import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service that interfaces with the native Android Home Screen Timetable Widget via MethodChannel.
class WidgetSyncService {
  static const MethodChannel _channel =
      MethodChannel('com.example.daily_routine/timetable_widget');

  static void Function(String route)? _onWidgetRoute;

  /// Initializes the route listener from native Android widget taps.
  static void initialize({void Function(String route)? onRoute}) {
    _onWidgetRoute = onRoute;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onWidgetRoute') {
        final route = call.arguments as String?;
        if (route != null && _onWidgetRoute != null) {
          _onWidgetRoute!(route);
        }
      }
    });
  }

  /// Triggers an immediate refresh of all Android home screen timetable widgets.
  static Future<void> updateWidget() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _channel.invokeMethod('updateWidget');
      }
    } catch (_) {
      // Gracefully ignore on unsupported platforms or unit test environments
    }
  }

  /// Retrieves any initial deep-link route passed when the app was launched from a widget tap.
  static Future<String?> getInitialRoute() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final route = await _channel.invokeMethod<String>('getInitialRoute');
        return route;
      }
    } catch (_) {
      // Gracefully ignore on unsupported platforms or unit test environments
    }
    return null;
  }
}
