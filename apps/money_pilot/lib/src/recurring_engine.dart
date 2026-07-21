import 'package:money_pilot/src/models.dart';

class RecurringTransactionInsight {
  const RecurringTransactionInsight({
    required this.title,
    required this.amountMinor,
    required this.cadenceDays,
    required this.nextExpectedDate,
    required this.occurrences,
  });
  final String title;
  final int amountMinor;
  final int cadenceDays;
  final DateTime nextExpectedDate;
  final int occurrences;
  String get cadenceLabel => cadenceDays == 7 ? 'Weekly' : 'Monthly';
}

class RecurringEngine {
  const RecurringEngine._();

  static List<RecurringTransactionInsight> detect(
    List<FinanceTransaction> transactions,
  ) {
    final groups = <String, List<FinanceTransaction>>{};
    for (final item in transactions.where((item) => !item.isPending)) {
      final title = item.title.trim().toLowerCase().replaceAll(
        RegExp(r'\s+'),
        ' ',
      );
      groups
          .putIfAbsent(
            '$title|${item.amountMinor}|${item.categoryId}',
            () => [],
          )
          .add(item);
    }
    final insights = <RecurringTransactionInsight>[];
    for (final group in groups.values.where((items) => items.length >= 3)) {
      group.sort((a, b) => a.date.compareTo(b.date));
      final gaps = <int>[];
      for (var index = 1; index < group.length; index += 1) {
        gaps.add(group[index].date.difference(group[index - 1].date).inDays);
      }
      final average = gaps.reduce((a, b) => a + b) / gaps.length;
      final cadence = average >= 6 && average <= 8
          ? 7
          : average >= 26 && average <= 35
          ? 30
          : null;
      if (cadence == null || gaps.any((gap) => (gap - cadence).abs() > 5)) {
        continue;
      }
      final latest = group.last;
      insights.add(
        RecurringTransactionInsight(
          title: latest.title,
          amountMinor: latest.amountMinor,
          cadenceDays: cadence,
          nextExpectedDate: latest.date.add(Duration(days: cadence)),
          occurrences: group.length,
        ),
      );
    }
    insights.sort((a, b) => a.nextExpectedDate.compareTo(b.nextExpectedDate));
    return insights;
  }
}
