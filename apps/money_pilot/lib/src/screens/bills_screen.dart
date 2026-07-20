import 'package:flutter/material.dart';
import 'package:money_pilot/src/localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_pilot/src/app_controller.dart';
import 'package:money_pilot/src/formatters.dart';
import 'package:money_pilot/src/models.dart';
import 'package:money_pilot/src/widgets/common.dart';

class BillsScreen extends ConsumerWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appControllerProvider);
    final openBills = data.bills.where((bill) => !bill.isPaid).toList();
    final dueSoon = openBills
        .where(
          (bill) => bill.dueDate.isBefore(
            DateTime.now().add(const Duration(days: 14)),
          ),
        )
        .fold(0, (total, bill) => total + bill.amountMinor);
    return PageFrame(
      title: 'Bills',
      subtitle: 'See commitments before they affect your available cash.',
      actions: [
        FilledButton.icon(
          onPressed: () => showBillEditor(context),
          icon: const Icon(Icons.add),
          label: const AppText('Add bill'),
        ),
      ],
      child: Column(
        children: [
          AdaptiveGrid(
            children: [
              MetricCard(
                label: 'Due in 14 days',
                value: MoneyFormatter.amount(dueSoon),
                detail: '${openBills.length} open bills total',
                icon: Icons.event_note_outlined,
                accent: const Color(0xFFF08A5D),
              ),
              MetricCard(
                label: 'On autopay',
                value: '${openBills.where((bill) => bill.autopay).length}',
                detail: 'Still protected in safe to spend',
                icon: Icons.autorenew_rounded,
                accent: const Color(0xFF1D9B68),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: 'Upcoming and recent',
            padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
            child: data.bills.isEmpty
                ? const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No bills yet',
                    message: 'Add recurring commitments to improve forecasts.',
                  )
                : Column(
                    children: [
                      for (
                        var index = 0;
                        index < data.bills.length;
                        index++
                      ) ...[
                        _BillRow(bill: data.bills[index]),
                        if (index != data.bills.length - 1) const Divider(),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _BillRow extends ConsumerWidget {
  const _BillRow({required this.bill});

  final Bill bill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = bill.dueDate.difference(DateTime.now()).inDays;
    final overdue = days < 0 && !bill.isPaid;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          Semantics(
            label: bill.isPaid
                ? 'Mark ${bill.name} unpaid'
                : 'Mark ${bill.name} paid',
            child: Checkbox.adaptive(
              value: bill.isPaid,
              onChanged: (_) =>
                  ref.read(appControllerProvider.notifier).toggleBillPaid(bill),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.receipt_long_outlined),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  bill.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    decoration: bill.isPaid ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 3),
                AppText(
                  '${DateFormats.medium.format(bill.dueDate)}${bill.autopay ? ' • Autopay' : ''}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: overdue
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          AppText(
            MoneyFormatter.amount(bill.amountMinor),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          PopupMenuButton<String>(
            tooltip: context.l10n.translate('${bill.name} actions'),
            onSelected: (value) {
              if (value == 'edit') {
                showBillEditor(context, existing: bill);
              } else if (value == 'delete') {
                ref.read(appControllerProvider.notifier).deleteBill(bill.id);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: AppText('Edit')),
              PopupMenuItem(value: 'delete', child: AppText('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> showBillEditor(BuildContext context, {Bill? existing}) =>
    showDialog<void>(
      context: context,
      builder: (context) => _BillEditorDialog(existing: existing),
    );

class _BillEditorDialog extends ConsumerStatefulWidget {
  const _BillEditorDialog({this.existing});

  final Bill? existing;

  @override
  ConsumerState<_BillEditorDialog> createState() => _BillEditorDialogState();
}

class _BillEditorDialogState extends ConsumerState<_BillEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late DateTime _dueDate;
  late bool _autopay;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _amountController = TextEditingController(
      text: widget.existing == null
          ? ''
          : MoneyFormatter.input(widget.existing!.amountMinor),
    );
    _dueDate =
        widget.existing?.dueDate ?? DateTime.now().add(const Duration(days: 7));
    _autopay = widget.existing?.autopay ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  int? _minor(String value) {
    return MoneyFormatter.parseInputToMinor(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: AppText(widget.existing == null ? 'Add bill' : 'Edit bill'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: context.l10n.translate('Bill name'),
                  prefixIcon: Icon(Icons.receipt_long_outlined),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? context.l10n.translate('Enter a bill name')
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: context.l10n.translate('Amount'),
                  prefixText: r'$ ',
                ),
                validator: (value) => _minor(value ?? '') == null
                    ? context.l10n.translate(
                        'Enter an amount greater than zero',
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final selected = await showDatePicker(
                      context: context,
                      initialDate: _dueDate,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 365),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (selected != null) setState(() => _dueDate = selected);
                  },
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: AppText('Due ${DateFormats.medium.format(_dueDate)}'),
                ),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const AppText('Autopay'),
                subtitle: const AppText(
                  'Still count it as a protected commitment.',
                ),
                value: _autopay,
                onChanged: (value) => setState(() => _autopay = value),
              ),
            ],
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
                .saveBill(
                  Bill(
                    id: widget.existing?.id ?? '',
                    name: _nameController.text.trim(),
                    amountMinor: _minor(_amountController.text)!,
                    dueDate: _dueDate,
                    isPaid: widget.existing?.isPaid ?? false,
                    autopay: _autopay,
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
