import 'package:flutter/widgets.dart';

import '../../../types/event.dart';
import '../../components/button/app_button.dart';
import '../../components/button/app_pill_button.dart';
import '../../core/pressable.dart';
import '../../theme/app_theme.dart';
import 'events_view_model.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key, required this.viewModel});

  final EventsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return SafeArea(
      child: ListenableBuilder(
        listenable: Listenable.merge([viewModel, viewModel.load, viewModel.answer]),
        builder: (context, _) => Column(
          crossAxisAlignment: .start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 18, AppSpacing.gutter, 14),
              child: Row(
                children: [
                  Expanded(child: Text('Around you', style: theme.text.screenTitle)),
                  // TEMP: reset fake data so the buttons can be pressed again.
                  if (viewModel.canReset)
                    Pressable(
                      onPressed: viewModel.reset,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 12),
                        child: Text('Reset', style: theme.text.meta),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(child: _buildBody(theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AppTheme theme) {
    if (viewModel.rows.isEmpty) {
      if (viewModel.loadError case final error?) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
          child: Column(
            mainAxisAlignment: .center,
            children: [
              Text(error, style: theme.text.body, textAlign: .center),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: 160,
                child: AppButton(label: 'Try again', variant: .secondary, onPressed: viewModel.load.execute),
              ),
            ],
          ),
        );
      }
      return Center(child: Text(viewModel.load.running ? 'Loading events' : 'Nothing on near you', style: theme.text.meta));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 2, AppSpacing.gutter, AppSpacing.lg),
      children: [
        Text(viewModel.summary, style: theme.text.body),
        if (viewModel.answerError case final error?)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(error, style: theme.text.meta.copyWith(color: theme.colors.emberInk)),
          ),
        const SizedBox(height: 14),
        for (final row in viewModel.rows)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _EventRow(
              row: row,
              answering: viewModel.isAnswering(row.id),
              onGoing: () => viewModel.answer.execute((row.id, Rsvp.going)),
            ),
          ),
      ],
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.row, required this.answering, required this.onGoing});

  final EventRowState row;
  final bool answering;
  final VoidCallback onGoing;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: theme.colors.card,
        borderRadius: const BorderRadius.all(AppRadius.row),
        boxShadow: AppShadows.row,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(row.title, style: theme.text.rowTitle, maxLines: 1, overflow: .ellipsis),
                const SizedBox(height: 3),
                Text(
                  row.meta,
                  style: row.needsAnswer ? theme.text.meta.copyWith(color: theme.colors.emberInk) : theme.text.meta,
                  maxLines: 1,
                  overflow: .ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (row.answer case final answer?)
            Text(answer, style: theme.text.rowState)
          else
            AppPillButton(label: "I'm going", onPressed: answering ? null : onGoing),
        ],
      ),
    );
  }
}
