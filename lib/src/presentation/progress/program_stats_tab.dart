import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fytter/src/providers/progress_provider.dart';
import 'package:fytter/src/providers/navigation_provider.dart';
import 'package:fytter/src/presentation/shared/app_card.dart';
import 'package:fytter/src/presentation/shared/app_list_row.dart';
import 'package:fytter/src/presentation/shared/app_text.dart';
import 'package:fytter/src/presentation/shared/app_empty_state.dart';
import 'package:fytter/src/presentation/shared/app_loading_state.dart';
import 'package:fytter/src/presentation/theme.dart';

class ProgramStatsTab extends ConsumerWidget {
  const ProgramStatsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.themeExt<AppColors>();
    final spacing = context.themeExt<AppSpacing>();
    final statsAsync = ref.watch(programStatsProvider);

    return statsAsync.when(
      data: (stats) {
        return ListView(
          padding: EdgeInsets.all(spacing.lg),
          children: [
            // Overall stats cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Total Programs',
                    stats.totalPrograms.toString(),
                    Icons.list_alt,
                    onTap: () {
                      ref.read(selectedTabIndexProvider.notifier).state = 2;
                    },
                    key: const Key('programStats_totalPrograms'),
                  ),
                ),
                SizedBox(width: spacing.lg),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Completion Rate',
                    '${(stats.completionRate * 100).toStringAsFixed(1)}%',
                    Icons.check_circle,
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.xl),
            // Program completion list
            const AppText('Program Completion', style: AppTextStyle.title),
            SizedBox(height: spacing.lg),
            if (stats.programCompletionStats.isEmpty)
              const AppEmptyState(
                title: 'No programs available',
                message: 'Create a program to track completion stats.',
                icon: Icons.list_alt,
              )
            else
              ...stats.programCompletionStats.map(
                (entry) => AppCard(
                  compact: true,
                  child: AppListRow(
                    dense: true,
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(entry.programName, style: AppTextStyle.label),
                        if (entry.startDate != null) ...[
                          SizedBox(height: spacing.xs),
                          AppText(
                            DateFormat('d MMM, yyyy').format(entry.startDate!),
                            style: AppTextStyle.caption,
                            color: colors.outline,
                          ),
                        ],
                      ],
                    ),
                    trailing: AppText(
                      '${entry.completedCount} of ${entry.totalCount} completed',
                      style: AppTextStyle.caption,
                      color: colors.success,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const AppLoadingState(
        useShimmer: true,
        variant: AppLoadingVariant.card,
      ),
      error: (error, stack) => AppEmptyState(
        title: 'Unable to load stats',
        message: error.toString(),
        icon: Icons.error_outline,
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    {VoidCallback? onTap, Key? key}
  ) {
    final colors = context.themeExt<AppColors>();
    final spacing = context.themeExt<AppSpacing>();
    final content = Padding(
      padding: EdgeInsets.all(spacing.lg),
      child: Column(
        children: [
          Icon(icon, size: 32, color: colors.primary),
          SizedBox(height: spacing.sm),
          AppText(
            title,
            style: AppTextStyle.label,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: spacing.xs),
          AppText(
            value,
            style: AppTextStyle.headline,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
    return AppCard(
      key: key,
      onTap: onTap,
      child: content,
    );
  }
} 