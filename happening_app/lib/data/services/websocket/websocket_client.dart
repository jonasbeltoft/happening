import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../api/api_client.dart';

enum WebSocketStatus { disconnected, connecting, connected }

/// One message pushed by the server on a topic.
@immutable
class WebSocketMessage {
  const WebSocketMessage({required this.topic, required this.type, required this.data});

  final String topic;

  /// What happened, e.g. `event.updated`.
  final String type;

  /// Decoded JSON payload.
  final Object? data;
}

/// The app's single WebSocket to the server. Repositories subscribe to topics
/// through [topic]; nothing else touches the socket.
///
/// Reconnects with exponential backoff and jitter, re-subscribes to open
/// topics after a reconnect, and sends a heartbeat to detect dead sockets.
/// Messages sent while disconnected are lost, so repositories should refetch
/// over REST when [reconnected] fires.
///
/// Wire protocol (JSON text frames), to be matched by the server:
/// - client → server: `{"type":"auth","token":"…"}`, `{"type":"subscribe","topic":"…"}`,
///   `{"type":"unsubscribe","topic":"…"}`, `{"type":"ping"}`
/// - server → client: `{"topic":"…","type":"…","data":…}`, `{"type":"pong"}`
class WebSocketClient {
  WebSocketClient({
    required this._url,
    this._token,
    WebSocketChannel Function(Uri url)? connect,
  }) : _connect = connect ?? WebSocketChannel.connect;

  final Uri _url;
  final TokenProvider? _token;
  final WebSocketChannel Function(Uri url) _connect;

  static const _heartbeatInterval = Duration(seconds: 25);
  static const _maxRetryDelay = Duration(seconds: 30);

  final _status = ValueNotifier(WebSocketStatus.disconnected);
  final _messages = StreamController<WebSocketMessage>.broadcast();
  final _reconnected = StreamController<void>.broadcast();
  final _random = Random();

  /// Open topics and how many listeners each has.
  final _topics = <String, int>{};

  WebSocketChannel? _channel;
  StreamSubscription<Object?>? _channelSub;
  Timer? _retryTimer;
  Timer? _heartbeat;
  DateTime _lastSeen = DateTime.now();
  int _attempt = 0;
  bool _wanted = false;
  bool _hasConnected = false;

  ValueListenable<WebSocketStatus> get status => _status;

  /// Fires after every successful reconnect (not the first connect).
  Stream<void> get reconnected => _reconnected.stream;

  /// Starts connecting and keeps the connection up until [disconnect].
  void connect() {
    _wanted = true;
    if (_channel == null && _retryTimer == null) _open();
  }

  void disconnect() {
    _wanted = false;
    _retryTimer?.cancel();
    _retryTimer = null;
    _channel?.sink.close();
    _closed(_channel);
  }

  /// Messages on [topic]. Subscribes on the server while at least one
  /// listener is attached, and unsubscribes when the last one cancels.
  Stream<WebSocketMessage> topic(String topic) => Stream.multi((controller) {
    _addTopic(topic);
    final sub = _messages.stream.where((m) => m.topic == topic).listen(controller.addSync);
    controller.onCancel = () {
      sub.cancel();
      _removeTopic(topic);
    };
  });

  void dispose() {
    disconnect();
    _messages.close();
    _reconnected.close();
    _status.dispose();
  }

  Future<void> _open() async {
    _status.value = WebSocketStatus.connecting;

    final channel = _connect(_url);
    _channel = channel;
    try {
      await channel.ready;
    } catch (_) {
      _closed(channel);
      return;
    }
    if (!identical(_channel, channel)) return;

    _attempt = 0;
    _lastSeen = DateTime.now();
    _channelSub = channel.stream.listen(
      _onData,
      onError: (Object _) => _closed(channel),
      onDone: () => _closed(channel),
      cancelOnError: true,
    );

    final token = await _token?.call();
    if (!identical(_channel, channel)) return;

    // Topics added while connecting were not sent; the replay below covers them.
    _status.value = WebSocketStatus.connected;
    if (token != null) _send({'type': 'auth', 'token': token});
    for (final topic in _topics.keys) {
      _send({'type': 'subscribe', 'topic': topic});
    }

    _heartbeat = Timer.periodic(_heartbeatInterval, (_) => _checkHeartbeat(channel));

    if (_hasConnected) _reconnected.add(null);
    _hasConnected = true;
  }

  void _onData(Object? raw) {
    _lastSeen = DateTime.now();
    if (raw is! String) return;

    final Object? json;
    try {
      json = jsonDecode(raw);
    } on FormatException {
      return;
    }

    if (json case {'topic': final String topic, 'type': final String type}) {
      _messages.add(WebSocketMessage(topic: topic, type: type, data: json['data']));
    }
  }

  void _checkHeartbeat(WebSocketChannel channel) {
    if (DateTime.now().difference(_lastSeen) > _heartbeatInterval * 2) {
      // No traffic, not even pongs: treat the socket as dead.
      channel.sink.close();
      _closed(channel);
      return;
    }
    _send({'type': 'ping'});
  }

  /// Cleans up after [channel] closed for any reason, then schedules a retry.
  void _closed(WebSocketChannel? channel) {
    if (channel == null || !identical(_channel, channel)) return;

    _channelSub?.cancel();
    _channelSub = null;
    _heartbeat?.cancel();
    _heartbeat = null;
    _channel = null;
    _status.value = WebSocketStatus.disconnected;

    if (_wanted) _scheduleRetry();
  }

  void _scheduleRetry() {
    final base = Duration(seconds: 1) * pow(2, _attempt);
    final capped = base > _maxRetryDelay ? _maxRetryDelay : base;
    final jittered = capped * (0.5 + _random.nextDouble() / 2);
    _attempt++;

    _retryTimer = Timer(jittered, () {
      _retryTimer = null;
      if (_wanted) _open();
    });
  }

  void _addTopic(String topic) {
    final count = (_topics[topic] ?? 0) + 1;
    _topics[topic] = count;
    if (count == 1) _send({'type': 'subscribe', 'topic': topic});
  }

  void _removeTopic(String topic) {
    final count = (_topics[topic] ?? 1) - 1;
    if (count > 0) {
      _topics[topic] = count;
      return;
    }
    _topics.remove(topic);
    _send({'type': 'unsubscribe', 'topic': topic});
  }

  /// Sends only while connected; subscriptions are replayed on reconnect.
  void _send(Map<String, Object?> message) {
    if (_status.value != WebSocketStatus.connected) return;
    _channel?.sink.add(jsonEncode(message));
  }
}
