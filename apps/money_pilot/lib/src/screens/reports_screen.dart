import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:money_pilot/src/localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_pilot/src/app_controller.dart';
import 'package:money_pilot/src/forecast_engine.dart';
import 'package:money_pilot/src/formatters.dart';
import 'package:money_pilot/src/models.dart';
import 'package:money_pilot/src/theme.dart';
import 'package:money_pilot/src/widgets/common.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider.notifier);
    final spending = controller.spendingByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final flow = controller.monthlyIncomeMinor - controller.monthlyExpenseMinor;
    return PageFrame(
      title: 'Reports & forecast',
      subtitle: 'Deterministic insights calculated from your local snapshot.',
      actions: const [
        StatusPill(
          label: 'Offline model',
          icon: Icons.offline_bolt_outlined,
          color: AppTheme.mint,
        ),
      ],
      child: Column(
        children: [
          AdaptiveGrid(
            children: [
              MetricCard(
                label: 'Income this month',
                value: MoneyFormatter.amount(controller.monthlyIncomeMinor),
                icon: Icons.south_west_rounded,
                accent: AppTheme.mint,
              ),
              MetricCard(
                label: 'Expenses this month',
                value: MoneyFormatter.amount(controller.monthlyExpenseMinor),
                icon: Icons.north_east_rounded,
                accent: const Color(0xFFF08A5D),
              ),
              MetricCard(
                label: 'Net cash flow',
                value: MoneyFormatter.amount(flow),
                detail: flow >= 0
                    ? 'Positive current pace'
                    : 'Spending exceeds income',
                icon: flow >= 0 ? Icons.trending_up : Icons.trending_down,
              ),
            ],
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: 'Cash forecast for six months',
            trailing: const StatusPill(
              label: 'Scenario, not a promise',
              icon: Icons.info_outline,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  'Assumes this month’s income and expense pace continues, with current open bills recurring monthly.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
                _ForecastChart(points: controller.sixMonthForecast),
              ],
            ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final categoryBreakdown = _CategoryBreakdown(
                entries: spending,
                categories: data.categories,
              );
              final insights = _InsightPanel(
                flowMinor: flow,
                savingsRate: controller.savingsRateBasisPoints,
                topCategory: spending.firstOrNull == null
                    ? null
                    : data.categories
                          .where(
                            (category) => category.id == spending.first.key,
                          )
                          .firstOrNull,
              );
              if (constraints.maxWidth < 860) {
                return Column(
                  children: [
                    categoryBreakdown,
                    const SizedBox(height: 20),
                    insights,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: categoryBreakdown),
                  const SizedBox(width: 20),
                  Expanded(flex: 2, child: insights),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ForecastChart extends StatelessWidget {
  const _ForecastChart({required this.points});

  final List<CashForecastPoint> points;

  @override
  Widget build(BuildContext context) {
    final maximum = points.fold<int>(
      1,
      (value, point) => math.max(value, point.balanceMinor.abs()),
    );
    return SizedBox(
      height: 250,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: points.map((point) {
          final ratio = point.balanceMinor.abs() / maximum;
          final height = 45 + 125 * ratio;
          final negative = point.balanceMinor < 0;
          final color = negative
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.primary;
          return Expanded(
            child: Semantics(
              label:
                  '${DateFormats.month.format(point.month)} projected balance ${MoneyFormatter.amount(point.balanceMinor)}',
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppText(
                      MoneyFormatter.compact(point.balanceMinor),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      height: height,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    AppText(
                      DateFormats.short.format(point.month),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({required this.entries, required this.categories});

  final List<MapEntry<String, int>> entries;
  final List<SpendingCategory> categories;

  @override
  Widget build(BuildContext context) {
    final maximum = entries.isEmpty ? 1 : entries.first.value;
    return SectionCard(
      title: 'Spending by category',
      child: entries.isEmpty
          ? const EmptyState(
              icon: Icons.bar_chart_outlined,
              title: 'No expenses this month',
              message: 'Category trends will appear after you add activity.',
            )
          : Column(
              children: entries.map((entry) {
                final category = categories
                    .where((item) => item.id == entry.key)
                    .firstOrNull;
                final color = Color(category?.colorValue ?? 0xFF747B8A);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AppText(
                              category?.name ?? 'Other',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          AppText(
                            MoneyFormatter.amount(entry.value),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      LinearProgressIndicator(
                        value: entry.value / maximum,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(99),
                        color: color,
                        backgroundColor: color.withValues(alpha: 0.12),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _InsightPanel extends StatelessWidget {
  const _InsightPanel({
    required this.flowMinor,
    required this.savingsRate,
    required this.topCategory,
  });

  final int flowMinor;
  final int savingsRate;
  final SpendingCategory? topCategory;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'What stands out',
      child: Column(
        children: [
          _InsightRow(
            icon: flowMinor >= 0 ? Icons.trending_up : Icons.warning_amber,
            title: flowMinor >= 0
                ? 'Positive cash flow'
                : 'Cash flow needs review',
            detail: flowMinor >= 0
                ? '${MoneyFormatter.amount(flowMinor)} remains at the current pace.'
                : '${MoneyFormatter.amount(flowMinor.abs())} more is leaving than arriving.',
          ),
          const SizedBox(height: 18),
          _InsightRow(
            icon: Icons.savings_outlined,
            title: 'Savings rate ${MoneyFormatter.percent(savingsRate)}',
            detail: 'Calculated only when income this month is positive.',
          ),
          const SizedBox(height: 18),
          _InsightRow(
            icon: Icons.pie_chart_outline,
            title: topCategory == null
                ? 'No top category yet'
                : '${topCategory!.name} leads flexible spending',
            detail:
                'Open Budgets to tune a guardrail without changing history.',
          ),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              AppText(detail, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
