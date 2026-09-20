import 'package:shared_preferences/shared_preferences.dart';
import '../../services/notification_service.dart';
import '../repositories/money_repository.dart';
import 'money_calculator.dart';

/// Helper to synchronize daily savings reminder notification with the current savings total.
class SavingsNotificationHelper {
  static const String prefEnabledKey = 'money_savings_reminder_enabled';
  static const String prefHourKey = 'money_savings_reminder_hour';
  static const String prefMinuteKey = 'money_savings_reminder_minute';

  static const int defaultHour = 21; // 9:00 PM
  static const int defaultMinute = 0;

  /// Reschedules the savings reminder if enabled in user preferences.
  static Future<void> syncSavingsReminder({
    required MoneyRepository repository,
    required NotificationService? notificationService,
    DateTime? testNow,
  }) async {
    if (notificationService == null) return;

    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool(prefEnabledKey) ?? true;

    if (!isEnabled) {
      await notificationService.cancelSavingsReminder();
      return;
    }

    final hour = prefs.getInt(prefHourKey) ?? defaultHour;
    final minute = prefs.getInt(prefMinuteKey) ?? defaultMinute;

    final savings = await repository.getSavings();
    final totalSavings = MoneyCalculator.calculateTotalSavingsAllocations(savings);

    await notificationService.scheduleSavingsReminder(
      currentSavings: totalSavings,
      hour: hour,
      minute: minute,
      testNow: testNow,
    );
  }
}
