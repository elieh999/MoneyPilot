import 'package:flutter/material.dart';
import 'package:money_pilot/src/localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:money_pilot/src/app_controller.dart';
import 'package:money_pilot/src/formatters.dart';
import 'package:money_pilot/src/theme.dart';
import 'package:money_pilot/src/widgets/common.dart';

class PurchaseCheckScreen extends ConsumerStatefulWidget {
  const PurchaseCheckScreen({super.key});

  @override
  ConsumerState<PurchaseCheckScreen> createState() =>
      _PurchaseCheckScreenState();
}

class _PurchaseCheckScreenState extends ConsumerState<PurchaseCheckScreen> {
  final _item = TextEditingController();
  final _amount = TextEditingController();
  int _coolingDays = 3;
  int? _checkedAmount;

  @override
  void dispose() {
    _item.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider.notifier);
    return PageFrame(
      title: 'Smart purchase check',
      subtitle: 'Pressure-test a purchase without being told what to do.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final form = _buildForm(context);
          final result = _buildResult(
            context,
            controller,
            data.accounts.isEmpty,
          );
          if (constraints.maxWidth < 900) {
            return Column(children: [form, const SizedBox(height: 18), result]);
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: form),
              const SizedBox(width: 18),
              Expanded(flex: 3, child: result),
            ],
          );
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context) => SectionCard(
    title: 'Purchase details',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: const Key('purchase-item-field'),
          controller: _item,
          decoration: InputDecoration(
            labelText: context.l10n.translate('What are you considering?'),
            prefixIcon: Icon(Icons.shopping_bag_outlined),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          key: const Key('purchase-amount-field'),
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: context.l10n.translate('Price'),
            prefixText: r'$ ',
          ),
        ),
        const SizedBox(height: 18),
        AppText(
          'Optional cooling-off period',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 1, label: AppText('24h')),
            ButtonSegment(value: 3, label: AppText('3d')),
            ButtonSegment(value: 7, label: AppText('7d')),
            ButtonSegment(value: 30, label: AppText('30d')),
          ],
          selected: {_coolingDays},
          onSelectionChanged: (values) =>
              setState(() => _coolingDays = values.first),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const Key('check-purchase-button'),
            onPressed: _check,
            icon: const Icon(Icons.calculate_outlined),
            label: const AppText('Check this purchase'),
          ),
        ),
      ],
    ),
  );

  Widget _buildResult(
    BuildContext context,
    AppController controller,
    bool accountsEmpty,
  ) {
    final amount = _checkedAmount;
    if (amount == null) {
      return const SectionCard(
        title: 'Decision view',
        child: EmptyState(
          icon: Icons.balance_outlined,
          title: 'Enter a real price',
          message:
              'MoneyPilot will compare it with your safe-to-spend amount and show the calculation.',
        ),
      );
    }
    if (accountsEmpty) {
      return const SectionCard(
        title: 'Decision view',
        child: EmptyState(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Add an account first',
          message:
              'Affordability needs an actual available balance. No balance is assumed.',
        ),
      );
    }
    final safe = controller.safeToSpendMinor;
    final remaining = safe - amount;
    final fits = remaining >= 0;
    final item = _item.text.trim().isEmpty
        ? 'This purchase'
        : _item.text.trim();
    final monthlySurplus =
        controller.monthlyIncomeMinor - controller.monthlyExpenseMinor;
    final deficit = fits ? 0 : amount - safe;
    final dailySurplus = monthlySurplus > 0 ? monthlySurplus ~/ 30 : 0;
    final waitDays = deficit > 0 && dailySurplus > 0
        ? (deficit + dailySurplus - 1) ~/ dailySurplus
        : null;
    return SectionCard(
      title: 'Decision view',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusPill(
            label: fits ? 'Fits current allowance' : 'Would exceed allowance',
            icon: fits
                ? Icons.check_circle_outline
                : Icons.warning_amber_rounded,
            color: fits ? AppTheme.mint : const Color(0xFFD17C13),
          ),
          const SizedBox(height: 18),
          AppText(
            item,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          AppText(
            MoneyFormatter.amount(amount),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Divider(height: 32),
          _DecisionRow(label: 'Safe to spend before purchase', value: safe),
          _DecisionRow(label: 'Purchase price', value: -amount),
          _DecisionRow(
            label: 'Estimated amount afterward',
            value: remaining,
            strong: true,
          ),
          const SizedBox(height: 18),
          AppText(
            fits
                ? 'The purchase fits the records you entered. Your selected $_coolingDays-day pause ends on ${DateFormats.medium.format(DateTime.now().add(Duration(days: _coolingDays)))}.'
                : waitDays == null
                ? 'The purchase exceeds your current allowance. There is not enough recorded monthly surplus to estimate a catch-up date.'
                : 'At the current recorded monthly surplus, closing the gap would take roughly $waitDays day${waitDays == 1 ? '' : 's'}.',
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () {
              ref
                  .read(appControllerProvider.notifier)
                  .askCoach(
                    'Can I afford $item for ${MoneyFormatter.input(amount)}?',
                  );
              context.go('/coach');
            },
            icon: const Icon(Icons.auto_awesome_outlined),
            label: const AppText('Discuss with AI Coach'),
          ),
          const SizedBox(height: 14),
          AppText(
            'Educational estimate—not financial, tax, investment, or legal advice.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  void _check() {
    final parsed = MoneyFormatter.parseInputToMinor(_amount.text);
    if (parsed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: AppText('Enter a price greater than zero.')),
      );
      return;
    }
    setState(() => _checkedAmount = parsed);
  }
}

class _DecisionRow extends StatelessWidget {
  const _DecisionRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final int value;
  final bool strong;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Expanded(
          child: AppText(
            label,
            style: TextStyle(fontWeight: strong ? FontWeight.w800 : null),
          ),
        ),
        AppText(
          MoneyFormatter.amount(value),
          style: TextStyle(
            fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
