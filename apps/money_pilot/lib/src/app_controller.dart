// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_pilot/src/auth.dart';
import 'package:money_pilot/src/coach_engine.dart';
import 'package:money_pilot/src/finance_engine.dart';
import 'package:money_pilot/src/forecast_engine.dart';
import 'package:money_pilot/src/initial_data.dart';
import 'package:money_pilot/src/local_repository.dart';
import 'package:money_pilot/src/models.dart';
import 'package:money_pilot/src/recurring_engine.dart';
import 'package:money_pilot/src/transaction_csv.dart';

final localRepositoryProvider = Provider<LocalRepository>((ref) {
  final userId = ref.watch(
    authControllerProvider.select((auth) => auth.currentUser?.id),
  );
  return LocalRepository(userId: userId ?? 'signed-out');
});
final syncGatewayProvider = Provider<DioSyncGateway>((ref) => DioSyncGateway());
final appControllerProvider = StateNotifierProvider<AppController, AppData>((
  ref,
) {
  return AppController(
    repository: ref.watch(localRepositoryProvider),
    syncGateway: ref.watch(syncGatewayProvider),
    hydrate: ref.watch(
      authControllerProvider.select((auth) => auth.currentUser != null),
    ),
  );
});

class AppController extends StateNotifier<AppData> {
  AppController({
    required LocalRepository repository,
    required DioSyncGateway syncGateway,
    AppData? initialData,
    bool hydrate = true,
  }) : _repository = repository,
       _syncGateway = syncGateway,
       super(initialData ?? buildEmptyData()) {
    if (initialData == null && hydrate) unawaited(_hydrate());
  }

  final LocalRepository _repository;
  final DioSyncGateway _syncGateway;
  final LocalCoachEngine _coach = const LocalCoachEngine();
  final TransactionCsvCodec _csv = const TransactionCsvCodec();
  bool _coachBusy = false;
  int _sequence = 0;

