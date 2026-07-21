import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:money_pilot/src/app_controller.dart';
import 'package:money_pilot/src/calendar_engine.dart';
import 'package:money_pilot/src/formatters.dart';
import 'package:money_pilot/src/localization.dart';
import 'package:money_pilot/src/models.dart';
import 'package:money_pilot/src/widgets/common.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _month;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  void _changeMonth(int offset) {
    final next = DateTime(_month.year, _month.month + offset);
    setState(() {
      _month = next;
      _selectedDate = DateTime(next.year, next.month, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appControllerProvider);
    final insights = CalendarEngine.summarize(
      month: _month,
      transactions: data.transactions,
    );
    final selected = insights.day(_selectedDate.day);
    return PageFrame(
      title: 'Spending calendar',
      subtitle: 'Explore daily income, expenses, and transactions.',
      actions: [
        OutlinedButton.icon(
          key: const Key('calendar-previous-month'),
          onPressed: () => _changeMonth(-1),
          icon: const Icon(Icons.chevron_left),
          label: const AppText('Previous month'),
        ),
        OutlinedButton.icon(
          key: const Key('calendar-next-month'),
          onPressed: () => _changeMonth(1),
          icon: const Icon(Icons.chevron_right),
          label: const AppText('Next month'),
        ),
      ],
      child: Column(
        children: [
          AdaptiveGrid(
            minItemWidth: 210,
            children: [
              MetricCard(
                label: 'Expenses this month',
                value: MoneyFormatter.amount(insights.expenseMinor),
                icon: Icons.south_east_rounded,
                accent: Theme.of(context).colorScheme.error,
              ),
              MetricCard(
                label: 'Income this month',
                value: MoneyFormatter.amount(insights.incomeMinor),
                icon: Icons.north_east_rounded,
                accent: const Color(0xFF18875C),
              ),
              MetricCard(
                label: 'Days without spending',
                value: '${insights.noSpendDays}',
                icon: Icons.savings_outlined,
              ),
              MetricCard(
                label: 'Busiest spending day',
                value: insights.busiestDay == null
                    ? '0'
                    : MaterialLocalizations.of(
                        context,
                      ).formatMediumDate(insights.busiestDay!.date),
                detail: insights.busiestDay == null
                    ? 'No expenses this month'
                    : MoneyFormatter.amount(insights.busiestDay!.expenseMinor),
                icon: Icons.local_fire_department_outlined,
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final calendar = _CalendarCard(
                month: _month,
                insights: insights,
                selectedDate: _selectedDate,
                onSelected: (date) => setState(() => _selectedDate = date),
              );
              final details = _DayDetails(
                summary: selected,
                categories: data.categories,
              );
              if (constraints.maxWidth < 960) {
                return Column(
                  children: [calendar, const SizedBox(height: 18), details],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: calendar),
                  const SizedBox(width: 18),
                  Expanded(flex: 2, child: details),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({
    required this.month,
    required this.insights,
    required this.selectedDate,
    required this.onSelected,
  });

  final DateTime month;
  final CalendarMonthInsights insights;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final material = MaterialLocalizations.of(context);
    final first = DateTime(month.year, month.month);
    final firstWeekdayIndex = first.weekday % 7;
    final offset = (firstWeekdayIndex - material.firstDayOfWeekIndex + 7) % 7;
    final weekdays = List.generate(
      7,
      (index) =>
          material.narrowWeekdays[(material.firstDayOfWeekIndex + index) % 7],
    );
    final itemCount = offset + insights.days.length;
    return SectionCard(
      title: DateFormat.yMMMM(locale).format(month),
      child: Column(
        children: [
          Row(
            children: [
              for (final weekday in weekdays)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppText(
                      weekday,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
              childAspectRatio: 0.9,
            ),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              if (index < offset) return const SizedBox.shrink();
              final dayNumber = index - offset + 1;
              final summary = insights.day(dayNumber);
              final selected =
                  selectedDate.year == month.year &&
                  selectedDate.month == month.month &&
                  selectedDate.day == dayNumber;
              return _DayCell(
                summary: summary,
                selected: selected,
                onTap: () => onSelected(summary.date),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.summary,
    required this.selected,
    required this.onTap,
  });

  final CalendarDaySummary summary;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label:
          '${MaterialLocalizations.of(context).formatMediumDate(summary.date)}, ${context.l10n.translate('Spent on selected day')} ${MoneyFormatter.amount(summary.expenseMinor)}, ${context.l10n.translate('Income on selected day')} ${MoneyFormatter.amount(summary.incomeMinor)}',
      child: Material(
        color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          key: Key('calendar-day-${summary.date.day}'),
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 52;
              return Padding(
                padding: EdgeInsets.all(compact ? 5 : 7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      '${summary.date.day}',
                      style: TextStyle(
                        fontSize: compact ? 11 : null,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    if (compact)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (summary.expenseMinor > 0)
                            _MoneyIndicator(color: scheme.error),
                          if (summary.expenseMinor > 0 &&
                              summary.incomeMinor > 0)
                            const SizedBox(width: 3),
                          if (summary.incomeMinor > 0)
                            const _MoneyIndicator(color: Color(0xFF18875C)),
                        ],
                      )
                    else ...[
                      if (summary.expenseMinor > 0)
                        FittedBox(
                          child: AppText(
                            '-${MoneyFormatter.amount(summary.expenseMinor)}',
                            style: TextStyle(
                              color: scheme.error,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      if (summary.incomeMinor > 0)
                        FittedBox(
                          child: AppText(
                            '+${MoneyFormatter.amount(summary.incomeMinor)}',
                            style: const TextStyle(
                              color: Color(0xFF18875C),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MoneyIndicator extends StatelessWidget {
  const _MoneyIndicator({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 6,
    height: 6,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _DayDetails extends StatelessWidget {
  const _DayDetails({required this.summary, required this.categories});

  final CalendarDaySummary summary;
  final List<SpendingCategory> categories;

  @override
  Widget build(BuildContext context) {
    final date = MaterialLocalizations.of(context).formatFullDate(summary.date);
    return SectionCard(
      title: date,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdaptiveGrid(
            minItemWidth: 150,
            children: [
              _DayMetric(
                label: 'Spent on selected day',
                value: MoneyFormatter.amount(summary.expenseMinor),
                color: Theme.of(context).colorScheme.error,
              ),
              _DayMetric(
                label: 'Income on selected day',
                value: MoneyFormatter.amount(summary.incomeMinor),
                color: const Color(0xFF18875C),
              ),
            ],
          ),
          const Divider(height: 28),
          if (summary.transactions.isEmpty)
            const EmptyState(
              icon: Icons.event_available_outlined,
              title: 'No transactions on this day.',
              message: 'Add your first income or expense when you are ready.',
            )
          else
            for (
              var index = 0;
              index < summary.transactions.length;
              index++
            ) ...[
              _CalendarTransactionRow(
                transaction: summary.transactions[index],
                category: categories
                    .where(
                      (category) =>
                          category.id == summary.transactions[index].categoryId,
                    )
                    .firstOrNull,
              ),
              if (index != summary.transactions.length - 1) const Divider(),
            ],
        ],
      ),
    );
  }
}

class _DayMetric extends StatelessWidget {
  const _DayMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 5),
          AppText(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarTransactionRow extends StatelessWidget {
  const _CalendarTransactionRow({required this.transaction, this.category});

  final FinanceTransaction transaction;
  final SpendingCategory? category;

  @override
  Widget build(BuildContext context) {
    final fallback = const SpendingCategory(
      id: 'unknown',
      name: 'Uncategorized',
      iconCode: 0xe5d3,
      colorValue: 0xFF747B8A,
    );
    final resolved = category ?? fallback;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          CategoryAvatar(category: resolved, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  transaction.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                AppText(
                  context.l10n.translate(resolved.name),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          AmountText(minor: transaction.amountMinor, emphasized: true),
        ],
      ),
    );
  }
}
