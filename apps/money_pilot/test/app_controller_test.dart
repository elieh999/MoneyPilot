import 'package:flutter_test/flutter_test.dart';
import 'package:money_pilot/src/app_controller.dart';
import 'package:money_pilot/src/local_repository.dart';
import 'package:money_pilot/src/models.dart';

class _MemoryRepository extends LocalRepository {
  AppData? saved;

  @override
  Future<AppData?> load() async => saved;

  @override
  Future<void> save(AppData data) async {
    saved = data;
  }

  @override
  Future<void> clear() async {
    saved = null;
  }
}

AppData _data({
  required List<MoneyAccount> accounts,
  List<SpendingCategory> categories = const [],
  List<FinanceTransaction> transactions = const [],
  List<Budget> budgets = const [],
  List<Bill> bills = const [],
  List<SavingsGoal> goals = const [],
}) => AppData(
  accounts: accounts,
  categories: categories,
  transactions: transactions,
  budgets: budgets,
  bills: bills,
  goals: goals,
  messages: const [],
  settings: const AppSettings(),
  onboardingComplete: true,
);

AppController _controller(AppData data, _MemoryRepository repository) {
  final controller = AppController(
    repository: repository,
    syncGateway: DioSyncGateway(),
    initialData: data,
  );
  addTearDown(controller.dispose);
  return controller;
}

