import 'package:flutter/material.dart';

import '../models/timetable_data.dart';
import '../models/timetable_session.dart';
import '../services/timetable_service.dart';
import '../theme/notes_theme.dart';

/// Mobile-friendly weekly timetable screen showing Mon-Sat schedule.
class TimetableScreen extends StatefulWidget {
  final TimetableService? timetableService;
  final int? initialDay; // 1 = Mon ... 6 = Sat

  const TimetableScreen({
    super.key,
    this.timetableService,
    this.initialDay,
  });

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  late final TimetableService _timetableService;
  late int _selectedDay; // 1 = Monday ... 6 = Saturday

  @override
  void initState() {
    super.initState();
    _timetableService = widget.timetableService ?? TimetableService();

    // Default to today (if Monday-Saturday), else Monday
    final today = DateTime.now().weekday;
    if (widget.initialDay != null) {
      _selectedDay = widget.initialDay!;
    } else if (today >= 1 && today <= 6) {
      _selectedDay = today;
    } else {
      _selectedDay = 1; // Default to Monday if opened on Sunday
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = NotesTheme.of(context);
    final nowNext = _timetableService.getNowNext();
    final todayWeekday = DateTime.now().weekday;

    final sessions = TimetableData.getSessionsForDay(_selectedDay);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          key: const Key('timetable_back_button'),
          icon: Icon(Icons.arrow_back, color: colors.textMain),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Timetable',
          style: TextStyle(
            color: colors.textMain,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Day Selector Chips ──────────────────────────────────────────
          Container(
            color: colors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (int day = 1; day <= 6; day++) ...[
                    _buildDayChip(
                      day: day,
                      isSelected: _selectedDay == day,
                      isToday: todayWeekday == day,
                      colors: colors,
                    ),
                    if (day < 6) const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ── Sessions List ───────────────────────────────────────────────
          Expanded(
            child: sessions.isEmpty
                ? _buildEmptyState(colors)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: sessions.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      final isCurrent = nowNext.status == NowNextStatus.now &&
                          nowNext.currentSession == session;
                      return _buildSessionCard(
                        session: session,
                        isCurrent: isCurrent,
                        colors: colors,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayChip({
    required int day,
    required bool isSelected,
    required bool isToday,
    required NotesColors colors,
  }) {
    final names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final label = names[day - 1];

    return InkWell(
      key: Key('timetable_day_chip_$day'),
      onTap: () {
        setState(() {
          _selectedDay = day;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary
              : (isToday
                  ? colors.primary.withValues(alpha: 0.15)
                  : colors.card),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? colors.primary
                : (isToday ? colors.primary.withValues(alpha: 0.5) : colors.border),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isToday ? colors.primary : colors.textMain),
              ),
            ),
            if (isToday) ...[
              const SizedBox(width: 4),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? Colors.white : colors.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard({
    required TimetableSession session,
    required bool isCurrent,
    required NotesColors colors,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent ? colors.primary : colors.border,
          width: isCurrent ? 2.0 : 1.0,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Time & Now badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 15, color: colors.primary),
                  const SizedBox(width: 6),
                  Text(
                    '${session.startTime} – ${session.endTime}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors.primary,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'NOW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: Course Title
          Text(
            session.courseTitle,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.textMain,
            ),
          ),
          const SizedBox(height: 8),

          // Row 3: Course Code & Room
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.highlight,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: colors.border),
                ),
                child: Text(
                  session.courseCode,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.location_on_outlined, size: 15, color: colors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  session.room,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(NotesColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy_rounded,
              size: 56,
              color: colors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Classes Scheduled',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textMain,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Enjoy your free day or prepare for upcoming classes.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
