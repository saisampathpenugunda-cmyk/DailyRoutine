import '../models/money_category.dart';
import '../models/money_transaction.dart';
import '../models/recurring_money_transaction.dart';
import '../repositories/money_repository.dart';

/// Service responsible for evaluating recurring transaction rules,
/// generating due [MoneyTransaction] records, and updating occurrence schedules.
class RecurringTransactionService {
  /// Computes the next occurrence date strictly after [currentOccurrence] based on
  /// [frequency] and the anchor [startDate].
  ///
  /// Correctly clamps monthly recurrences to the last valid day of each target month
  /// (e.g. Jan 31 -> Feb 28/29, Mar 31 -> Apr 30).
  ///
  /// All computations use pure local calendar dates (`00:00:00`) without UTC shifts.
  static DateTime computeNextOccurrence({
    required DateTime currentOccurrence,
    required RecurrenceFrequency frequency,
    required DateTime startDate,
  }) {
    final curr = DateTime(
      currentOccurrence.year,
      currentOccurrence.month,
      currentOccurrence.day,
    );
    final anchor = DateTime(startDate.year, startDate.month, startDate.day);

    switch (frequency) {
      case RecurrenceFrequency.daily:
        return DateTime(curr.year, curr.month, curr.day + 1);

      case RecurrenceFrequency.weekly:
        return DateTime(curr.year, curr.month, curr.day + 7);

      case RecurrenceFrequency.monthly:
        int nextYear = curr.year;
        int nextMonth = curr.month + 1;
        if (nextMonth > 12) {
          nextYear++;
          nextMonth = 1;
        }
        // DateTime(nextYear, nextMonth + 1, 0).day gives the total days in nextMonth
        final daysInNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
        final targetDay =
            anchor.day <= daysInNextMonth ? anchor.day : daysInNextMonth;
        return DateTime(nextYear, nextMonth, targetDay);
    }
  }

  /// Generates a deterministic transaction ID for an occurrence of a recurring rule.
  /// Format: `rec_${ruleId}_${yyyyMMdd}`
  static String deterministicTransactionId(
    String ruleId,
    DateTime occurrenceDate,
  ) {
    final y = occurrenceDate.year.toString().padLeft(4, '0');
    final m = occurrenceDate.month.toString().padLeft(2, '0');
    final d = occurrenceDate.day.toString().padLeft(2, '0');
    return 'rec_${ruleId}_$y$m$d';
  }

  /// Evaluates all active recurring transaction rules in [repository] and generates
  /// any due [MoneyTransaction] records up to [now] (defaults to local today).
  ///
  /// Advances [RecurringMoneyTransaction.nextOccurrence] and persists changes
  /// in [repository].
  ///
  /// Guarantees duplicate safety through deterministic ID validation.
  static Future<List<MoneyTransaction>> generateDueTransactions(
    MoneyRepository repository, {
    DateTime? now,
  }) async {
    final effectiveNow = now ?? DateTime.now();
    final today = DateTime(
      effectiveNow.year,
      effectiveNow.month,
      effectiveNow.day,
    );

    final rules = await repository.getRecurringTransactions();
    final categories = await repository.getCategories();
    final List<MoneyTransaction> generatedTransactions = [];

    for (final rule in rules) {
      if (!rule.isActive) {
        continue;
      }

      DateTime curNext = DateTime(
        rule.nextOccurrence.year,
        rule.nextOccurrence.month,
        rule.nextOccurrence.day,
      );

      final normalizedEndDate = rule.endDate != null
          ? DateTime(rule.endDate!.year, rule.endDate!.month, rule.endDate!.day)
          : null;

      bool modified = false;

      while (!curNext.isAfter(today)) {
        // If an end date exists, do not generate beyond it
        if (normalizedEndDate != null && curNext.isAfter(normalizedEndDate)) {
          break;
        }

        final txId = deterministicTransactionId(rule.id, curNext);

        // Check if an occurrence for this date was already generated
        final existing = await repository.getTransactionById(txId);
        if (existing == null) {
          final cat = categories.firstWhere(
            (c) =>
                c.id == rule.categoryId ||
                c.name.trim().toLowerCase() == rule.categoryId.trim().toLowerCase(),
            orElse: () => MoneyCategory(
              id: rule.categoryId,
              name: rule.categoryId,
              type: rule.type,
            ),
          );

          final newTx = MoneyTransaction(
            id: txId,
            type: rule.type,
            amount: rule.amount,
            category: cat.name,
            date: curNext,
            note: rule.note,
            createdAt: effectiveNow,
          );

          await repository.addTransaction(newTx);
          generatedTransactions.add(newTx);
        }

        // Advance to next cycle
        curNext = computeNextOccurrence(
          currentOccurrence: curNext,
          frequency: rule.frequency,
          startDate: rule.startDate,
        );
        modified = true;
      }

      if (modified) {
        final updatedRule = rule.copyWith(
          nextOccurrence: curNext,
          updatedAt: effectiveNow,
        );
        await repository.updateRecurring(updatedRule);
      }
    }

    return generatedTransactions;
  }
}
