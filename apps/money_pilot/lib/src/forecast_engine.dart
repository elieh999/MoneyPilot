class CashForecastPoint {
  const CashForecastPoint({required this.month, required this.balanceMinor});

  final DateTime month;
  final int balanceMinor;
}

class ForecastEngine {
  const ForecastEngine._();

  static List<CashForecastPoint> project({
    required DateTime from,
    required int startingBalanceMinor,
    required int monthlyIncomeMinor,
    required int monthlyExpenseMinor,
    required int monthlyBillsMinor,
    int months = 6,
  }) {
    final net = monthlyIncomeMinor - monthlyExpenseMinor - monthlyBillsMinor;
    return List.generate(months, (index) {
      return CashForecastPoint(
        month: DateTime(from.year, from.month + index + 1),
        balanceMinor: startingBalanceMinor + net * (index + 1),
      );
    });
  }
}
