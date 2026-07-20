import 'package:flutter_test/flutter_test.dart';
import 'package:money_pilot/src/coach_engine.dart';
import 'package:money_pilot/src/initial_data.dart';
import 'package:money_pilot/src/models.dart';

Future<CoachReply> _ask(String prompt, AppData data) {
  return const LocalCoachEngine().reply(
    prompt: prompt,
    data: data,
    safeToSpendMinor: data.accounts.fold(
      0,
      (total, account) => total + account.balanceMinor,
    ),
    monthlyIncomeMinor: 0,
    monthlyExpenseMinor: data.transactions
        .where((item) => item.amountMinor < 0)
        .fold(0, (total, item) => total + item.amountMinor.abs()),
    netWorthMinor: data.accounts.fold(
      0,
      (total, account) => total + account.balanceMinor,
    ),
    savingsRateBasisPoints: 0,
    newId: (prefix) => '$prefix-test',
  );
}

void main() {
  test(
    'coach is conversational and honest when the workspace is empty',
    () async {
      final greeting = await _ask('Hello', buildEmptyData());
      final purchase = await _ask(
        'Can I buy a laptop for 900?',
        buildEmptyData(),
      );

      expect(greeting.text, contains('workspace is empty'));
      expect(purchase.text, contains('there is no account balance'));
      expect(purchase.text, isNot(contains('you can afford')));
    },
  );

  test('coach answers from actual account and transaction data', () async {
    final now = DateTime.now();
    final data = buildEmptyData().copyWith(
      accounts: const [
        MoneyAccount(
          id: 'checking',
          name: 'Checking',
          type: 'Checking',
          balanceMinor: 200000,
          colorValue: 0,
        ),
      ],
      transactions: [
        FinanceTransaction(
          id: 'dinner',
          accountId: 'checking',
          categoryId: 'dining',
          title: 'Dinner',
          amountMinor: -4250,
          date: now,
        ),
      ],
    );

    final spending = await _ask('How much did I spend on dining?', data);
    final purchase = await _ask('Can I afford a 500 purchase?', data);

    expect(spending.text, contains(r'$42.50'));
    expect(purchase.text, contains(r'$500.00'));
    expect(purchase.text, contains(r'$2,000.00'));
  });

  test('coach drafts a typed action and never applies it itself', () async {
    final reply = await _ask('Set a 250 dining budget', buildEmptyData());

    expect(reply.action, isNotNull);
    expect(reply.action!.kind, 'upsert_budget');
    expect(reply.action!.payload['categoryId'], 'dining');
    expect(reply.action!.payload['plannedMinor'], 25000);
    expect(reply.text, contains('nothing changes unless you approve'));
  });

  test('coach replies in French when French is selected', () async {
    final data = buildEmptyData().copyWith(
      settings: const AppSettings(languageCode: 'fr'),
    );

    final greeting = await _ask('Bonjour', data);
    final purchase = await _ask('Puis-je acheter un ordinateur à 900 ?', data);

    expect(greeting.text, contains('Bonjour'));
    expect(purchase.text, contains('aucun solde'));
  });

  test('coach understands Arabic questions and Arabic numerals', () async {
    final data = buildEmptyData().copyWith(
      settings: const AppSettings(languageCode: 'ar'),
    );

    final greeting = await _ask('مرحبا', data);
    final purchase = await _ask('هل أستطيع شراء حاسوب بسعر ٩٠٠؟', data);

    expect(greeting.text, contains('مرحب'));
    expect(purchase.text, contains(r'$900.00'));
    expect(purchase.text, contains('لا يوجد رصيد'));
  });

  test(
    'coach handles the main financial intents in all three languages',
    () async {
      final now = DateTime.now();
      final base = buildEmptyData().copyWith(
        accounts: const [
          MoneyAccount(
            id: 'checking',
            name: 'Checking',
            type: 'Checking',
            balanceMinor: 350000,
            colorValue: 0,
          ),
        ],
        transactions: [
          FinanceTransaction(
            id: 'salary',
            accountId: 'checking',
            categoryId: 'salary',
            title: 'Salary',
            amountMinor: 250000,
            date: now,
          ),
          FinanceTransaction(
            id: 'dinner',
            accountId: 'checking',
            categoryId: 'dining',
            title: 'Dinner',
            amountMinor: -4500,
            date: now,
          ),
        ],
        bills: [
          Bill(
            id: 'internet',
            name: 'Internet',
            amountMinor: 6000,
            dueDate: now.add(const Duration(days: 5)),
          ),
        ],
        goals: [
          SavingsGoal(
            id: 'emergency',
            name: 'Emergency fund',
            targetMinor: 100000,
            savedMinor: 25000,
            targetDate: now.add(const Duration(days: 180)),
          ),
        ],
      );

      final prompts = <String, List<String>>{
        'en': [
          'What is safe to spend?',
          'How much did I spend on dining?',
          'What bills are coming up?',
          'How is my savings goal?',
          'Can I afford 500?',
          'Set a dining budget of 250',
        ],
        'fr': [
          'Quel montant est disponible ?',
          'Combien ai-je dépensé au restaurant ?',
          'Quelles factures arrivent à échéance ?',
          'Où en est mon objectif d’épargne ?',
          'Puis-je acheter quelque chose à 500 ?',
          'Budget restaurants 250',
        ],
        'ar': [
          'ما المبلغ الآمن للصرف؟',
          'كم أنفقت على المطاعم؟',
          'ما الفواتير القادمة؟',
          'كيف هو هدف الادخار؟',
          'هل أستطيع شراء شيء بسعر ٥٠٠؟',
          'ميزانية مطاعم ٢٥٠',
        ],
      };

      for (final entry in prompts.entries) {
        final data = base.copyWith(
          settings: AppSettings(languageCode: entry.key),
        );
        for (final prompt in entry.value) {
          final reply = await _ask(prompt, data);
          expect(reply.text.trim(), isNotEmpty, reason: '$entry: $prompt');
          expect(reply.text, isNot(contains('Exception')), reason: prompt);
          if (entry.key == 'fr') {
            expect(reply.text, isNot(contains('I cannot')), reason: prompt);
          }
          if (entry.key == 'ar') {
            expect(reply.text, isNot(contains('I can')), reason: prompt);
          }
        }
      }
    },
  );
}
