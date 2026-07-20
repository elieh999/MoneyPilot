import 'package:flutter/material.dart';
import 'package:money_pilot/src/localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_pilot/src/app_controller.dart';
import 'package:money_pilot/src/finance_engine.dart';
import 'package:money_pilot/src/formatters.dart';
import 'package:money_pilot/src/models.dart';
import 'package:money_pilot/src/widgets/common.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider.notifier);
    final totalPlanned = data.budgets.fold(
      0,
      (total, budget) => total + budget.plannedMinor,
    );
    final totalSpent = data.budgets.fold(
      0,
      (total, budget) => total + controller.spentForCategory(budget.categoryId),
    );
    return PageFrame(
      title: 'Budgets',
      subtitle:
          '${DateFormats.month.format(DateTime.now())} spending guardrails.',
      actions: [
        FilledButton.icon(
          onPressed: () => showBudgetEditor(context),
          icon: const Icon(Icons.add),
          label: const AppText('Add budget'),
        ),
      ],
      child: Column(
        children: [
          AdaptiveGrid(
            children: [
              MetricCard(
                label: 'Planned',
                value: MoneyFormatter.amount(totalPlanned),
                icon: Icons.event_note_outlined,
              ),
              MetricCard(
                label: 'Spent',
                value: MoneyFormatter.amount(totalSpent),
                icon: Icons.shopping_bag_outlined,
                accent: const Color(0xFFF08A5D),
              ),
              MetricCard(
                label: 'Remaining',
                value: MoneyFormatter.amount(totalPlanned - totalSpent),
                icon: Icons.savings_outlined,
                accent: const Color(0xFF1D9B68),
              ),
            ],
          ),
          const SizedBox(height: 20),
          data.budgets.isEmpty
              ? EmptyState(
                  icon: Icons.donut_large_outlined,
                  title: 'No budgets yet',
                  message: 'Add a category guardrail to start planning.',
                  action: FilledButton(
                    onPressed: () => showBudgetEditor(context),
                    child: const AppText('Create budget'),
                  ),
                )
              : AdaptiveGrid(
                  minItemWidth: 330,
                  children: data.budgets.map((budget) {
                    final category = data.categories
                        .where((item) => item.id == budget.categoryId)
                        .firstOrNull;
                    return _BudgetCard(
                      budget: budget,
                      category: category,
                      status: controller.statusForBudget(budget),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }
}

class _BudgetCard extends ConsumerWidget {
  const _BudgetCard({
    required this.budget,
    required this.category,
    required this.status,
  });

  final Budget budget;
  final SpendingCategory? category;
  final BudgetStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolved =
        category ??
        const SpendingCategory(
          id: 'unknown',
          name: 'Unknown',
          iconCode: 0xe5d3,
          colorValue: 0xFF747B8A,
        );
    final spent = budget.plannedMinor - status.remainingMinor;
    final progress = (status.usageBasisPoints / 10000).clamp(0.0, 1.0);
    final over = status.remainingMinor < 0;
    final color = over
        ? Theme.of(context).colorScheme.error
        : Color(resolved.colorValue);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CategoryAvatar(category: resolved),
              const SizedBox(width: 12),
              Expanded(
                child: AppText(
                  resolved.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: context.l10n.translate(
                  '${resolved.name} budget actions',
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    showBudgetEditor(context, existing: budget);
                  } else if (value == 'delete') {
                    ref
                        .read(appControllerProvider.notifier)
                        .deleteBudget(budget.id);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: AppText('Edit')),
                  PopupMenuItem(value: 'delete', child: AppText('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: AppText(
                  '${MoneyFormatter.amount(spent)} spent',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              AppText(
                'of ${MoneyFormatter.amount(budget.plannedMinor)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Semantics(
            label:
                '${resolved.name} budget ${MoneyFormatter.percent(status.usageBasisPoints)} used',
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              borderRadius: BorderRadius.circular(99),
              color: color,
              backgroundColor: color.withValues(alpha: 0.13),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppText(
                  over
                      ? '${MoneyFormatter.amount(status.remainingMinor.abs())} over plan'
                      : '${MoneyFormatter.amount(status.remainingMinor)} left',
                  style: TextStyle(color: color, fontWeight: FontWeight.w800),
                ),
              ),
              StatusPill(
                label: status.needsReview ? 'Review' : 'On track',
                icon: status.needsReview
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline,
                color: color,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> showBudgetEditor(BuildContext context, {Budget? existing}) =>
    showDialog<void>(
      context: context,
      builder: (context) => _BudgetEditorDialog(existing: existing),
    );

class _BudgetEditorDialog extends ConsumerStatefulWidget {
  const _BudgetEditorDialog({this.existing});

  final Budget? existing;

  @override
  ConsumerState<_BudgetEditorDialog> createState() =>
      _BudgetEditorDialogState();
}

class _BudgetEditorDialogState extends ConsumerState<_BudgetEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  String? _categoryId;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.existing?.categoryId;
    _amountController = TextEditingController(
      text: widget.existing == null
          ? ''
          : MoneyFormatter.input(widget.existing!.plannedMinor),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  int? _minor(String value) {
    return MoneyFormatter.parseInputToMinor(value);
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appControllerProvider);
    _categoryId ??= data.categories.firstOrNull?.id;
    return AlertDialog(
      title: AppText(widget.existing == null ? 'Add budget' : 'Edit budget'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _categoryId,
                decoration: InputDecoration(
                  labelText: context.l10n.translate('Category'),
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: data.categories
                    .where((category) => category.id != 'salary')
                    .map(
                      (category) => DropdownMenuItem(
                        value: category.id,
                        child: AppText(category.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _categoryId = value),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: context.l10n.translate('Monthly plan'),
                  prefixText: r'$ ',
                ),
                validator: (value) => _minor(value ?? '') == null
                    ? context.l10n.translate(
                        'Enter an amount greater than zero',
                      )
                    : null,
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
            if (!_formKey.currentState!.validate() || _categoryId == null) {
              return;
            }
            ref
                .read(appControllerProvider.notifier)
                .saveBudget(
                  Budget(
                    id: widget.existing?.id ?? '',
                    categoryId: _categoryId!,
                    plannedMinor: _minor(_amountController.text)!,
                    month: DateTime(DateTime.now().year, DateTime.now().month),
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
