import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:money_pilot/src/localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_pilot/src/app_controller.dart';
import 'package:money_pilot/src/formatters.dart';
import 'package:money_pilot/src/models.dart';
import 'package:money_pilot/src/recurring_engine.dart';
import 'package:money_pilot/src/widgets/common.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _searchController = TextEditingController();
  String _categoryId = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider.notifier);
    final recurring = controller.recurringInsights;
    final query = _searchController.text.trim().toLowerCase();
    final visible = data.transactions.where((transaction) {
      final matchesText =
          query.isEmpty ||
          transaction.title.toLowerCase().contains(query) ||
          transaction.note.toLowerCase().contains(query);
      final matchesCategory =
          _categoryId == 'all' || transaction.categoryId == _categoryId;
      return matchesText && matchesCategory;
    }).toList()..sort((a, b) => b.date.compareTo(a.date));

    return PageFrame(
      title: 'Transactions',
      subtitle: 'Search, categorize, and edit every local money movement.',
      actions: [
        Tooltip(
          message: context.l10n.translate('Import transactions from CSV'),
          child: OutlinedButton.icon(
            onPressed: data.accounts.isEmpty
                ? null
                : () => _showCsvImport(context, ref),
            icon: const Icon(Icons.upload_file_outlined),
            label: const AppText('Import CSV'),
          ),
        ),
        Tooltip(
          message: context.l10n.translate('Copy transactions as CSV'),
          child: OutlinedButton.icon(
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: controller.exportTransactionsCsv()),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: AppText(
                      '${data.transactions.length} transactions copied as CSV.',
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.download_outlined),
            label: const AppText('Export CSV'),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => showCategoryManager(context),
          icon: const Icon(Icons.category_outlined),
          label: const AppText('Categories'),
        ),
        FilledButton.icon(
          onPressed: () => showTransactionEditor(context),
          icon: const Icon(Icons.add),
          label: const AppText('Add transaction'),
        ),
      ],
      child: Column(
        children: [
          SectionCard(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 360,
                  child: TextField(
                    key: const Key('transaction-search'),
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: context.l10n.translate('Search transactions'),
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                SizedBox(
                  width: 230,
                  child: DropdownButtonFormField<String>(
                    initialValue: _categoryId,
                    decoration: InputDecoration(
                      labelText: context.l10n.translate('Category'),
                      prefixIcon: Icon(Icons.filter_list),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: 'all',
                        child: AppText('All categories'),
                      ),
                      ...data.categories.map(
                        (category) => DropdownMenuItem(
                          value: category.id,
                          child: AppText(category.name),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _categoryId = value ?? 'all'),
                  ),
                ),
                StatusPill(
                  label: '${visible.length} shown',
                  icon: Icons.list_alt_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (recurring.isNotEmpty) ...[
            _RecurringCard(insights: recurring),
            const SizedBox(height: 16),
          ],
          SectionCard(
            padding: EdgeInsets.zero,
            child: visible.isEmpty
                ? const EmptyState(
                    icon: Icons.search_off,
                    title: 'No matching transactions',
                    message: 'Try another search or category filter.',
                  )
                : Column(
                    children: [
                      for (var index = 0; index < visible.length; index++) ...[
                        _TransactionRow(
                          transaction: visible[index],
                          category: data.categories
                              .where(
                                (category) =>
                                    category.id == visible[index].categoryId,
                              )
                              .firstOrNull,
                          account: data.accounts
                              .where(
                                (account) =>
                                    account.id == visible[index].accountId,
                              )
                              .firstOrNull,
                        ),
                        if (index != visible.length - 1) const Divider(),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _RecurringCard extends StatelessWidget {
  const _RecurringCard({required this.insights});

  final List<RecurringTransactionInsight> insights;

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Recurring activity',
    child: Wrap(
      spacing: 12,
      runSpacing: 12,
      children: insights.take(4).map((item) {
        final description =
            '${context.l10n.translate(item.cadenceLabel)} • ${item.occurrences} ${context.l10n.translate('occurrences')} • ${context.l10n.translate('next')} ${DateFormats.short.format(item.nextExpectedDate)}';
        return Semantics(
          label:
              '${item.title}, ${MoneyFormatter.amount(item.amountMinor)}, $description',
          child: Container(
            width: 260,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                AppText(description),
                const SizedBox(height: 4),
                AmountText(minor: item.amountMinor, emphasized: true),
              ],
            ),
          ),
        );
      }).toList(),
    ),
  );
}

Future<void> _showCsvImport(BuildContext context, WidgetRef ref) async {
  final input = TextEditingController();
  try {
    final shouldImport = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const AppText('Import transactions from CSV'),
        content: SizedBox(
          width: 620,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppText(
                'Paste CSV with columns: date, description, amount, account, category, note, pending. Invalid rows are skipped.',
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('csv-import-input'),
                controller: input,
                autofocus: true,
                minLines: 8,
                maxLines: 14,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  labelText: context.l10n.translate('CSV data'),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const AppText('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.upload_file_outlined),
            label: const AppText('Import CSV'),
          ),
        ],
      ),
    );
    if (shouldImport != true || !context.mounted) return;
    final result = ref
        .read(appControllerProvider.notifier)
        .importTransactionsCsv(input.text);
    final issueText = result.issues.isEmpty
        ? ''
        : ' ${result.issues.length} rows were skipped.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: AppText(
          '${result.transactions.length} transactions imported.$issueText',
        ),
      ),
    );
  } finally {
    input.dispose();
  }
}

class _TransactionRow extends ConsumerWidget {
  const _TransactionRow({
    required this.transaction,
    required this.category,
    required this.account,
  });

  final FinanceTransaction transaction;
  final SpendingCategory? category;
  final MoneyAccount? account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fallback = const SpendingCategory(
      id: 'unknown',
      name: 'Uncategorized',
      iconCode: 0xe5d3,
      colorValue: 0xFF747B8A,
    );
    final resolvedCategory = category ?? fallback;
    return Semantics(
      button: true,
      label:
          '${transaction.title}, ${MoneyFormatter.amount(transaction.amountMinor)}, ${DateFormats.medium.format(transaction.date)}',
      child: InkWell(
        onTap: () => showTransactionEditor(context, existing: transaction),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              CategoryAvatar(category: resolvedCategory),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: AppText(
                            transaction.title,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        if (transaction.isPending) ...[
                          const SizedBox(width: 8),
                          const StatusPill(
                            label: 'Pending',
                            icon: Icons.schedule,
                            color: Color(0xFFD17C13),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    AppText(
                      '${context.l10n.translate(resolvedCategory.name)} • ${account?.name ?? context.l10n.translate('Unknown account')} • ${DateFormats.short.format(transaction.date)}',
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AmountText(minor: transaction.amountMinor, emphasized: true),
              PopupMenuButton<String>(
                tooltip: context.l10n.translate('Transaction actions'),
                onSelected: (value) async {
                  if (value == 'edit') {
                    await showTransactionEditor(context, existing: transaction);
                  } else if (value == 'delete' && context.mounted) {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const AppText('Delete transaction?'),
                        content: AppText(
                          '${transaction.title} will be removed and the account balance will be adjusted.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const AppText('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const AppText('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      ref
                          .read(appControllerProvider.notifier)
                          .deleteTransaction(transaction.id);
                    }
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: AppText('Edit')),
                  PopupMenuItem(value: 'delete', child: AppText('Delete')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showTransactionEditor(
  BuildContext context, {
  FinanceTransaction? existing,
}) => showDialog<void>(
  context: context,
  builder: (context) => TransactionEditorDialog(existing: existing),
);

class TransactionEditorDialog extends ConsumerStatefulWidget {
  const TransactionEditorDialog({this.existing, super.key});

  final FinanceTransaction? existing;

  @override
  ConsumerState<TransactionEditorDialog> createState() =>
      _TransactionEditorDialogState();
}

class _TransactionEditorDialogState
    extends ConsumerState<TransactionEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late bool _income;
  late bool _pending;
  late DateTime _date;
  String? _accountId;
  String? _categoryId;

  @override
  void initState() {
    super.initState();
    final transaction = widget.existing;
    _titleController = TextEditingController(text: transaction?.title ?? '');
    _amountController = TextEditingController(
      text: transaction == null
          ? ''
          : MoneyFormatter.input(transaction.amountMinor, absolute: true),
    );
    _noteController = TextEditingController(text: transaction?.note ?? '');
    _income = transaction?.isIncome ?? false;
    _pending = transaction?.isPending ?? false;
    _date = transaction?.date ?? DateTime.now();
    _accountId = transaction?.accountId;
    _categoryId = transaction?.categoryId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  int? _parseMinor(String value) {
    return MoneyFormatter.parseInputToMinor(value);
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appControllerProvider);
    _accountId ??= data.accounts.firstOrNull?.id;
    _categoryId ??= data.categories.firstOrNull?.id;
    return AlertDialog(
      title: AppText(
        widget.existing == null ? 'Add transaction' : 'Edit transaction',
      ),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: false,
                      label: AppText('Expense'),
                      icon: Icon(Icons.arrow_upward),
                    ),
                    ButtonSegment(
                      value: true,
                      label: AppText('Income'),
                      icon: Icon(Icons.arrow_downward),
                    ),
                  ],
                  selected: {_income},
                  onSelectionChanged: (value) =>
                      setState(() => _income = value.first),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  key: const Key('transaction-title-field'),
                  controller: _titleController,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: context.l10n.translate(
                      'Merchant or description',
                    ),
                    prefixIcon: Icon(Icons.edit_outlined),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? context.l10n.translate('Enter a description')
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('transaction-amount-field'),
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: context.l10n.translate('Amount'),
                    prefixText: r'$ ',
                  ),
                  validator: (value) => _parseMinor(value ?? '') == null
                      ? context.l10n.translate(
                          'Enter an amount greater than zero',
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _accountId,
                  decoration: InputDecoration(
                    labelText: context.l10n.translate('Account'),
                    prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                  ),
                  items: data.accounts
                      .map(
                        (account) => DropdownMenuItem(
                          value: account.id,
                          child: AppText(account.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _accountId = value),
                  validator: (value) => value == null
                      ? context.l10n.translate(
                          'Create an account before adding a transaction',
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _categoryId,
                  decoration: InputDecoration(
                    labelText: context.l10n.translate('Category'),
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: data.categories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category.id,
                          child: AppText(category.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _categoryId = value),
                  validator: (value) => value == null
                      ? context.l10n.translate(
                          'Create a category before adding a transaction',
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final selected = await showDatePicker(
                            context: context,
                            initialDate: _date,
                            firstDate: DateTime(2015),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (selected != null) {
                            setState(() => _date = selected);
                          }
                        },
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: AppText(DateFormats.medium.format(_date)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteController,
                  minLines: 1,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: context.l10n.translate('Note (optional)'),
                    prefixIcon: Icon(Icons.notes),
                  ),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const AppText('Pending transaction'),
                  subtitle: const AppText('Keep it visibly provisional.'),
                  value: _pending,
                  onChanged: (value) => setState(() => _pending = value),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const AppText('Cancel'),
        ),
        FilledButton(
          key: const Key('save-transaction-button'),
          onPressed: data.accounts.isEmpty || data.categories.isEmpty
              ? null
              : () {
                  if (!_formKey.currentState!.validate() ||
                      _accountId == null ||
                      _categoryId == null) {
                    return;
                  }
                  final unsigned = _parseMinor(_amountController.text)!;
                  ref
                      .read(appControllerProvider.notifier)
                      .saveTransaction(
                        FinanceTransaction(
                          id: widget.existing?.id ?? '',
                          accountId: _accountId!,
                          categoryId: _categoryId!,
                          title: _titleController.text.trim(),
                          note: _noteController.text.trim(),
                          amountMinor: _income ? unsigned : -unsigned,
                          date: _date,
                          isPending: _pending,
                        ),
                      );
                  Navigator.pop(context);
                },
          child: const AppText('Save'),
        ),
      ],
    );
  }
}

Future<void> showCategoryManager(BuildContext context) => showDialog<void>(
  context: context,
  builder: (context) => const _CategoryManagerDialog(),
);

class _CategoryManagerDialog extends ConsumerWidget {
  const _CategoryManagerDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider.notifier);
    return AlertDialog(
      title: const AppText('Categories'),
      content: SizedBox(
        width: 480,
        height: 480,
        child: ListView.separated(
          itemCount: data.categories.length,
          separatorBuilder: (_, _) => const Divider(),
          itemBuilder: (context, index) {
            final category = data.categories[index];
            final deletable = controller.canDeleteCategory(category.id);
            return ListTile(
              leading: CategoryAvatar(category: category),
              title: AppText(category.name),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: context.l10n.translate('Edit ${category.name}'),
                    onPressed: () =>
                        _showCategoryEditor(context, ref, existing: category),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: deletable
                        ? 'Delete ${category.name}'
                        : 'Category is in use',
                    onPressed: deletable
                        ? () => controller.deleteCategory(category.id)
                        : null,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const AppText('Done'),
        ),
        FilledButton.icon(
          onPressed: () => _showCategoryEditor(context, ref),
          icon: const Icon(Icons.add),
          label: const AppText('New category'),
        ),
      ],
    );
  }

  Future<void> _showCategoryEditor(
    BuildContext context,
    WidgetRef ref, {
    SpendingCategory? existing,
  }) async {
    final name = TextEditingController(text: existing?.name ?? '');
    var colorValue = existing?.colorValue ?? 0xFF4E7BEF;
    const colors = [
      0xFF4E7BEF,
      0xFF1D9B68,
      0xFFF08A5D,
      0xFFE86F91,
      0xFF8E6CC0,
      0xFFD69B2D,
    ];
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: AppText(existing == null ? 'New category' : 'Edit category'),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: context.l10n.translate('Name'),
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  children: colors
                      .map(
                        (value) => InkWell(
                          onTap: () => setState(() => colorValue = value),
                          borderRadius: BorderRadius.circular(99),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Color(value),
                              shape: BoxShape.circle,
                              border: value == colorValue
                                  ? Border.all(color: Colors.white, width: 4)
                                  : null,
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 3),
                              ],
                            ),
                            child: value == colorValue
                                ? const Icon(Icons.check, color: Colors.white)
                                : null,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const AppText('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const AppText('Save'),
            ),
          ],
        ),
      ),
    );
    if (saved == true && name.text.trim().isNotEmpty) {
      ref
          .read(appControllerProvider.notifier)
          .saveCategory(
            SpendingCategory(
              id: existing?.id ?? '',
              name: name.text.trim(),
              iconCode: existing?.iconCode ?? Icons.category_outlined.codePoint,
              colorValue: colorValue,
            ),
          );
    }
    name.dispose();
  }
}
