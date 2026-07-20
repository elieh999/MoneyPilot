import 'package:flutter_test/flutter_test.dart';
import 'package:money_pilot/src/calendar_engine.dart';
import 'package:money_pilot/src/models.dart';

FinanceTransaction _transaction(String id, int day, int amount) =>
    FinanceTransaction(
      id: id,
      accountId: 'checking',
      categoryId: 'dining',
      title: id,
      amountMinor: amount,
      date: DateTime(2026, 7, day),
    );

void main() {
  test(
    'calendar groups daily money movement and calculates month insights',
    () {
      final insights = CalendarEngine.summarize(
        month: DateTime(2026, 7),
        today: DateTime(2026, 7, 5),
        transactions: [
          _transaction('coffee', 1, -500),
          _transaction('salary', 1, 200000),
          _transaction('groceries', 3, -8500),
          _transaction('refund', 3, 1200),
          FinanceTransaction(
            id: 'other-month',
            accountId: 'checking',
            categoryId: 'dining',
            title: 'other-month',
            amountMinor: -999,
            date: DateTime(2026, 8),
          ),
        ],
      );

      expect(insights.day(1).transactions, hasLength(2));
      expect(insights.day(1).expenseMinor, 500);
      expect(insights.day(1).incomeMinor, 200000);
      expect(insights.expenseMinor, 9000);
      expect(insights.incomeMinor, 201200);
      expect(insights.busiestDay?.date.day, 3);
      expect(insights.noSpendDays, 3);
    },
  );

  test('future month never reports future no-spend days', () {
    final insights = CalendarEngine.summarize(
      month: DateTime(2026, 8),
      today: DateTime(2026, 7, 20),
      transactions: const [],
    );

    expect(insights.noSpendDays, 0);
    expect(insights.busiestDay, isNull);
  });
}
