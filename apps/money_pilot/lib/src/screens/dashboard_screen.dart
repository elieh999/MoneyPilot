import 'package:flutter/material.dart';
import 'package:money_pilot/src/localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:money_pilot/src/app_controller.dart';
import 'package:money_pilot/src/formatters.dart';
import 'package:money_pilot/src/models.dart';
import 'package:money_pilot/src/screens/transactions_screen.dart';
import 'package:money_pilot/src/theme.dart';
import 'package:money_pilot/src/widgets/common.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider.notifier);
    final recent = [...data.transactions]
      ..sort((a, b) => b.date.compareTo(a.date));
    final openBills = data.bills.where((bill) => !bill.isPaid).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return PageFrame(
      title: _greeting(),
      subtitle: 'Here is your financial flight plan for today.',
      actions: [
        FilledButton.icon(
          onPressed: () => showTransactionEditor(context),
          icon: const Icon(Icons.add),
          label: const AppText('Add transaction'),
        ),
      ],
      child: Column(
        children: [
          _SafeToSpendCard(controller: controller),
          const SizedBox(height: 18),
          AdaptiveGrid(
            children: [
              MetricCard(
                label: 'Net worth',
                value: MoneyFormatter.amount(controller.netWorthMinor),
                detail: '${data.accounts.length} connected locally',
                icon: Icons.account_balance_wallet_outlined,
              ),
              MetricCard(
                label: 'Spent this month',
                value: MoneyFormatter.amount(controller.monthlyExpenseMinor),
                detail: '${data.transactions.length} transactions tracked',
                icon: Icons.trending_down,
                accent: const Color(0xFFF08A5D),
              ),
              MetricCard(
                label: 'Savings rate',
                value: controller.monthlyIncomeMinor <= 0
                    ? 'Unavailable'
                    : MoneyFormatter.percent(controller.savingsRateBasisPoints),
                detail: controller.monthlyIncomeMinor <= 0
                    ? 'Income is needed for a meaningful rate'
                    : 'Based on cash flow this month',
                icon: Icons.savings_outlined,
                accent: AppTheme.mint,
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              final budgets = _BudgetSnapshot(
                data: data,
                controller: controller,
              );
              final bills = _UpcomingBills(bills: openBills.take(4).toList());
              return wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: budgets),
                        const SizedBox(width: 18),
                        Expanded(flex: 2, child: bills),
                      ],
                    )
                  : Column(
                      children: [budgets, const SizedBox(height: 18), bills],
                    );
            },
          ),
          const SizedBox(height: 18),
          SectionCard(
            title: 'Recent activity',
            trailing: TextButton(
              onPressed: () => context.go('/transactions'),
              child: const AppText('View all'),
            ),
            padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
            child: recent.isEmpty
                ? const Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No transactions yet',
                      message:
                          'Add your first income or expense when you are ready.',
                    ),
                  )
                : Column(
                    children: [
                      for (
                        var index = 0;
                        index < recent.take(5).length;
                        index++
                      ) ...[
                        _RecentRow(
                          transaction: recent[index],
                          category: data.categories
                              .where(
                                (category) =>
                                    category.id == recent[index].categoryId,
                              )
                              .firstOrNull,
                        ),
                        if (index != recent.take(5).length - 1) const Divider(),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }
}

class _SafeToSpendCard extends StatelessWidget {
  const _SafeToSpendCard({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label:
          'Safe to spend ${MoneyFormatter.amount(controller.safeToSpendMinor)}',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF15355A), Color(0xFF1E5D67)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF15355A).withValues(alpha: 0.22),
              blurRadius: 26,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Wrap(
          spacing: 24,
          runSpacing: 20,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_outlined, color: Color(0xFF8FE4C4)),
                      SizedBox(width: 9),
                      AppText(
                        'SAFE TO SPEND',
                        style: TextStyle(
                          color: Color(0xFF8FE4C4),
                          letterSpacing: 1.3,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AppText(
                    MoneyFormatter.amount(controller.safeToSpendMinor),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const AppText(
                    'Available after protected bills, savings, reserves, card obligations, and your monthly budget cap.',
                    style: TextStyle(color: Color(0xFFD0DEE7), height: 1.45),
                  ),
                ],
              ),
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
              ),
              onPressed: () => _showExplanation(context),
              icon: const Icon(Icons.info_outline),
              label: const AppText('How it is calculated'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showExplanation(BuildContext context) async {
    final input = controller.safeToSpendInput;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                'Your safe spending breakdown',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              AppText(
                'MoneyPilot uses integer cents and the more conservative of liquidity and remaining discretionary budgets.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              _BreakdownRow(
                'Included available balances',
                input.availableMinor,
              ),
              _BreakdownRow(
                'Confirmed income before horizon',
                input.confirmedIncomeMinor,
              ),
              _BreakdownRow(
                'Upcoming required bills',
                -input.requiredBillsMinor,
              ),
              _BreakdownRow('Planned savings', -input.plannedSavingsMinor),
              _BreakdownRow(
                'Goal contributions',
                -input.goalContributionsMinor,
              ),
              _BreakdownRow('Emergency reserve', -input.emergencyReserveMinor),
              _BreakdownRow(
                'Credit obligations',
                -input.creditObligationsMinor,
              ),
              _BreakdownRow('Personal safety buffer', -input.safetyBufferMinor),
              const Divider(height: 26),
              _BreakdownRow(
                'Liquidity ceiling',
                input.liquidityCeilingMinor.clamp(0, 1 << 62).toInt(),
                strong: true,
              ),
              if (input.budgetRemainingMinor != null)
                _BreakdownRow(
                  'Discretionary budget remainder',
                  input.budgetRemainingMinor!,
                  strong: true,
                ),
              const Divider(height: 26),
              _BreakdownRow(
                'Safe to spend',
                controller.safeToSpendMinor,
                strong: true,
              ),
              const SizedBox(height: 16),
              const StatusPill(
                label:
                    'Pending authorizations already reduce available balances',
                icon: Icons.verified_outlined,
                color: AppTheme.mint,
              ),
              const SizedBox(height: 18),
              AppText(
                'This planning estimate is not financial advice. Review account inclusion and upcoming commitments when your situation changes.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow(this.label, this.minor, {this.strong = false});

  final String label;
  final int minor;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
            MoneyFormatter.amount(minor),
            style: TextStyle(
              fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetSnapshot extends StatelessWidget {
  const _BudgetSnapshot({required this.data, required this.controller});

  final AppData data;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Budget pulse',
      trailing: TextButton(
        onPressed: () => context.go('/budgets'),
        child: const AppText('Manage'),
      ),
      child: data.budgets.isEmpty
          ? const EmptyState(
              icon: Icons.donut_large,
              title: 'No budgets',
              message: 'Create a guardrail to see progress here.',
            )
          : Column(
              children: data.budgets.take(4).map((budget) {
                final category = data.categories
                    .where((item) => item.id == budget.categoryId)
                    .firstOrNull;
                final status = controller.statusForBudget(budget);
                final value = (status.usageBasisPoints / 10000).clamp(0.0, 1.0);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AppText(
                              category?.name ?? 'Unknown',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          AppText(
                            '${MoneyFormatter.amount(budget.plannedMinor - status.remainingMinor)} / ${MoneyFormatter.amount(budget.plannedMinor)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: value,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(99),
                        color: status.needsReview
                            ? const Color(0xFFF08A5D)
                            : const Color(0xFF1D9B68),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _UpcomingBills extends StatelessWidget {
  const _UpcomingBills({required this.bills});

  final List<Bill> bills;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Upcoming bills',
      trailing: TextButton(
        onPressed: () => context.go('/bills'),
        child: const AppText('View'),
      ),
      child: bills.isEmpty
          ? const EmptyState(
              icon: Icons.check_circle_outline,
              title: 'All clear',
              message: 'No open bills are scheduled.',
            )
          : Column(
              children: bills
                  .map(
                    (bill) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: const Icon(Icons.receipt_long_outlined),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  bill.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                AppText(
                                  'Due ${DateFormats.short.format(bill.dueDate)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          AppText(
                            MoneyFormatter.amount(bill.amountMinor),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.transaction, required this.category});

  final FinanceTransaction transaction;
  final SpendingCategory? category;

  @override
  Widget build(BuildContext context) {
    final resolved =
        category ??
        const SpendingCategory(
          id: 'unknown',
          name: 'Other',
          iconCode: 0xe5d3,
          colorValue: 0xFF747B8A,
        );
    return InkWell(
      onTap: () => showTransactionEditor(context, existing: transaction),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Row(
          children: [
            CategoryAvatar(category: resolved),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    transaction.title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  AppText(
                    '${resolved.name} • ${DateFormats.short.format(transaction.date)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            AmountText(minor: transaction.amountMinor, emphasized: true),
          ],
        ),
      ),
    );
  }
}
