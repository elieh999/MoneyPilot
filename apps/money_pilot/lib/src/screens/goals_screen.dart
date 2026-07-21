import 'package:flutter/material.dart';
import 'package:money_pilot/src/localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_pilot/src/app_controller.dart';
import 'package:money_pilot/src/formatters.dart';
import 'package:money_pilot/src/models.dart';
import 'package:money_pilot/src/widgets/common.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appControllerProvider);
    final saved = data.goals.fold(0, (total, goal) => total + goal.savedMinor);
    final target = data.goals.fold(
      0,
      (total, goal) => total + goal.targetMinor,
    );
    return PageFrame(
      title: 'Goals',
      subtitle: 'Turn long term plans into clear, manageable milestones.',
      actions: [
        FilledButton.icon(
          onPressed: () => showGoalEditor(context),
          icon: const Icon(Icons.add),
          label: const AppText('Add goal'),
        ),
      ],
      child: Column(
        children: [
          AdaptiveGrid(
            children: [
              MetricCard(
                label: 'Saved toward goals',
                value: MoneyFormatter.amount(saved),
                detail: 'Across ${data.goals.length} active goals',
                icon: Icons.savings_outlined,
                accent: const Color(0xFF1D9B68),
              ),
              MetricCard(
                label: 'Combined target',
                value: MoneyFormatter.amount(target),
                detail: target == 0
                    ? 'Create your first milestone'
                    : '${((saved / target) * 100).round()}% funded',
                icon: Icons.flag_outlined,
              ),
            ],
          ),
          const SizedBox(height: 20),
          data.goals.isEmpty
              ? const EmptyState(
                  icon: Icons.flag_outlined,
                  title: 'No goals yet',
                  message: 'Create a milestone for the future you want.',
                )
              : AdaptiveGrid(
                  minItemWidth: 340,
                  children: data.goals
                      .map((goal) => _GoalCard(goal: goal))
                      .toList(),
                ),
        ],
      ),
    );
  }
}

class _GoalCard extends ConsumerWidget {
  const _GoalCard({required this.goal});

  final SavingsGoal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = goal.targetMinor <= 0
        ? 0.0
        : (goal.savedMinor / goal.targetMinor).clamp(0.0, 1.0);
    final remaining = (goal.targetMinor - goal.savedMinor).clamp(
      0,
      goal.targetMinor,
    );
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4E7BEF), Color(0xFF26C18A)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.flag_rounded, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      goal.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    AppText(
                      'Target ${DateFormats.medium.format(goal.targetDate)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: context.l10n.translate('${goal.name} actions'),
                onSelected: (value) {
                  if (value == 'edit') {
                    showGoalEditor(context, existing: goal);
                  } else if (value == 'delete') {
                    ref
                        .read(appControllerProvider.notifier)
                        .deleteGoal(goal.id);
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
            MoneyFormatter.amount(goal.savedMinor),
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          AppText('of ${MoneyFormatter.amount(goal.targetMinor)}'),
          const SizedBox(height: 14),
          LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            borderRadius: BorderRadius.circular(99),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: AppText(
                  '${MoneyFormatter.amount(remaining.toInt())} to go',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              AppText(
                '${(progress * 100).round()}%',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: progress >= 1
                  ? null
                  : () => _showContribution(context, ref),
              icon: const Icon(Icons.add_card_outlined),
              label: AppText(
                progress >= 1 ? 'Goal reached' : 'Add contribution',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showContribution(BuildContext context, WidgetRef ref) async {
    final amount = TextEditingController();
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: AppText('Contribute to ${goal.name}'),
        content: TextField(
          controller: amount,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: context.l10n.translate('Contribution'),
            prefixText: r'$ ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const AppText('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(
                context,
                MoneyFormatter.parseInputToMinor(amount.text),
              );
            },
            child: const AppText('Add'),
          ),
        ],
      ),
    );
    amount.dispose();
    if (result != null && result > 0) {
      ref
          .read(appControllerProvider.notifier)
          .contributeToGoal(goal.id, result);
    }
  }
}

Future<void> showGoalEditor(BuildContext context, {SavingsGoal? existing}) =>
    showDialog<void>(
      context: context,
      builder: (context) => _GoalEditorDialog(existing: existing),
    );

class _GoalEditorDialog extends ConsumerStatefulWidget {
  const _GoalEditorDialog({this.existing});

  final SavingsGoal? existing;

  @override
  ConsumerState<_GoalEditorDialog> createState() => _GoalEditorDialogState();
}

class _GoalEditorDialogState extends ConsumerState<_GoalEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _targetController;
  late final TextEditingController _savedController;
  late DateTime _targetDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _targetController = TextEditingController(
      text: widget.existing == null
          ? ''
          : MoneyFormatter.input(widget.existing!.targetMinor),
    );
    _savedController = TextEditingController(
      text: widget.existing == null
          ? '0.00'
          : MoneyFormatter.input(widget.existing!.savedMinor),
    );
    _targetDate =
        widget.existing?.targetDate ??
        DateTime.now().add(const Duration(days: 365));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _savedController.dispose();
    super.dispose();
  }

  int? _minor(String value, {bool allowZero = false}) {
    return MoneyFormatter.parseInputToMinor(value, allowZero: allowZero);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: AppText(widget.existing == null ? 'Add goal' : 'Edit goal'),
      content: SizedBox(
        width: 470,
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
                    labelText: context.l10n.translate('Goal name'),
                    prefixIcon: Icon(Icons.flag_outlined),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? context.l10n.translate('Enter a goal name')
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _targetController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: context.l10n.translate('Target amount'),
                    prefixText: r'$ ',
                  ),
                  validator: (value) => _minor(value ?? '') == null
                      ? context.l10n.translate(
                          'Enter a target greater than zero',
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _savedController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: context.l10n.translate('Already saved'),
                    prefixText: r'$ ',
                  ),
                  validator: (value) =>
                      _minor(value ?? '', allowZero: true) == null
                      ? context.l10n.translate('Enter zero or more')
                      : null,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final selected = await showDatePicker(
                        context: context,
                        initialDate: _targetDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(
                          const Duration(days: 3650),
                        ),
                      );
                      if (selected != null) {
                        setState(() => _targetDate = selected);
                      }
                    },
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: AppText(
                      'Target ${DateFormats.medium.format(_targetDate)}',
                    ),
                  ),
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
            final target = _minor(_targetController.text)!;
            final saved = _minor(_savedController.text, allowZero: true)!;
            ref
                .read(appControllerProvider.notifier)
                .saveGoal(
                  SavingsGoal(
                    id: widget.existing?.id ?? '',
                    name: _nameController.text.trim(),
                    targetMinor: target,
                    savedMinor: saved.clamp(0, target).toInt(),
                    targetDate: _targetDate,
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
