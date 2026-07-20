import 'package:money_pilot/src/models.dart';

class CalendarDaySummary {
  const CalendarDaySummary({
    required this.date,
    required this.transactions,
    required this.incomeMinor,
    required this.expenseMinor,
  });

  final DateTime date;
  final List<FinanceTransaction> transactions;
  final int incomeMinor;
  final int expenseMinor;
}

class CalendarMonthInsights {
  const CalendarMonthInsights({
    required this.month,
    required this.days,
    required this.incomeMinor,
    required this.expenseMinor,
    required this.noSpendDays,
    this.busiestDay,
  });

  final DateTime month;
  final Map<int, CalendarDaySummary> days;
  final int incomeMinor;
  final int expenseMinor;
  final int noSpendDays;
  final CalendarDaySummary? busiestDay;

  CalendarDaySummary day(int number) =>
      days[number] ??
      CalendarDaySummary(
        date: DateTime(month.year, month.month, number),
        transactions: const [],
        incomeMinor: 0,
        expenseMinor: 0,
      );
}

class CalendarEngine {
  const CalendarEngine._();

  static CalendarMonthInsights summarize({
    required DateTime month,
    required List<FinanceTransaction> transactions,
    DateTime? today,
  }) {
    final normalizedMonth = DateTime(month.year, month.month);
    final now = today ?? DateTime.now();
    final grouped = <int, List<FinanceTransaction>>{};
    for (final transaction in transactions) {
      if (transaction.date.year == normalizedMonth.year &&
          transaction.date.month == normalizedMonth.month) {
        grouped.putIfAbsent(transaction.date.day, () => []).add(transaction);
      }
    }

    final dayCount = DateTime(
      normalizedMonth.year,
      normalizedMonth.month + 1,
      0,
    ).day;
    final summaries = <int, CalendarDaySummary>{};
    var income = 0;
    var expense = 0;
    CalendarDaySummary? busiest;
    for (var day = 1; day <= dayCount; day++) {
      final items = List<FinanceTransaction>.unmodifiable(
        grouped[day] ?? const [],
      );
      final dayIncome = items
          .where((item) => item.amountMinor > 0)
          .fold<int>(0, (total, item) => total + item.amountMinor);
      final dayExpense = items
          .where((item) => item.amountMinor < 0)
          .fold<int>(0, (total, item) => total + item.amountMinor.abs());
      final summary = CalendarDaySummary(
        date: DateTime(normalizedMonth.year, normalizedMonth.month, day),
        transactions: items,
        incomeMinor: dayIncome,
        expenseMinor: dayExpense,
      );
      summaries[day] = summary;
      income += dayIncome;
      expense += dayExpense;
      if (dayExpense > 0 &&
          (busiest == null || dayExpense > busiest.expenseMinor)) {
        busiest = summary;
      }
    }

    final isCurrentMonth =
        now.year == normalizedMonth.year && now.month == normalizedMonth.month;
    final isFutureMonth = normalizedMonth.isAfter(
      DateTime(now.year, now.month),
    );
    final observableDays = isFutureMonth
        ? 0
        : (isCurrentMonth ? now.day : dayCount);
    final noSpendDays = summaries.values
        .where((day) => day.date.day <= observableDays && day.expenseMinor == 0)
        .length;

    return CalendarMonthInsights(
      month: normalizedMonth,
      days: Map.unmodifiable(summaries),
      incomeMinor: income,
      expenseMinor: expense,
      noSpendDays: noSpendDays,
      busiestDay: busiest,
    );
  }
}
