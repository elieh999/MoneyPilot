class SafeToSpendInput {
  const SafeToSpendInput({
    required this.availableMinor,
    required this.confirmedIncomeMinor,
    required this.pendingOutgoingMinor,
    required this.requiredBillsMinor,
    required this.minimumDebtMinor,
    required this.plannedSavingsMinor,
    required this.goalContributionsMinor,
    required this.emergencyReserveMinor,
    required this.creditObligationsMinor,
    required this.safetyBufferMinor,
    required this.knownRequiredMinor,
    this.budgetRemainingMinor,
  });

  final int availableMinor;
  final int confirmedIncomeMinor;
  final int pendingOutgoingMinor;
  final int requiredBillsMinor;
  final int minimumDebtMinor;
  final int plannedSavingsMinor;
  final int goalContributionsMinor;
  final int emergencyReserveMinor;
  final int creditObligationsMinor;
  final int safetyBufferMinor;
  final int knownRequiredMinor;
  final int? budgetRemainingMinor;

  int get liquidityCeilingMinor =>
      availableMinor +
      confirmedIncomeMinor -
      pendingOutgoingMinor -
      requiredBillsMinor -
      minimumDebtMinor -
      plannedSavingsMinor -
      goalContributionsMinor -
      emergencyReserveMinor -
      creditObligationsMinor -
      safetyBufferMinor -
      knownRequiredMinor;
}

class BudgetStatus {
  const BudgetStatus({
    required this.remainingMinor,
    required this.usageBasisPoints,
    required this.needsReview,
  });

  final int remainingMinor;
  final int usageBasisPoints;
  final bool needsReview;
}

class FinanceEngine {
  const FinanceEngine._();

  static int safeToSpend(SafeToSpendInput input) {
    final liquidity = input.liquidityCeilingMinor < 0
        ? 0
        : input.liquidityCeilingMinor;
    final budget = input.budgetRemainingMinor;
    if (budget == null) return liquidity;
    final nonNegativeBudget = budget < 0 ? 0 : budget;
    return liquidity < nonNegativeBudget ? liquidity : nonNegativeBudget;
  }

  static int savingsRateBasisPoints({
    required int incomeMinor,
    required int expenseMinor,
  }) {
    if (incomeMinor <= 0) return 0;
    final savings = incomeMinor - expenseMinor;
    if (savings <= 0) return 0;
    return _roundRatioAwayFromZero(savings * 10000, incomeMinor);
  }

  static BudgetStatus budgetStatus({
    required int plannedMinor,
    required int spentMinor,
  }) {
    final remaining = plannedMinor - spentMinor;
    if (plannedMinor <= 0) {
      return BudgetStatus(
        remainingMinor: remaining,
        usageBasisPoints: 0,
        needsReview: true,
      );
    }
    final usage = _roundRatioAwayFromZero(spentMinor * 10000, plannedMinor);
    return BudgetStatus(
      remainingMinor: remaining,
      usageBasisPoints: usage,
      needsReview: usage >= 9000,
    );
  }

  static int _roundRatioAwayFromZero(int numerator, int denominator) {
    if (denominator == 0) return 0;
    final negative = (numerator < 0) != (denominator < 0);
    final absoluteNumerator = numerator.abs();
    final absoluteDenominator = denominator.abs();
    final rounded =
        (absoluteNumerator + absoluteDenominator ~/ 2) ~/ absoluteDenominator;
    return negative ? -rounded : rounded;
  }
}