  String _newId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}-${_sequence++}';

  Future<void> _hydrate() async {
    final saved = await _repository.load();
    if (saved != null) {
      state = saved;
    } else {
      await _repository.save(state);
    }
  }

  void _commit(AppData next) {
    state = next.copyWith(syncStatus: 'Local changes saved');
    unawaited(_repository.save(state));
  }

  int get netWorthMinor =>
      state.accounts.fold(0, (total, account) => total + account.balanceMinor);

  List<RecurringTransactionInsight> get recurringInsights =>
      RecurringEngine.detect(state.transactions);

  String exportTransactionsCsv() => _csv.encode(
    state.transactions,
    accounts: state.accounts,
    categories: state.categories,
  );

  CsvImportResult importTransactionsCsv(String input) {
    final result = _csv.decode(
      input,
      accounts: state.accounts,
      categories: state.categories,
      newId: () => _newId('tx'),
    );
    if (result.transactions.isEmpty) return result;
    final fingerprints = state.transactions
        .map(_transactionFingerprint)
        .toSet();
    final unique = result.transactions
        .where((item) => fingerprints.add(_transactionFingerprint(item)))
        .toList();
    if (unique.isEmpty) {
      return CsvImportResult(transactions: const [], issues: result.issues);
    }
    var accounts = [...state.accounts];
    for (final item in unique) {
      accounts = _applyBalanceDelta(accounts, item.accountId, item.amountMinor);
    }
    final transactions = [...state.transactions, ...unique]
      ..sort((a, b) => b.date.compareTo(a.date));
    _commit(state.copyWith(accounts: accounts, transactions: transactions));
    return CsvImportResult(transactions: unique, issues: result.issues);
  }

  String _transactionFingerprint(FinanceTransaction item) =>
      '${item.date.toIso8601String().split('T').first}|${item.title.trim().toLowerCase()}|${item.amountMinor}|${item.accountId}|${item.categoryId}';

  Iterable<FinanceTransaction> get currentMonthTransactions {
    final now = DateTime.now();
    return state.transactions.where(
      (item) => item.date.year == now.year && item.date.month == now.month,
    );
  }

  int get monthlyIncomeMinor => currentMonthTransactions
      .where((item) => item.amountMinor > 0)
      .fold(0, (total, item) => total + item.amountMinor);

  int get monthlyExpenseMinor => currentMonthTransactions
      .where((item) => item.amountMinor < 0)
      .fold(0, (total, item) => total + item.amountMinor.abs());

  int get savingsRateBasisPoints => FinanceEngine.savingsRateBasisPoints(
    incomeMinor: monthlyIncomeMinor,
    expenseMinor: monthlyExpenseMinor,
  );

  Map<String, int> get spendingByCategory {
    final result = <String, int>{};
    for (final transaction in currentMonthTransactions) {
      if (transaction.amountMinor < 0) {
        result.update(
          transaction.categoryId,
          (value) => value + transaction.amountMinor.abs(),
          ifAbsent: transaction.amountMinor.abs,
        );
      }
    }
    return result;
  }

  List<CashForecastPoint> get sixMonthForecast {
    final liquid = state.accounts
        .where((account) => !account.isCredit)
        .fold(0, (total, account) => total + account.balanceMinor);
    final recurringBills = state.bills
        .where((bill) => !bill.isPaid)
        .fold(0, (total, bill) => total + bill.amountMinor);
    return ForecastEngine.project(
      from: DateTime.now(),
      startingBalanceMinor: liquid,
      monthlyIncomeMinor: monthlyIncomeMinor,
      monthlyExpenseMinor: monthlyExpenseMinor,
      monthlyBillsMinor: recurringBills,
    );
  }

  int spentForCategory(String categoryId) => currentMonthTransactions
      .where((item) => item.categoryId == categoryId && item.amountMinor < 0)
      .fold(0, (total, item) => total + item.amountMinor.abs());

  BudgetStatus statusForBudget(Budget budget) => FinanceEngine.budgetStatus(
    plannedMinor: budget.plannedMinor,
    spentMinor: spentForCategory(budget.categoryId),
  );

  SafeToSpendInput get safeToSpendInput {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final horizon = today.add(const Duration(days: 30));
    final available = state.accounts
        .where((account) => account.includedInSafeToSpend && !account.isCredit)
        .fold(0, (total, account) => total + account.balanceMinor);
    // Local account balances are available balances and already include pending
    // authorizations, so passing them again would count the outflow twice.
    const pending = 0;
    final bills = state.bills
        .where((bill) {
          final due = DateTime(
            bill.dueDate.year,
            bill.dueDate.month,
            bill.dueDate.day,
          );
          // Overdue bills, bills due today, and upcoming bills stay protected.
          return !bill.isPaid && !due.isAfter(horizon);
        })
        .fold(0, (total, bill) => total + bill.amountMinor);
    final credit = state.accounts
        .where((account) => account.isCredit && account.balanceMinor < 0)
        .fold(0, (total, account) => total + account.balanceMinor.abs());
    final emergency = state.goals
        .where((goal) => goal.name.toLowerCase().contains('emergency'))
        .fold(0, (total, goal) => total + goal.savedMinor);
    final currentBudgets = state.budgets
        .where(
          (budget) =>
              budget.month.year == now.year && budget.month.month == now.month,
        )
        .toList();
    final currentBudgetRemaining = currentBudgets.fold<int>(
      0,
      (total, budget) =>
          total +
          statusForBudget(budget).remainingMinor.clamp(0, 1 << 62).toInt(),
    );
    final int? budgetRemaining = currentBudgets.isEmpty
        ? null
        : currentBudgetRemaining;
    return SafeToSpendInput(
      availableMinor: available,
      confirmedIncomeMinor: 0,
      pendingOutgoingMinor: pending,
      requiredBillsMinor: bills,
      minimumDebtMinor: 0,
      plannedSavingsMinor: 0,
      goalContributionsMinor: 0,
      emergencyReserveMinor: emergency,
      creditObligationsMinor: credit,
      safetyBufferMinor: state.settings.safetyBufferMinor,
      knownRequiredMinor: 0,
      budgetRemainingMinor: budgetRemaining,
    );
  }

  int get safeToSpendMinor => FinanceEngine.safeToSpend(safeToSpendInput);

  void completeOnboarding() =>
      _commit(state.copyWith(onboardingComplete: true));

  void saveAccount(MoneyAccount account) {
    final accounts = [...state.accounts];
    final index = accounts.indexWhere((item) => item.id == account.id);
    if (index == -1) {
      accounts.add(
        MoneyAccount(
          id: account.id.isEmpty ? _newId('account') : account.id,
          name: account.name,
          type: account.type,
          balanceMinor: account.balanceMinor,
          colorValue: account.colorValue,
          includedInSafeToSpend: account.includedInSafeToSpend,
        ),
      );
    } else {
      accounts[index] = account;
    }
    _commit(state.copyWith(accounts: accounts));
  }

  void deleteAccount(String id) {
    if (state.accounts.length <= 1) return;
    _commit(
      state.copyWith(
        accounts: state.accounts.where((item) => item.id != id).toList(),
        transactions: state.transactions
            .where((item) => item.accountId != id)
            .toList(),
      ),
    );
  }

  List<MoneyAccount> _applyBalanceDelta(
    List<MoneyAccount> accounts,
    String accountId,
    int delta,
  ) => accounts
      .map(
        (account) => account.id == accountId
            ? account.copyWith(balanceMinor: account.balanceMinor + delta)
            : account,
      )
      .toList();

  void saveTransaction(FinanceTransaction transaction) {
    final accountExists = state.accounts.any(
      (account) => account.id == transaction.accountId,
    );
    final categoryExists = state.categories.any(
      (category) => category.id == transaction.categoryId,
    );
    if (!accountExists || !categoryExists || transaction.amountMinor == 0) {
      return;
    }
    final transactions = [...state.transactions];
    var accounts = [...state.accounts];
    final index = transactions.indexWhere((item) => item.id == transaction.id);
    if (index == -1) {
      final created = FinanceTransaction(
        id: transaction.id.isEmpty ? _newId('tx') : transaction.id,
        accountId: transaction.accountId,
        categoryId: transaction.categoryId,
        title: transaction.title,
        note: transaction.note,
        amountMinor: transaction.amountMinor,
        date: transaction.date,
        isPending: transaction.isPending,
      );
      transactions.insert(0, created);
      accounts = _applyBalanceDelta(
        accounts,
        created.accountId,
        created.amountMinor,
      );
    } else {
      final previous = transactions[index];
      accounts = _applyBalanceDelta(
        accounts,
        previous.accountId,
        -previous.amountMinor,
      );
      accounts = _applyBalanceDelta(
        accounts,
        transaction.accountId,
        transaction.amountMinor,
      );
      transactions[index] = transaction;
    }
    transactions.sort((a, b) => b.date.compareTo(a.date));
    _commit(state.copyWith(accounts: accounts, transactions: transactions));
  }

  void deleteTransaction(String id) {
    final existing = state.transactions
        .where((item) => item.id == id)
        .firstOrNull;
    if (existing == null) return;
    final accounts = _applyBalanceDelta(
      state.accounts,
      existing.accountId,
      -existing.amountMinor,
    );
    _commit(
      state.copyWith(
        accounts: accounts,
        transactions: state.transactions
            .where((item) => item.id != id)
            .toList(),
      ),
    );
  }

  void saveCategory(SpendingCategory category) {
    final categories = [...state.categories];
    final index = categories.indexWhere((item) => item.id == category.id);
    if (index == -1) {
      categories.add(
        SpendingCategory(
          id: category.id.isEmpty ? _newId('category') : category.id,
          name: category.name,
          iconCode: category.iconCode,
          colorValue: category.colorValue,
        ),
      );
    } else {
      categories[index] = category;
    }
    _commit(state.copyWith(categories: categories));
  }

  bool canDeleteCategory(String id) =>
      !state.transactions.any((item) => item.categoryId == id) &&
      !state.budgets.any((item) => item.categoryId == id);

  void deleteCategory(String id) {
    if (!canDeleteCategory(id)) return;
    _commit(
      state.copyWith(
        categories: state.categories.where((item) => item.id != id).toList(),
      ),
    );
  }

  void saveBudget(Budget budget) {
    if (budget.plannedMinor <= 0 ||
        !state.categories.any((item) => item.id == budget.categoryId)) {
      return;
    }
    final budgets = [...state.budgets];
    final index = budgets.indexWhere((item) => item.id == budget.id);
    final value = budget.id.isEmpty
        ? Budget(
            id: _newId('budget'),
            categoryId: budget.categoryId,
            plannedMinor: budget.plannedMinor,
            month: budget.month,
          )
        : budget;
    if (index == -1) {
      budgets.add(value);
    } else {
      budgets[index] = value;
    }
    _commit(state.copyWith(budgets: budgets));
  }

  void deleteBudget(String id) => _commit(
    state.copyWith(
      budgets: state.budgets.where((item) => item.id != id).toList(),
    ),
  );

  void saveBill(Bill bill) {
    final bills = [...state.bills];
    final index = bills.indexWhere((item) => item.id == bill.id);
    final value = bill.id.isEmpty
        ? Bill(
            id: _newId('bill'),
            name: bill.name,
            amountMinor: bill.amountMinor,
            dueDate: bill.dueDate,
            isPaid: bill.isPaid,
            autopay: bill.autopay,
          )
        : bill;
    if (index == -1) {
      bills.add(value);
    } else {
      bills[index] = value;
    }
    bills.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    _commit(state.copyWith(bills: bills));
  }

  void toggleBillPaid(Bill bill) =>
      saveBill(bill.copyWith(isPaid: !bill.isPaid));

  void deleteBill(String id) => _commit(
    state.copyWith(bills: state.bills.where((item) => item.id != id).toList()),
  );

  void saveGoal(SavingsGoal goal) {
    final goals = [...state.goals];
    final index = goals.indexWhere((item) => item.id == goal.id);
    final value = goal.id.isEmpty
        ? SavingsGoal(
            id: _newId('goal'),
            name: goal.name,
            targetMinor: goal.targetMinor,
            savedMinor: goal.savedMinor,
            targetDate: goal.targetDate,
          )
        : goal;
    if (index == -1) {
      goals.add(value);
    } else {
      goals[index] = value;
    }
    _commit(state.copyWith(goals: goals));
  }

  void contributeToGoal(String id, int amountMinor) {
    final goals = state.goals
        .map(
          (goal) => goal.id == id
              ? goal.copyWith(
                  savedMinor: (goal.savedMinor + amountMinor)
                      .clamp(0, goal.targetMinor)
                      .toInt(),
                )
              : goal,
        )
        .toList();
    _commit(state.copyWith(goals: goals));
  }

  void deleteGoal(String id) => _commit(
    state.copyWith(goals: state.goals.where((item) => item.id != id).toList()),
  );

  void updateSettings(AppSettings settings) =>
      _commit(state.copyWith(settings: settings));

  Future<void> syncNow() async {
    state = state.copyWith(syncStatus: 'Checking API connection…');
    final result = await _syncGateway.sync(state);
    state = state.copyWith(syncStatus: result);
    await _repository.save(state);
  }

  Future<String> connectApi({
    required String baseUrl,
    required String email,
    required String password,
  }) async {
    final settings = state.settings.copyWith(apiBaseUrl: baseUrl.trim());
    state = state.copyWith(
      settings: settings,
      syncStatus: 'Signing in to API…',
    );
    final result = await _syncGateway.connect(
      baseUrl: settings.apiBaseUrl,
      email: email,
      password: password,
    );
    state = state.copyWith(syncStatus: result);
    await _repository.save(state);
    return result;
  }

  void disconnectApi() {
    _syncGateway.disconnect();
    _commit(state.copyWith(syncStatus: 'API session disconnected'));
  }

  Future<void> askCoach(String prompt) async {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty || _coachBusy) return;
    _coachBusy = true;
    _commit(
      state.copyWith(
        messages: [
          ...state.messages,
          CoachMessage(
            id: _newId('message'),
            role: 'user',
            text: trimmed,
            createdAt: DateTime.now(),
          ),
        ],
        coachThinking: true,
        clearPendingCoachAction: true,
      ),
    );
    try {
      final reply = await _coach.reply(
        prompt: trimmed,
        data: state,
        safeToSpendMinor: safeToSpendMinor,
        monthlyIncomeMinor: monthlyIncomeMinor,
        monthlyExpenseMinor: monthlyExpenseMinor,
        netWorthMinor: netWorthMinor,
        savingsRateBasisPoints: savingsRateBasisPoints,
        newId: _newId,
      );
      _commit(
        state.copyWith(
          messages: [
            ...state.messages,
            CoachMessage(
              id: _newId('message'),
              role: 'assistant',
              text: reply.text,
              createdAt: DateTime.now(),
            ),
          ],
          pendingCoachAction: reply.action,
          clearPendingCoachAction: reply.action == null,
          coachThinking: false,
        ),
      );
    } catch (_) {
      final errorMessage = switch (state.settings.languageCode) {
        'fr' =>
          'Je n’ai pas pu terminer cette analyse. Vos données financières enregistrées sont inchangées ; reformulez la question puis réessayez.',
        'ar' =>
          'تعذر إكمال هذا التحليل. لم تتغير بياناتك المالية المحفوظة؛ أعد صياغة السؤال ثم حاول مجدداً.',
        _ =>
          'I could not complete that analysis. Your saved financial data is unchanged; please try rephrasing the question.',
      };
      _commit(
        state.copyWith(
          messages: [
            ...state.messages,
            CoachMessage(
              id: _newId('message'),
              role: 'assistant',
              text: errorMessage,
              createdAt: DateTime.now(),
            ),
          ],
          coachThinking: false,
          clearPendingCoachAction: true,
        ),
      );
    } finally {
      _coachBusy = false;
    }
  }

  void clearCoachConversation() => _commit(
    state.copyWith(
      messages: const [],
      clearPendingCoachAction: true,
      coachThinking: false,
    ),
  );

  void approveCoachAction(String id) {
    final action = state.pendingCoachAction;
    if (action == null || action.id != id) return;
    if (action.kind == 'upsert_budget') {
      final categoryId = action.payload['categoryId'] as String;
      final plannedMinor = action.payload['plannedMinor'] as int;
      final existing = state.budgets
          .where((budget) => budget.categoryId == categoryId)
          .firstOrNull;
      saveBudget(
        Budget(
          id: existing?.id ?? '',
          categoryId: categoryId,
          plannedMinor: plannedMinor,
          month: DateTime(DateTime.now().year, DateTime.now().month),
        ),
      );
    }
    final message = CoachMessage(
      id: _newId('message'),
      role: 'assistant',
      text: 'Approved and applied. You can review or edit it from Budgets.',
      createdAt: DateTime.now(),
    );
    _commit(
      state.copyWith(
        messages: [...state.messages, message],
        clearPendingCoachAction: true,
      ),
    );
  }

  void rejectCoachAction(String id) {
    if (state.pendingCoachAction?.id != id) return;
    _commit(state.copyWith(clearPendingCoachAction: true));
  }

  Future<void> clearAllData() async {
    final reset = buildEmptyData(
      onboardingComplete: true,
    ).copyWith(categories: state.categories, settings: state.settings);
    state = reset;
    await _repository.clear();
    await _repository.save(reset);
  }

  Future<void> resetDemo() => clearAllData();
}
