import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:money_pilot/src/finance_engine.dart';
import 'package:money_pilot/src/formatters.dart';

void main() {
  late Map<String, dynamic> contracts;

  setUpAll(() async {
    final file = File('../../packages/financial_contracts/vectors.json');
    expect(
      await file.exists(),
      isTrue,
      reason: 'Run Flutter tests from apps/money_pilot.',
    );
    contracts = Map<String, dynamic>.from(
      jsonDecode(await file.readAsString()) as Map,
    );
  });

  group('shared financial contract vectors', () {
    test('safe spending matches every shared runtime example', () {
      final vectors = contracts['safe_to_spend'] as List<dynamic>;
      for (final rawVector in vectors) {
        final vector = Map<String, dynamic>.from(rawVector as Map);
        final input = Map<String, dynamic>.from(vector['input'] as Map);
        final result = FinanceEngine.safeToSpend(
          SafeToSpendInput(
            availableMinor: input['available_minor'] as int,
            confirmedIncomeMinor: input['confirmed_income_minor'] as int,
            pendingOutgoingMinor: input['pending_outgoing_minor'] as int,
            requiredBillsMinor: input['required_bills_minor'] as int,
            minimumDebtMinor: input['minimum_debt_minor'] as int,
            plannedSavingsMinor: input['planned_savings_minor'] as int,
            goalContributionsMinor: input['goal_contributions_minor'] as int,
            emergencyReserveMinor: input['emergency_reserve_minor'] as int,
            creditObligationsMinor: input['credit_obligations_minor'] as int,
            safetyBufferMinor: input['safety_buffer_minor'] as int,
            knownRequiredMinor: input['known_required_minor'] as int,
            budgetRemainingMinor: input['budget_remaining_minor'] as int?,
          ),
        );

        expect(
          result,
          vector['expected_minor'],
          reason: vector['name'] as String,
        );
      }
    });

    test('savings rate matches every cross-runtime vector', () {
      final vectors = contracts['savings_rate'] as List<dynamic>;
      for (final rawVector in vectors) {
        final vector = Map<String, dynamic>.from(rawVector as Map);
        final input = Map<String, dynamic>.from(vector['input'] as Map);

        expect(
          FinanceEngine.savingsRateBasisPoints(
            incomeMinor: input['income_minor'] as int,
            expenseMinor: input['expense_minor'] as int,
          ),
          vector['expected_basis_points'],
          reason: vector['name'] as String,
        );
      }
    });

    test('budget status matches every cross-runtime vector', () {
      final vectors = contracts['budget_status'] as List<dynamic>;
      for (final rawVector in vectors) {
        final vector = Map<String, dynamic>.from(rawVector as Map);
        final input = Map<String, dynamic>.from(vector['input'] as Map);
        final expected = Map<String, dynamic>.from(vector['expected'] as Map);
        final result = FinanceEngine.budgetStatus(
          plannedMinor: input['planned_minor'] as int,
          spentMinor: input['spent_minor'] as int,
        );

        expect(
          result.remainingMinor,
          expected['remaining_minor'],
          reason: vector['name'] as String,
        );
        expect(
          result.usageBasisPoints,
          expected['usage_basis_points'],
          reason: vector['name'] as String,
        );
      }
    });
  });

  group('financial edge policy', () {
    test('half-basis-point ratios round away from zero', () {
      expect(
        FinanceEngine.savingsRateBasisPoints(incomeMinor: 32, expenseMinor: 31),
        313,
      );
    });

    test('zero plan is numeric zero plus a needs-review state', () {
      final status = FinanceEngine.budgetStatus(
        plannedMinor: 0,
        spentMinor: 1200,
      );

      expect(status.usageBasisPoints, 0);
      expect(status.remainingMinor, -1200);
      expect(status.needsReview, isTrue);
    });

    test('liquidity and budget ceilings are independently non-negative', () {
      const common = SafeToSpendInput(
        availableMinor: 100000,
        confirmedIncomeMinor: 0,
        pendingOutgoingMinor: 0,
        requiredBillsMinor: 10000,
        minimumDebtMinor: 0,
        plannedSavingsMinor: 0,
        goalContributionsMinor: 0,
        emergencyReserveMinor: 0,
        creditObligationsMinor: 0,
        safetyBufferMinor: 0,
        knownRequiredMinor: 0,
        budgetRemainingMinor: -1,
      );
      const shortfall = SafeToSpendInput(
        availableMinor: 1000,
        confirmedIncomeMinor: 0,
        pendingOutgoingMinor: 2000,
        requiredBillsMinor: 0,
        minimumDebtMinor: 0,
        plannedSavingsMinor: 0,
        goalContributionsMinor: 0,
        emergencyReserveMinor: 0,
        creditObligationsMinor: 0,
        safetyBufferMinor: 0,
        knownRequiredMinor: 0,
      );

      expect(FinanceEngine.safeToSpend(common), 0);
      expect(FinanceEngine.safeToSpend(shortfall), 0);
    });
  });

  group('exact money input and formatting', () {
    test(
      'parses zero, cents, and one-decimal input without floating point',
      () {
        expect(MoneyFormatter.parseInputToMinor('0'), isNull);
        expect(MoneyFormatter.parseInputToMinor('0', allowZero: true), 0);
        expect(MoneyFormatter.parseInputToMinor('0.01'), 1);
        expect(MoneyFormatter.parseInputToMinor('.01'), 1);
        expect(MoneyFormatter.parseInputToMinor('1.2'), 120);
        expect(MoneyFormatter.parseInputToMinor(r'$1,234.50'), 123450);
      },
    );

    test('negative input is accepted only when the caller allows it', () {
      expect(MoneyFormatter.parseInputToMinor('-12.34'), isNull);
      expect(
        MoneyFormatter.parseInputToMinor('-12.34', allowNegative: true),
        -1234,
      );
    });

    test('rejects malformed values and precision beyond minor units', () {
      for (final value in [
        '',
        'money',
        '.',
        '1.',
        '1.234',
        '1..2',
        '--1',
        '1e3',
        r'$$1.00',
      ]) {
        expect(
          MoneyFormatter.parseInputToMinor(value, allowZero: true),
          isNull,
          reason: value,
        );
      }
    });

    test('preserves exact digits through the signed 64-bit maximum', () {
      const maxInt64 = 9223372036854775807;

      expect(MoneyFormatter.input(maxInt64), '92233720368547758.07');
      expect(
        MoneyFormatter.parseInputToMinor('92233720368547758.07'),
        maxInt64,
      );
      expect(MoneyFormatter.amount(maxInt64), r'$92,233,720,368,547,758.07');
      expect(MoneyFormatter.parseInputToMinor('92233720368547758.08'), isNull);
    });
  });
}