void main() {
  test(
    'transaction create, edit across accounts, and delete preserve balances',
    () async {
      final repository = _MemoryRepository();
      final controller = _controller(
        _data(
          accounts: const [
            MoneyAccount(
              id: 'cash',
              name: 'Cash',
              type: 'Cash',
              balanceMinor: 100000,
              colorValue: 0,
            ),
            MoneyAccount(
              id: 'card',
              name: 'Card',
              type: 'Credit card',
              balanceMinor: 50000,
              colorValue: 0,
            ),
          ],
          categories: const [
            SpendingCategory(
              id: 'food',
              name: 'Food',
              iconCode: 0,
              colorValue: 0,
            ),
          ],
        ),
        repository,
      );
      final now = DateTime.now();

      controller.saveTransaction(
        FinanceTransaction(
          id: 'tx-1',
          accountId: 'cash',
          categoryId: 'food',
          title: 'Lunch',
          amountMinor: -2500,
          date: now,
        ),
      );
      expect(controller.state.transactions, hasLength(1));
      expect(
        controller.state.accounts
            .singleWhere((item) => item.id == 'cash')
            .balanceMinor,
        97500,
      );
      expect(controller.netWorthMinor, 147500);

      controller.saveTransaction(
        FinanceTransaction(
          id: 'tx-1',
          accountId: 'card',
          categoryId: 'food',
          title: 'Lunch corrected',
          amountMinor: -3000,
          date: now,
        ),
      );
      expect(
        controller.state.accounts
            .singleWhere((item) => item.id == 'cash')
            .balanceMinor,
        100000,
      );
      expect(
        controller.state.accounts
            .singleWhere((item) => item.id == 'card')
            .balanceMinor,
        47000,
      );
      expect(controller.netWorthMinor, 147000);

      controller.deleteTransaction('tx-1');
      expect(controller.state.transactions, isEmpty);
      expect(
        controller.state.accounts
            .singleWhere((item) => item.id == 'card')
            .balanceMinor,
        50000,
      );
      expect(controller.netWorthMinor, 150000);

      await Future<void>.delayed(Duration.zero);
      expect(repository.saved?.transactions, isEmpty);
      expect(
        repository.saved?.accounts.fold<int>(
          0,
          (total, account) => total + account.balanceMinor,
        ),
        150000,
      );
    },
  );

  test(
    'available balance already reflects pending transaction exactly once',
    () {
      final controller = _controller(
        _data(
          accounts: const [
            MoneyAccount(
              id: 'checking',
              name: 'Checking',
              type: 'Checking',
              balanceMinor: 300000,
              colorValue: 0,
            ),
          ],
          categories: const [
            SpendingCategory(
              id: 'dining',
              name: 'Dining',
              iconCode: 0,
              colorValue: 0,
            ),
          ],
          transactions: [
            FinanceTransaction(
              id: 'pending',
              accountId: 'checking',
              categoryId: 'dining',
              title: 'Pending dinner',
              amountMinor: -10000,
              date: DateTime.now(),
              isPending: true,
            ),
          ],
          budgets: [
            Budget(
              id: 'dining-plan',
              categoryId: 'dining',
              plannedMinor: 500000,
              month: DateTime(DateTime.now().year, DateTime.now().month),
            ),
          ],
        ),
        _MemoryRepository(),
      );

      expect(controller.safeToSpendInput.pendingOutgoingMinor, 0);
      expect(controller.safeToSpendInput.budgetRemainingMinor, 490000);
      expect(controller.safeToSpendMinor, 300000);
    },
  );

  test(
    'AI proposal changes nothing until exact approval and supports rejection',
    () async {
      final originalBudget = Budget(
        id: 'dining-budget',
        categoryId: 'dining',
        plannedMinor: 10000,
        month: DateTime(DateTime.now().year, DateTime.now().month),
      );
      final controller = _controller(
        _data(
          accounts: const [
            MoneyAccount(
              id: 'checking',
              name: 'Checking',
              type: 'Checking',
              balanceMinor: 500000,
              colorValue: 0,
            ),
          ],
          categories: const [
            SpendingCategory(
              id: 'dining',
              name: 'Dining',
              iconCode: 0,
              colorValue: 0,
            ),
          ],
          budgets: [originalBudget],
        ),
        _MemoryRepository(),
      );

      await controller.askCoach('Set a 250 dining budget');
      final firstProposal = controller.state.pendingCoachAction;
      expect(firstProposal, isNotNull);
      expect(controller.state.budgets.single.plannedMinor, 10000);

      controller.approveCoachAction('not-the-proposal');
      expect(controller.state.pendingCoachAction?.id, firstProposal!.id);
      expect(controller.state.budgets.single.plannedMinor, 10000);

      controller.approveCoachAction(firstProposal.id);
      expect(controller.state.pendingCoachAction, isNull);
      expect(controller.state.budgets.single.plannedMinor, 25000);
      expect(
        controller.state.messages.last.text,
        contains('Approved and applied'),
      );

      await controller.askCoach('Set a 400 dining budget');
      final secondProposal = controller.state.pendingCoachAction;
      expect(secondProposal, isNotNull);
      controller.rejectCoachAction(secondProposal!.id);
      expect(controller.state.pendingCoachAction, isNull);
      expect(controller.state.budgets.single.plannedMinor, 25000);
    },
  );

  test('referenced categories cannot be deleted, unused categories can', () {
    final now = DateTime.now();
    final controller = _controller(
      _data(
        accounts: const [
          MoneyAccount(
            id: 'cash',
            name: 'Cash',
            type: 'Cash',
            balanceMinor: 10000,
            colorValue: 0,
          ),
        ],
        categories: const [
          SpendingCategory(
            id: 'used',
            name: 'Used',
            iconCode: 0,
            colorValue: 0,
          ),
          SpendingCategory(
            id: 'unused',
            name: 'Unused',
            iconCode: 0,
            colorValue: 0,
          ),
        ],
        transactions: [
          FinanceTransaction(
            id: 'tx',
            accountId: 'cash',
            categoryId: 'used',
            title: 'Existing',
            amountMinor: -100,
            date: now,
          ),
        ],
      ),
      _MemoryRepository(),
    );

    expect(controller.canDeleteCategory('used'), isFalse);
    controller.deleteCategory('used');
    expect(
      controller.state.categories.map((item) => item.id),
      contains('used'),
    );

    expect(controller.canDeleteCategory('unused'), isTrue);
    controller.deleteCategory('unused');
    expect(
      controller.state.categories.map((item) => item.id),
      isNot(contains('unused')),
    );
  });
}
