import 'package:flutter_test/flutter_test.dart';
import 'package:money_pilot/src/models.dart';
import 'package:money_pilot/src/recurring_engine.dart';

FinanceTransaction _transaction(
  String id,
  DateTime date, {
  int amount = -1200,
}) => FinanceTransaction(
  id: id,
  accountId: 'checking',
  categoryId: 'subscription',
  title: 'Music plan',
  amountMinor: amount,
  date: date,
);

void main() {
  test('detects stable monthly and weekly patterns', () {
    final monthly = [
      _transaction('m1', DateTime(2026, 1, 1)),
      _transaction('m2', DateTime(2026, 1, 31)),
      _transaction('m3', DateTime(2026, 3, 2)),
    ];
    final weekly = [
      _transaction('w1', DateTime(2026, 2, 1), amount: -500),
      _transaction('w2', DateTime(2026, 2, 8), amount: -500),
      _transaction('w3', DateTime(2026, 2, 15), amount: -500),
    ];
    final insights = RecurringEngine.detect([...monthly, ...weekly]);
    expect(insights, hasLength(2));
    expect(insights.map((item) => item.cadenceDays), containsAll([7, 30]));
  });

  test('ignores unstable, pending, and two-occurrence patterns', () {
    final items = [
      _transaction('a', DateTime(2026, 1, 1)),
      _transaction('b', DateTime(2026, 1, 10)),
      _transaction('c', DateTime(2026, 3, 20)),
      FinanceTransaction(
        id: 'pending',
        accountId: 'checking',
        categoryId: 'subscription',
        title: 'Music plan',
        amountMinor: -1200,
        date: DateTime(2026, 4, 20),
        isPending: true,
      ),
    ];
    expect(RecurringEngine.detect(items), isEmpty);
  });
}
