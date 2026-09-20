package com.example.daily_routine

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.util.SizeF
import android.view.View
import android.widget.RemoteViews
import java.util.Calendar

class TimetableWidgetProvider : AppWidgetProvider() {

    companion object {
        const val ACTION_UPDATE_WIDGET = "com.example.daily_routine.ACTION_UPDATE_WIDGET"
        const val ACTION_OPEN_TIMETABLE = "com.example.daily_routine.ACTION_OPEN_TIMETABLE"

        data class SecondaryClass(
            val title: String,
            val code: String,
            val room: String,
            val time: String
        )

        data class Session(
            val day: Int, // 1 = Monday ... 7 = Sunday
            val startTime: String,
            val endTime: String,
            val startMinutes: Int,
            val endMinutes: Int,
            val courseCode: String,
            val courseTitle: String,
            val room: String
        )

        private fun parseMinutes(time: String): Int {
            val parts = time.split(":")
            return parts[0].toInt() * 60 + parts[1].toInt()
        }

        private fun s(day: Int, start: String, end: String, code: String, title: String, room: String): Session {
            return Session(
                day = day,
                startTime = start,
                endTime = end,
                startMinutes = parseMinutes(start),
                endMinutes = parseMinutes(end),
                courseCode = code,
                courseTitle = title,
                room = room
            )
        }

        // Centralized immutable schedule identical to Dart TimetableData
        val SCHEDULE = listOf(
            // MONDAY (1)
            s(1, "08:00", "08:50", "24CSEN1011", "Object Oriented Programming", "ICT / 505"),
            s(1, "09:00", "09:50", "24CSEN2021", "Computer Organization and Architecture", "ICT / 505"),
            s(1, "10:00", "10:50", "MATH2561", "Probability and Statistics For Engineering", "ICT / 218"),
            s(1, "11:00", "11:50", "24CSEN2001", "Data Structures", "ICT / 617"),
            s(1, "13:00", "13:50", "EECE2191", "Fundamentals of Autonomous Vehicles", "ICT / 424"),

            // TUESDAY (2)
            s(2, "08:00", "08:50", "24CSEN1011P", "Object Oriented Programming Lab", "ICT / 209"),
            s(2, "09:00", "09:50", "24CSEN1011P", "Object Oriented Programming Lab", "ICT / 209"),
            s(2, "10:00", "10:50", "24CSEN2021", "Computer Organization and Architecture", "ICT / 505"),
            s(2, "11:00", "11:50", "MATH2561", "Probability and Statistics For Engineering", "ICT / 6032"),
            s(2, "13:00", "13:50", "EECE2191", "Fundamentals of Autonomous Vehicles", "ICT / 424"),

            // WEDNESDAY (3)
            s(3, "08:00", "08:50", "24CSEN2001", "Data Structures", "ICT / 617"),
            s(3, "09:00", "09:50", "24CSEN1011", "Object Oriented Programming", "ICT / 505"),
            s(3, "10:00", "10:50", "MATH2561", "Probability and Statistics For Engineering", "ICT / 218"),
            s(3, "11:00", "11:50", "24CSEN2021", "Computer Organization and Architecture", "ICT / 505"),
            s(3, "13:00", "13:50", "EECE2191", "Fundamentals of Autonomous Vehicles", "ICT / 424"),

            // THURSDAY (4)
            s(4, "08:00", "08:50", "24CSEN2001P", "Data Structures Lab", "ICT / 220"),
            s(4, "09:00", "09:50", "24CSEN2001P", "Data Structures Lab", "ICT / 220"),
            s(4, "10:00", "10:50", "GCGC1001", "Aptitude and Self-Management Skills", "ICT / 617"),
            s(4, "11:00", "11:50", "GCGC1001", "Aptitude and Self-Management Skills", "ICT / 617"),
            s(4, "14:00", "14:50", "24CSEN2021", "Computer Organization and Architecture", "ICT / 505"),

            // FRIDAY (5)
            s(5, "09:00", "09:50", "MATH2561", "Probability and Statistics For Engineering", "ICT / 6032"),
            s(5, "10:00", "10:50", "24CSEN2001", "Data Structures", "ICT / 617"),
            s(5, "11:00", "11:50", "24CSEN1011", "Object Oriented Programming", "ICT / 505")
        )

        private val DAY_NAMES = arrayOf("", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday")

        fun getDayName(day: Int): String {
            return if (day in 1..7) DAY_NAMES[day] else ""
        }

        fun getSessionsForDay(day: Int): List<Session> {
            return SCHEDULE.filter { it.day == day }.sortedBy { it.startMinutes }
        }

        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, TimetableWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
            if (appWidgetIds != null && appWidgetIds.isNotEmpty()) {
                val provider = TimetableWidgetProvider()
                provider.onUpdate(context, appWidgetManager, appWidgetIds)
            }
        }
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        try {
            val nowCal = Calendar.getInstance()

            // Convert Calendar day (Sunday=1, Monday=2..Saturday=7) to ISO day (Monday=1..Sunday=7)
            val calDay = nowCal.get(Calendar.DAY_OF_WEEK)
            val isoDay = if (calDay == Calendar.SUNDAY) 7 else calDay - 1

            val currentMinutes = nowCal.get(Calendar.HOUR_OF_DAY) * 60 + nowCal.get(Calendar.MINUTE)
            val todaySessions = getSessionsForDay(isoDay)

            var statusBadge = "NO CLASSES TODAY"
            var badgeBackgroundRes = R.drawable.widget_badge_muted
            var badgeTextColor = 0xFF8FAEAD.toInt()
            var courseTitle = "No Classes Today"
            var courseCode = ""
            var room = ""
            var time = "No classes scheduled"
            var showDetailsRow = false
            var nextTransitionMillis = 0L
            var secondaryClass: SecondaryClass? = null

            // Helper to get next upcoming session on subsequent days
            fun findUpcomingAfter(startDay: Int): Pair<Session, String>? {
                for (offset in 1..7) {
                    val nextDay = ((startDay - 1 + offset) % 7) + 1
                    val sessions = getSessionsForDay(nextDay)
                    if (sessions.isNotEmpty()) {
                        val dayLabel = if (offset == 1) "Tomorrow" else getDayName(nextDay)
                        return Pair(sessions.first(), dayLabel)
                    }
                }
                return null
            }

            // Helper to calculate exact transition timestamp
            fun getTodayMillis(minutes: Int): Long {
                val c = nowCal.clone() as Calendar
                c.set(Calendar.HOUR_OF_DAY, minutes / 60)
                c.set(Calendar.MINUTE, minutes % 60)
                c.set(Calendar.SECOND, 0)
                c.set(Calendar.MILLISECOND, 0)
                return c.timeInMillis
            }

            fun getNextMidnightMillis(): Long {
                val c = nowCal.clone() as Calendar
                c.add(Calendar.DAY_OF_MONTH, 1)
                c.set(Calendar.HOUR_OF_DAY, 0)
                c.set(Calendar.MINUTE, 0)
                c.set(Calendar.SECOND, 0)
                c.set(Calendar.MILLISECOND, 0)
                return c.timeInMillis
            }

            if (todaySessions.isEmpty()) {
                // Case 1: Weekend or day with no classes
                statusBadge = "NO CLASSES TODAY"
                badgeBackgroundRes = R.drawable.widget_badge_muted
                badgeTextColor = 0xFF8FAEAD.toInt()
                courseTitle = "No Classes Today"
                showDetailsRow = false
                time = "Enjoy your day off!"
                val upcoming = findUpcomingAfter(isoDay)
                if (upcoming != null) {
                    val s = upcoming.first
                    secondaryClass = SecondaryClass(
                        title = s.courseTitle,
                        code = s.courseCode,
                        room = "📍 ${s.room}",
                        time = "🕒 ${upcoming.second} ${s.startTime} – ${s.endTime}"
                    )
                }
                nextTransitionMillis = getNextMidnightMillis()
            } else {
                // Check if class currently running
                var runningSession: Session? = null
                var runningIndex = -1
                for (i in todaySessions.indices) {
                    val s = todaySessions[i]
                    if (currentMinutes in s.startMinutes until s.endMinutes) {
                        runningSession = s
                        runningIndex = i
                        break
                    }
                }

                if (runningSession != null) {
                    // Case 2: Class currently in session
                    statusBadge = "NOW"
                    badgeBackgroundRes = R.drawable.widget_badge_now
                    badgeTextColor = 0xFF99F6E4.toInt()
                    courseTitle = runningSession.courseTitle
                    courseCode = runningSession.courseCode
                    room = "📍 ${runningSession.room}"
                    time = "🕒 ${runningSession.startTime} – ${runningSession.endTime}"
                    showDetailsRow = true

                    val nextSessionToday = if (runningIndex + 1 < todaySessions.size) todaySessions[runningIndex + 1] else null
                    if (nextSessionToday != null) {
                        secondaryClass = SecondaryClass(
                            title = nextSessionToday.courseTitle,
                            code = nextSessionToday.courseCode,
                            room = "📍 ${nextSessionToday.room}",
                            time = "🕒 ${nextSessionToday.startTime} – ${nextSessionToday.endTime}"
                        )
                    } else {
                        val upcoming = findUpcomingAfter(isoDay)
                        if (upcoming != null) {
                            val s = upcoming.first
                            secondaryClass = SecondaryClass(
                                title = s.courseTitle,
                                code = s.courseCode,
                                room = "📍 ${s.room}",
                                time = "🕒 ${upcoming.second} ${s.startTime} – ${s.endTime}"
                            )
                        }
                    }
                    nextTransitionMillis = getTodayMillis(runningSession.endMinutes)
                } else {
                    // Check if an upcoming class exists today
                    var nextSessionToday: Session? = null
                    var nextSessionIndex = -1
                    for (i in todaySessions.indices) {
                        val s = todaySessions[i]
                        if (currentMinutes < s.startMinutes) {
                            nextSessionToday = s
                            nextSessionIndex = i
                            break
                        }
                    }

                    if (nextSessionToday != null) {
                        // Case 3: Next class upcoming today
                        statusBadge = "NEXT CLASS"
                        badgeBackgroundRes = R.drawable.widget_badge_next
                        badgeTextColor = 0xFFA5F3FC.toInt()
                        courseTitle = nextSessionToday.courseTitle
                        courseCode = nextSessionToday.courseCode
                        room = "📍 ${nextSessionToday.room}"
                        time = "🕒 ${nextSessionToday.startTime} – ${nextSessionToday.endTime}"
                        showDetailsRow = true

                        val followingSessionToday = if (nextSessionIndex + 1 < todaySessions.size) todaySessions[nextSessionIndex + 1] else null
                        if (followingSessionToday != null) {
                            secondaryClass = SecondaryClass(
                                title = followingSessionToday.courseTitle,
                                code = followingSessionToday.courseCode,
                                room = "📍 ${followingSessionToday.room}",
                                time = "🕒 ${followingSessionToday.startTime} – ${followingSessionToday.endTime}"
                            )
                        } else {
                            val upcoming = findUpcomingAfter(isoDay)
                            if (upcoming != null) {
                                val s = upcoming.first
                                secondaryClass = SecondaryClass(
                                    title = s.courseTitle,
                                    code = s.courseCode,
                                    room = "📍 ${s.room}",
                                    time = "🕒 ${upcoming.second} ${s.startTime} – ${s.endTime}"
                                )
                            }
                        }
                        nextTransitionMillis = getTodayMillis(nextSessionToday.startMinutes)
                    } else {
                        // Case 4: All classes finished for today
                        statusBadge = "TODAY'S CLASSES FINISHED"
                        badgeBackgroundRes = R.drawable.widget_badge_done
                        badgeTextColor = 0xFFB2D8D6.toInt()
                        courseTitle = "All Classes Finished"
                        showDetailsRow = false
                        time = "Done for today!"
                        val upcoming = findUpcomingAfter(isoDay)
                        if (upcoming != null) {
                            val s = upcoming.first
                            secondaryClass = SecondaryClass(
                                title = s.courseTitle,
                                code = s.courseCode,
                                room = "📍 ${s.room}",
                                time = "🕒 ${upcoming.second} ${s.startTime} – ${s.endTime}"
                            )
                        }
                        nextTransitionMillis = getNextMidnightMillis()
                    }
                }
            }

            // Tap PendingIntent: Launch MainActivity with action ACTION_OPEN_TIMETABLE
            val openIntent = Intent(context, MainActivity::class.java).apply {
                action = ACTION_OPEN_TIMETABLE
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("route", "timetable")
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                100,
                openIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
            )

            for (appWidgetId in appWidgetIds) {
                val standardViews = bindWidgetViews(
                    context = context,
                    layoutId = R.layout.timetable_widget,
                    statusBadge = statusBadge,
                    badgeBackgroundRes = badgeBackgroundRes,
                    badgeTextColor = badgeTextColor,
                    dayName = getDayName(isoDay),
                    courseTitle = courseTitle,
                    courseCode = courseCode,
                    room = room,
                    time = time,
                    showDetailsRow = showDetailsRow,
                    secondaryClass = secondaryClass,
                    pendingIntent = pendingIntent
                )

                val compactViews = bindWidgetViews(
                    context = context,
                    layoutId = R.layout.timetable_widget_compact,
                    statusBadge = statusBadge,
                    badgeBackgroundRes = badgeBackgroundRes,
                    badgeTextColor = badgeTextColor,
                    dayName = getDayName(isoDay),
                    courseTitle = courseTitle,
                    courseCode = courseCode,
                    room = room,
                    time = time,
                    showDetailsRow = showDetailsRow,
                    secondaryClass = secondaryClass,
                    pendingIntent = pendingIntent
                )

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    val viewMapping = mapOf(
                        SizeF(0f, 0f) to compactViews,
                        SizeF(0f, 145f) to standardViews
                    )
                    appWidgetManager.updateAppWidget(appWidgetId, RemoteViews(viewMapping))
                } else {
                    val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
                    val minHeight = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0) ?: 0
                    val views = if (minHeight in 1..144) compactViews else standardViews
                    appWidgetManager.updateAppWidget(appWidgetId, views)
                }
            }

