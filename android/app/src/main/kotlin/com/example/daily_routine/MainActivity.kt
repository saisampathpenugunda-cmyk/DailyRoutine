package com.example.daily_routine

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.example.daily_routine/timetable_widget"
    private var methodChannel: MethodChannel? = null
    private var launchRoute: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
        val route = extractRoute(intent)
        if (route != null) {
            methodChannel?.invokeMethod("onWidgetRoute", route)
        }
    }

    private fun handleIntent(intent: Intent?) {
        val route = extractRoute(intent)
        if (route != null) {
            launchRoute = route
        }
    }

    private fun extractRoute(intent: Intent?): String? {
        if (intent == null) return null
        if (intent.action == TimetableWidgetProvider.ACTION_OPEN_TIMETABLE ||
            intent.getStringExtra("route") == "timetable"
        ) {
            return "timetable"
        }
        return null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialRoute" -> {
                        val route = launchRoute
                        launchRoute = null // consume once
                        result.success(route)
                    }
                    "updateWidget" -> {
                        TimetableWidgetProvider.updateAllWidgets(context)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }
}
