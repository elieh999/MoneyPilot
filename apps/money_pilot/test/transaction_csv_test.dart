import 'package:flutter_test/flutter_test.dart';
import 'package:money_pilot/src/models.dart';
import 'package:money_pilot/src/transaction_csv.dart';

void main() {
  const codec = TransactionCsvCodec();
  const accounts = [
    MoneyAccount(
      id: 'checking',
      name: 'Main, Checking',
      type: 'Checking',
      balanceMinor: 0,
      colorValue: 0,
    ),
  ];
  const categories = [
    SpendingCategory(id: 'food', name: 'Food', iconCode: 0, colorValue: 0),
  ];

  test('CSV round trip preserves quotes, commas, signs, and pending state', () {
    final csv = codec.encode(
      [
        FinanceTransaction(
          id: 'source',
          accountId: 'checking',
          categoryId: 'food',
          title: 'Lunch, with "team"',
          note: 'Line one\nLine two',
          amountMinor: -1299,
          date: DateTime(2026, 7, 20),
          isPending: true,
        ),
      ],
      accounts: accounts,
      categories: categories,
    );
    final decoded = codec.decode(
      csv,
      accounts: accounts,
      categories: categories,
      newId: () => 'imported',
    );
    expect(decoded.issues, isEmpty);
    expect(decoded.transactions.single.title, 'Lunch, with "team"');
    expect(decoded.transactions.single.note, 'Line one\nLine two');
    expect(decoded.transactions.single.amountMinor, -1299);
    expect(decoded.transactions.single.isPending, isTrue);
  });

  test('invalid rows are reported and valid rows still import', () {
    const csv =
        'date,description,amount,account,category,note,pending\n'
        '2026-07-20,Coffee,-4.50,checking,food,,false\n'
        'not-a-date,Broken,0,missing,food,,maybe';
    final decoded = codec.decode(
      csv,
      accounts: accounts,
      categories: categories,
      newId: () => 'id',
    );
    expect(decoded.transactions, hasLength(1));
    expect(decoded.issues.single.row, 3);
    expect(decoded.issues.single.message, contains('invalid date'));
  });
}
