import 'package:flutter/material.dart';
import 'package:money_pilot/src/localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_pilot/src/app_controller.dart';
import 'package:money_pilot/src/formatters.dart';
import 'package:money_pilot/src/models.dart';
import 'package:money_pilot/src/widgets/common.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider.notifier);
    return PageFrame(
      title: 'Accounts',
      subtitle: 'Keep balances and safe-to-spend inclusion rules transparent.',
      actions: [
        FilledButton.icon(
          onPressed: () => showAccountEditor(context),
          icon: const Icon(Icons.add),
          label: const AppText('Add account'),
        ),
      ],
      child: Column(
        children: [
          AdaptiveGrid(
            minItemWidth: 290,
            children: data.accounts
                .map(
                  (account) => _AccountCard(
                    account: account,
                    transactionCount: data.transactions
                        .where((item) => item.accountId == account.id)
                        .length,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: 'Portfolio summary',
            child: Column(
              children: [
                _SummaryRow(
                  label: 'Assets',
                  value: data.accounts
                      .where((account) => account.balanceMinor > 0)
                      .fold(
                        0,
                        (total, account) => total + account.balanceMinor,
                      ),
                ),
                const SizedBox(height: 10),
                _SummaryRow(
                  label: 'Liabilities',
                  value: data.accounts
                      .where((account) => account.balanceMinor < 0)
                      .fold(
                        0,
                        (total, account) => total + account.balanceMinor.abs(),
                      ),
                  negative: true,
                ),
                const Divider(height: 26),
                _SummaryRow(
                  label: 'Net worth',
                  value: controller.netWorthMinor,
                  emphasized: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends ConsumerWidget {
  const _AccountCard({required this.account, required this.transactionCount});

  final MoneyAccount account;
  final int transactionCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Color(account.colorValue);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showAccountEditor(context, existing: account),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      account.isCredit
                          ? Icons.credit_card
                          : account.type == 'Savings'
                          ? Icons.savings_outlined
                          : Icons.account_balance_outlined,
                      color: color,
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    tooltip: context.l10n.translate('Account actions'),
                    onSelected: (value) async {
                      if (value == 'edit') {
                        await showAccountEditor(context, existing: account);
                      } else if (value == 'delete' && context.mounted) {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const AppText('Delete account?'),
                            content: AppText(
                              'Deleting ${account.name} also removes its $transactionCount local transactions.',
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
                              .deleteAccount(account.id);
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
              const SizedBox(height: 22),
              AppText(
                account.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              AppText(
                account.type,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              AppText(
                MoneyFormatter.amount(account.balanceMinor),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  StatusPill(
                    label: account.includedInSafeToSpend
                        ? 'Included in safety'
                        : 'Excluded from safety',
                    icon: account.includedInSafeToSpend
                        ? Icons.shield_outlined
                        : Icons.visibility_off_outlined,
                    color: account.includedInSafeToSpend
                        ? const Color(0xFF1D9B68)
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.negative = false,
    this.emphasized = false,
  });

  final String label;
  final int value;
  final bool negative;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppText(
            label,
            style: TextStyle(
              fontWeight: emphasized ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
        AppText(
          MoneyFormatter.amount(negative ? -value : value),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: emphasized ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

Future<void> showAccountEditor(
  BuildContext context, {
  MoneyAccount? existing,
}) => showDialog<void>(
  context: context,
  builder: (context) => _AccountEditorDialog(existing: existing),
);

class _AccountEditorDialog extends ConsumerStatefulWidget {
  const _AccountEditorDialog({this.existing});

  final MoneyAccount? existing;

  @override
  ConsumerState<_AccountEditorDialog> createState() =>
      _AccountEditorDialogState();
}

class _AccountEditorDialogState extends ConsumerState<_AccountEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;
  late String _type;
  late int _colorValue;
  late bool _included;

  static const _colors = [
    0xFF4E7BEF,
    0xFF1D9B68,
    0xFF8E6CC0,
    0xFFF08A5D,
    0xFF2F9CCB,
  ];

  @override
  void initState() {
    super.initState();
    final account = widget.existing;
    _nameController = TextEditingController(text: account?.name ?? '');
    _balanceController = TextEditingController(
      text: account == null ? '' : MoneyFormatter.input(account.balanceMinor),
    );
    _type = account?.type ?? 'Checking';
    _colorValue = account?.colorValue ?? _colors.first;
    _included = account?.includedInSafeToSpend ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  int? _minor(String value) {
    return MoneyFormatter.parseInputToMinor(
      value,
      allowNegative: true,
      allowZero: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: AppText(widget.existing == null ? 'Add account' : 'Edit account'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: context.l10n.translate('Account name'),
                    prefixIcon: Icon(Icons.account_balance_outlined),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? context.l10n.translate('Enter an account name')
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: InputDecoration(
                    labelText: context.l10n.translate('Account type'),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Checking',
                      child: AppText('Checking'),
                    ),
                    DropdownMenuItem(
                      value: 'Savings',
                      child: AppText('Savings'),
                    ),
                    DropdownMenuItem(
                      value: 'Credit card',
                      child: AppText('Credit card'),
                    ),
                    DropdownMenuItem(value: 'Cash', child: AppText('Cash')),
                    DropdownMenuItem(
                      value: 'Investment',
                      child: AppText('Investment'),
                    ),
                  ],
                  onChanged: (value) => setState(() {
                    _type = value ?? _type;
                    if (_type == 'Credit card') _included = false;
                  }),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _balanceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: InputDecoration(
                    labelText: context.l10n.translate('Current balance'),
                    prefixText: r'$ ',
                    helperText: context.l10n.translate(
                      'Use a negative amount for debt.',
                    ),
                  ),
                  validator: (value) => _minor(value ?? '') == null
                      ? context.l10n.translate('Enter a valid balance')
                      : null,
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppText(
                    'Color',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 12,
                    children: _colors
                        .map(
                          (value) => ChoiceChip(
                            label: const SizedBox(width: 14, height: 14),
                            selected: _colorValue == value,
                            avatar: CircleAvatar(backgroundColor: Color(value)),
                            onSelected: (_) =>
                                setState(() => _colorValue = value),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const AppText('Include in safe to spend'),
                  subtitle: const AppText(
                    'Only include liquid balances you can actually use.',
                  ),
                  value: _included,
                  onChanged: (value) => setState(() => _included = value),
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
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            ref
                .read(appControllerProvider.notifier)
                .saveAccount(
                  MoneyAccount(
                    id: widget.existing?.id ?? '',
                    name: _nameController.text.trim(),
                    type: _type,
                    balanceMinor: _minor(_balanceController.text)!,
                    colorValue: _colorValue,
                    includedInSafeToSpend: _included,
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