            // Schedule next boundary update alarm
            scheduleNextUpdate(context, nextTransitionMillis)
        } catch (t: Throwable) {
            Log.e("TimetableWidget", "Error updating widget", t)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle?
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        try {
            onUpdate(context, appWidgetManager, intArrayOf(appWidgetId))
        } catch (t: Throwable) {
            Log.e("TimetableWidget", "Error on options changed", t)
        }
    }

    private fun bindWidgetViews(
        context: Context,
        layoutId: Int,
        statusBadge: String,
        badgeBackgroundRes: Int,
        badgeTextColor: Int,
        dayName: String,
        courseTitle: String,
        courseCode: String,
        room: String,
        time: String,
        showDetailsRow: Boolean,
        secondaryClass: SecondaryClass?,
        pendingIntent: PendingIntent
    ): RemoteViews {
        val views = RemoteViews(context.packageName, layoutId)

        views.setTextViewText(R.id.widget_status_badge, statusBadge)
        views.setInt(R.id.widget_status_badge, "setBackgroundResource", badgeBackgroundRes)
        views.setTextColor(R.id.widget_status_badge, badgeTextColor)
        views.setTextViewText(R.id.widget_day_text, dayName)
        views.setTextViewText(R.id.widget_course_title, courseTitle)
        views.setTextViewText(R.id.widget_time, time)

        if (showDetailsRow) {
            views.setViewVisibility(R.id.widget_details_row, View.VISIBLE)
            views.setTextViewText(R.id.widget_course_code, courseCode)
            views.setTextViewText(R.id.widget_room, room)
        } else {
            views.setViewVisibility(R.id.widget_details_row, View.GONE)
        }

        if (secondaryClass != null) {
            views.setViewVisibility(R.id.widget_divider, View.VISIBLE)
            views.setViewVisibility(R.id.widget_next_section, View.VISIBLE)
            views.setTextViewText(R.id.widget_next_title, secondaryClass.title)
            views.setTextViewText(R.id.widget_next_code, secondaryClass.code)
            views.setTextViewText(R.id.widget_next_room, secondaryClass.room)
            views.setTextViewText(R.id.widget_next_time, secondaryClass.time)
        } else {
            views.setViewVisibility(R.id.widget_divider, View.GONE)
            views.setViewVisibility(R.id.widget_next_section, View.GONE)
        }

        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
        return views
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        val action = intent.action ?: return
        if (action == ACTION_UPDATE_WIDGET ||
            action == Intent.ACTION_BOOT_COMPLETED ||
            action == Intent.ACTION_TIME_CHANGED ||
            action == Intent.ACTION_TIMEZONE_CHANGED ||
            action == "android.intent.action.TIME_SET" ||
            action == "android.intent.action.MY_PACKAGE_REPLACED" ||
            action == Intent.ACTION_WALLPAPER_CHANGED ||
            action == Intent.ACTION_CONFIGURATION_CHANGED
        ) {
            updateAllWidgets(context)
        }
    }

    private fun scheduleNextUpdate(context: Context, nextTransitionMillis: Long) {
        if (nextTransitionMillis <= 0L) return
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return

        val intent = Intent(context, TimetableWidgetProvider::class.java).apply {
            action = ACTION_UPDATE_WIDGET
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            200,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        )

        // Safety: ensure alarm is at least 10 seconds in the future
        val now = System.currentTimeMillis()
        val alarmTime = if (nextTransitionMillis > now) nextTransitionMillis + 500 else now + 60_000

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC, alarmTime, pendingIntent)
            } else {
                alarmManager.setExact(AlarmManager.RTC, alarmTime, pendingIntent)
            }
        } catch (e: Exception) {
            alarmManager.set(AlarmManager.RTC, alarmTime, pendingIntent)
        }
    }
}
