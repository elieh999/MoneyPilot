import 'package:money_pilot/src/formatters.dart';
import 'package:money_pilot/src/models.dart';

class CsvImportIssue {
  const CsvImportIssue(this.row, this.message);
  final int row;
  final String message;
}

class CsvImportResult {
  const CsvImportResult({required this.transactions, required this.issues});
  final List<FinanceTransaction> transactions;
  final List<CsvImportIssue> issues;
}

class TransactionCsvCodec {
  const TransactionCsvCodec();

  static const _headers = [
    'date',
    'description',
    'amount',
    'account',
    'category',
    'note',
    'pending',
  ];

  String encode(
    List<FinanceTransaction> transactions, {
    required List<MoneyAccount> accounts,
    required List<SpendingCategory> categories,
  }) {
    final accountNames = {for (final item in accounts) item.id: item.name};
    final categoryNames = {for (final item in categories) item.id: item.name};
    final rows = <List<String>>[
      _headers,
      ...transactions.map(
        (item) => [
          item.date.toIso8601String().split('T').first,
          item.title,
          MoneyFormatter.input(item.amountMinor),
          accountNames[item.accountId] ?? item.accountId,
          categoryNames[item.categoryId] ?? item.categoryId,
          item.note,
          item.isPending.toString(),
        ],
      ),
    ];
    return rows.map((row) => row.map(_escape).join(',')).join('\r\n');
  }

  CsvImportResult decode(
    String input, {
    required List<MoneyAccount> accounts,
    required List<SpendingCategory> categories,
    required String Function() newId,
  }) {
    final rows = _parse(input);
    if (rows.isEmpty) {
      return const CsvImportResult(
        transactions: [],
        issues: [CsvImportIssue(1, 'CSV is empty or has an open quote.')],
      );
    }
    final headers = rows.first.map(_normalize).toList();
    if (headers.length != _headers.length ||
        !_headers.asMap().entries.every((e) => headers[e.key] == e.value)) {
      return const CsvImportResult(
        transactions: [],
        issues: [CsvImportIssue(1, 'CSV headers do not match the template.')],
      );
    }
    final accountIds = <String, String>{
      for (final item in accounts) _normalize(item.name): item.id,
      for (final item in accounts) _normalize(item.id): item.id,
    };
    final categoryIds = <String, String>{
      for (final item in categories) _normalize(item.name): item.id,
      for (final item in categories) _normalize(item.id): item.id,
    };
    final imported = <FinanceTransaction>[];
    final issues = <CsvImportIssue>[];
    for (var index = 1; index < rows.length; index += 1) {
      final row = rows[index];
      final rowNumber = index + 1;
      if (row.every((cell) => cell.trim().isEmpty)) continue;
      if (row.length != _headers.length) {
        issues.add(CsvImportIssue(rowNumber, 'Expected 7 columns.'));
        continue;
      }
      final date = DateTime.tryParse(row[0].trim());
      final title = row[1].trim();
      final amount = MoneyFormatter.parseInputToMinor(
        row[2],
        allowNegative: true,
      );
      final accountId = accountIds[_normalize(row[3])];
      final categoryId = categoryIds[_normalize(row[4])];
      final pending = switch (_normalize(row[6])) {
        '' || 'false' || 'no' || '0' => false,
        'true' || 'yes' || '1' => true,
        _ => null,
      };
      final problems = <String>[
        if (date == null) 'invalid date',
        if (title.isEmpty) 'missing description',
        if (amount == null) 'invalid non-zero amount',
        if (accountId == null) 'unknown account',
        if (categoryId == null) 'unknown category',
        if (pending == null) 'invalid pending value',
      ];
      if (problems.isNotEmpty) {
        issues.add(CsvImportIssue(rowNumber, problems.join(', ')));
        continue;
      }
      imported.add(
        FinanceTransaction(
          id: newId(),
          accountId: accountId!,
          categoryId: categoryId!,
          title: title,
          amountMinor: amount!,
          date: date!,
          note: row[5].trim(),
          isPending: pending!,
        ),
      );
    }
    return CsvImportResult(transactions: imported, issues: issues);
  }

  String _escape(String value) => value.contains(RegExp('[,"\r\n]'))
      ? '"${value.replaceAll('"', '""')}"'
      : value;
  String _normalize(String value) => value.trim().toLowerCase();

  List<List<String>> _parse(String input) {
    final rows = <List<String>>[];
    var row = <String>[];
    var field = StringBuffer();
    var quoted = false;
    for (var index = 0; index < input.length; index += 1) {
      final char = input[index];
      if (char == '"') {
        if (quoted && index + 1 < input.length && input[index + 1] == '"') {
          field.write('"');
          index += 1;
        } else {
          quoted = !quoted;
        }
      } else if (char == ',' && !quoted) {
        row.add(field.toString());
        field = StringBuffer();
      } else if ((char == '\n' || char == '\r') && !quoted) {
        if (char == '\r' &&
            index + 1 < input.length &&
            input[index + 1] == '\n') {
          index += 1;
        }
        row.add(field.toString());
        rows.add(row);
        row = <String>[];
        field = StringBuffer();
      } else {
        field.write(char);
      }
    }
    if (quoted) return const [];
    if (field.isNotEmpty || row.isNotEmpty) {
      row.add(field.toString());
      rows.add(row);
    }
    return rows;
  }
}
