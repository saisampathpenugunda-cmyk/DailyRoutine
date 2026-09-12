import 'package:flutter_test/flutter_test.dart';
import 'package:daily_routine/money/models/recurring_money_transaction.dart';
import 'package:daily_routine/money/models/transaction_type.dart';
import 'package:daily_routine/money/repositories/in_memory_money_repository.dart';
import 'package:daily_routine/money/services/recurring_transaction_service.dart';

void main() {
  group('RecurringTransactionService - Frequency Math', () {
    test('daily frequency advances exactly one calendar day', () {
      final start = DateTime(2026, 9, 1);
      final next = RecurringTransactionService.computeNextOccurrence(
        currentOccurrence: start,
        frequency: RecurrenceFrequency.daily,
        startDate: start,
      );
      expect(next, DateTime(2026, 9, 2));
    });

    test('daily frequency safely crosses month and year boundaries', () {
      // Month boundary
      final sep30 = DateTime(2026, 9, 30);
      final oct1 = RecurringTransactionService.computeNextOccurrence(
        currentOccurrence: sep30,
        frequency: RecurrenceFrequency.daily,
        startDate: sep30,
      );
      expect(oct1, DateTime(2026, 10, 1));

      // Year boundary
      final dec31 = DateTime(2026, 12, 31);
      final jan1 = RecurringTransactionService.computeNextOccurrence(
        currentOccurrence: dec31,
        frequency: RecurrenceFrequency.daily,
        startDate: dec31,
      );
      expect(jan1, DateTime(2027, 1, 1));
    });

    test('weekly frequency advances exactly seven calendar days', () {
      final start = DateTime(2026, 9, 1);
      final next = RecurringTransactionService.computeNextOccurrence(
        currentOccurrence: start,
        frequency: RecurrenceFrequency.weekly,
        startDate: start,
      );
      expect(next, DateTime(2026, 9, 8));
    });

    test('monthly frequency advances month cleanly for mid-month dates', () {
      final start = DateTime(2026, 9, 15);
      final next = RecurringTransactionService.computeNextOccurrence(
        currentOccurrence: start,
        frequency: RecurrenceFrequency.monthly,
        startDate: start,
      );
      expect(next, DateTime(2026, 10, 15));
    });

    test('monthly frequency safely rolls over December to January', () {
      final start = DateTime(2026, 12, 10);
      final next = RecurringTransactionService.computeNextOccurrence(
        currentOccurrence: start,
        frequency: RecurrenceFrequency.monthly,
        startDate: start,
      );
      expect(next, DateTime(2027, 1, 10));
    });

    test('monthly frequency clamps January 31 to February 28 in non-leap year (2026) and rebounds to March 31', () {
      final start = DateTime(2026, 1, 31);

      // Jan 31 -> Feb 28
      final feb = RecurringTransactionService.computeNextOccurrence(
        currentOccurrence: start,
        frequency: RecurrenceFrequency.monthly,
        startDate: start,
      );
      expect(feb, DateTime(2026, 2, 28));

      // Feb 28 -> March 31 (anchor day 31 is restored!)
      final mar = RecurringTransactionService.computeNextOccurrence(
        currentOccurrence: feb,
        frequency: RecurrenceFrequency.monthly,
        startDate: start,
      );
      expect(mar, DateTime(2026, 3, 31));

      // March 31 -> April 30
      final apr = RecurringTransactionService.computeNextOccurrence(
        currentOccurrence: mar,
        frequency: RecurrenceFrequency.monthly,
        startDate: start,
      );
      expect(apr, DateTime(2026, 4, 30));

      // April 30 -> May 31
      final may = RecurringTransactionService.computeNextOccurrence(
        currentOccurrence: apr,
        frequency: RecurrenceFrequency.monthly,
        startDate: start,
      );
      expect(may, DateTime(2026, 5, 31));
    });

    test('monthly frequency clamps January 31 to February 29 in leap year (2028)', () {
      final start = DateTime(2028, 1, 31);
      final feb = RecurringTransactionService.computeNextOccurrence(
        currentOccurrence: start,
        frequency: RecurrenceFrequency.monthly,
        startDate: start,
      );
      expect(feb, DateTime(2028, 2, 29));
    });

    test('deterministic transaction ID matches pattern', () {
      final id = RecurringTransactionService.deterministicTransactionId(
        'test-rule-123',
        DateTime(2026, 9, 5),
      );
      expect(id, 'rec_test-rule-123_20260905');
    });
  });

  group('RecurringTransactionService - Transaction Generation Engine', () {
    late InMemoryMoneyRepository repo;

    setUp(() {
      repo = InMemoryMoneyRepository();
    });

    test('does not generate transaction if first occurrence is in the future', () async {
      final rule = RecurringMoneyTransaction(
        id: 'rule-future',
        type: TransactionType.expense,
        amount: 500.0,
        categoryId: 'food',
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2026, 9, 20),
        nextOccurrence: DateTime(2026, 9, 20),
      );
      await repo.addRecurring(rule);

      // System date is September 12 (before September 20)
      final generated = await RecurringTransactionService.generateDueTransactions(
        repo,
        now: DateTime(2026, 9, 12),
      );

      expect(generated, isEmpty);
      final allTxs = await repo.getTransactions();
      expect(allTxs, isEmpty);

      // Next occurrence remains unchanged
      final updatedRule = await repo.getRecurringById('rule-future');
      expect(updatedRule!.nextOccurrence, DateTime(2026, 9, 20));
    });

    test('generates transaction when occurrence date is due today and advances nextOccurrence', () async {
      final rule = RecurringMoneyTransaction(
        id: 'rule-due-today',
        type: TransactionType.income,
        amount: 50000.0,
        categoryId: 'salary',
        note: 'Monthly job salary',
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2026, 9, 1),
        nextOccurrence: DateTime(2026, 9, 1),
      );
      await repo.addRecurring(rule);

      // Run engine on September 1
      final generated = await RecurringTransactionService.generateDueTransactions(
        repo,
        now: DateTime(2026, 9, 1),
      );

      expect(generated.length, 1);
      expect(generated.first.id, 'rec_rule-due-today_20260901');
      expect(generated.first.amount, 50000.0);
      expect(generated.first.type, TransactionType.income);
      expect(generated.first.category, 'Salary');
      expect(generated.first.note, 'Monthly job salary');
      expect(generated.first.date, DateTime(2026, 9, 1));

      // Rule nextOccurrence should now be October 1
      final updatedRule = await repo.getRecurringById('rule-due-today');
      expect(updatedRule!.nextOccurrence, DateTime(2026, 10, 1));
    });

    test('duplicate safety: running generator multiple times on same day creates exactly 1 transaction', () async {
      final rule = RecurringMoneyTransaction(
        id: 'rule-dup-safe',
        type: TransactionType.expense,
        amount: 100.0,
        categoryId: 'transport',
        frequency: RecurrenceFrequency.daily,
        startDate: DateTime(2026, 9, 1),
        nextOccurrence: DateTime(2026, 9, 1),
      );
      await repo.addRecurring(rule);

      // App opened 1st time
      final gen1 = await RecurringTransactionService.generateDueTransactions(
        repo,
        now: DateTime(2026, 9, 1, 9, 0),
      );
      expect(gen1.length, 1);

      // App opened 2nd time on same day
      final gen2 = await RecurringTransactionService.generateDueTransactions(
        repo,
        now: DateTime(2026, 9, 1, 14, 0),
      );
      expect(gen2, isEmpty);

      // App opened 3rd time
      final gen3 = await RecurringTransactionService.generateDueTransactions(
        repo,
        now: DateTime(2026, 9, 1, 23, 59),
      );
      expect(gen3, isEmpty);

      final allTxs = await repo.getTransactions();
      expect(allTxs.length, 1);
      expect(allTxs.first.id, 'rec_rule-dup-safe_20260901');
    });

    test('generates all missed occurrences in sequential order when app was not opened for several days', () async {
      final rule = RecurringMoneyTransaction(
        id: 'rule-missed-days',
        type: TransactionType.expense,
        amount: 100.0,
        categoryId: 'food',
        frequency: RecurrenceFrequency.daily,
        startDate: DateTime(2026, 9, 1),
        nextOccurrence: DateTime(2026, 9, 1),
      );
      await repo.addRecurring(rule);

      // App opened on September 5
      final generated = await RecurringTransactionService.generateDueTransactions(
        repo,
        now: DateTime(2026, 9, 5),
      );

      // Missed: Sep 1, Sep 2, Sep 3, Sep 4, Sep 5 -> 5 occurrences!
      expect(generated.length, 5);
      expect(generated[0].date, DateTime(2026, 9, 1));
      expect(generated[1].date, DateTime(2026, 9, 2));
      expect(generated[2].date, DateTime(2026, 9, 3));
      expect(generated[3].date, DateTime(2026, 9, 4));
      expect(generated[4].date, DateTime(2026, 9, 5));

      final allTxs = await repo.getTransactions();
      expect(allTxs.length, 5);

      final updatedRule = await repo.getRecurringById('rule-missed-days');
      expect(updatedRule!.nextOccurrence, DateTime(2026, 9, 6));
    });

    test('respects end date and never generates beyond it', () async {
      final rule = RecurringMoneyTransaction(
        id: 'rule-end-date',
        type: TransactionType.expense,
        amount: 200.0,
        categoryId: 'bills',
        frequency: RecurrenceFrequency.daily,
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 9, 3), // Ends on Sep 3
        nextOccurrence: DateTime(2026, 9, 1),
      );
      await repo.addRecurring(rule);

      // App opened on September 10 (well past end date)
      final generated = await RecurringTransactionService.generateDueTransactions(
        repo,
        now: DateTime(2026, 9, 10),
      );

      // Must only generate Sep 1, 2, 3 (3 occurrences)
      expect(generated.length, 3);
      expect(generated.map((t) => t.date), [
        DateTime(2026, 9, 1),
        DateTime(2026, 9, 2),
        DateTime(2026, 9, 3),
      ]);

      // Running again does not generate any more
      final genAgain = await RecurringTransactionService.generateDueTransactions(
        repo,
        now: DateTime(2026, 9, 15),
      );
      expect(genAgain, isEmpty);
    });

    test('paused recurring rule does not generate transactions and retains nextOccurrence', () async {
      final rule = RecurringMoneyTransaction(
        id: 'rule-paused',
        type: TransactionType.expense,
        amount: 1500.0,
        categoryId: 'bills',
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2026, 9, 1),
        nextOccurrence: DateTime(2026, 9, 1),
        isActive: false, // Paused
      );
      await repo.addRecurring(rule);

      final generated = await RecurringTransactionService.generateDueTransactions(
        repo,
        now: DateTime(2026, 9, 1),
      );
      expect(generated, isEmpty);

      final checkRule = await repo.getRecurringById('rule-paused');
      expect(checkRule!.nextOccurrence, DateTime(2026, 9, 1));
      expect(checkRule.isActive, isFalse);
    });

    test('resuming recurring rule continues generation from retained nextOccurrence without duplicate generation', () async {
      final rule = RecurringMoneyTransaction(
        id: 'rule-resume',
        type: TransactionType.expense,
        amount: 1000.0,
        categoryId: 'food',
        frequency: RecurrenceFrequency.weekly,
        startDate: DateTime(2026, 9, 1),
        nextOccurrence: DateTime(2026, 9, 1),
        isActive: false, // Paused
      );
      await repo.addRecurring(rule);

      // Step 1: Paused -> no transactions generated on Sep 1
      await RecurringTransactionService.generateDueTransactions(
        repo,
        now: DateTime(2026, 9, 1),
      );
      expect(await repo.getTransactions(), isEmpty);

      // Step 2: User resumes on Sep 1
      final active = rule.copyWith(isActive: true);
      await repo.updateRecurring(active);

      // Step 3: Run generator -> Sep 1 is generated!
      final gen = await RecurringTransactionService.generateDueTransactions(
        repo,
        now: DateTime(2026, 9, 1),
      );
      expect(gen.length, 1);
      expect(gen.first.date, DateTime(2026, 9, 1));

      // Rule nextOccurrence is advanced to Sep 8
      final updated = await repo.getRecurringById('rule-resume');
      expect(updated!.nextOccurrence, DateTime(2026, 9, 8));
    });

    test('editing a recurring rule does not alter already generated transactions', () async {
      final rule = RecurringMoneyTransaction(
        id: 'rule-edit',
        type: TransactionType.income,
        amount: 50000.0,
        categoryId: 'salary',
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2026, 9, 1),
        nextOccurrence: DateTime(2026, 9, 1),
      );
      await repo.addRecurring(rule);

      // Generate September transaction
      await RecurringTransactionService.generateDueTransactions(
        repo,
        now: DateTime(2026, 9, 1),
      );

      final sepTx = (await repo.getTransactions()).first;
      expect(sepTx.amount, 50000.0);

      // Edit rule to 55000
      final updatedRule = (await repo.getRecurringById('rule-edit'))!.copyWith(
        amount: 55000.0,
      );
      await repo.updateRecurring(updatedRule);

      // Verify Sep transaction is STILL 50000!
      final sepTxAfterEdit = await repo.getTransactionById(sepTx.id);
      expect(sepTxAfterEdit!.amount, 50000.0);

      // Generate October transaction -> should use new amount 55000
      final octGen = await RecurringTransactionService.generateDueTransactions(
        repo,
        now: DateTime(2026, 10, 1),
      );
      expect(octGen.length, 1);
      expect(octGen.first.amount, 55000.0);
    });
  });
}
