import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_routine/models/activity.dart';
import 'package:daily_routine/repositories/activity_repository.dart';
import 'package:daily_routine/screens/guitar_screen.dart';
import 'package:daily_routine/controllers/guitar_songs_controller.dart';
import 'package:daily_routine/controllers/routine_timer_controller.dart';
import 'package:daily_routine/controllers/streak_controller.dart';
import 'package:daily_routine/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late ActivityRepository repository;
  late Activity guitarActivity;
  late GuitarSongsController songsController;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();

    guitarActivity = const Activity(
      id: 'guitar',
      name: 'Guitar',
      activityType: ActivityType.guitar,
      defaultDuration: Duration(minutes: 15),
      isEnabled: true,
      isCompleted: false,
    );

    repository = InMemoryActivityRepository(
      initialActivities: [guitarActivity],
    );
    songsController = await GuitarSongsController.init(prefs: prefs);
  });

  Widget buildTestWidget({
    RoutineTimerController? timer,
    GuitarSongsController? songsCtrl,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: GuitarScreen(
        activity: guitarActivity,
        repository: repository,
        timer: timer,
        songsController: songsCtrl ?? songsController,
      ),
    );
  }

  group('GuitarScreen UI & Timer Functionality', () {
    testWidgets('displays AppBar with "Guitar" and timer with formatted time', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Check AppBar
      expect(find.widgetWithText(AppBar, 'Guitar'), findsOneWidget);

      // Check Timer Display
      expect(find.byKey(const Key('guitar_timer_text')), findsOneWidget);
      expect(find.text('15:00'), findsOneWidget);
      expect(find.text('Practice Time'), findsOneWidget);

      // Check Start button
      expect(find.byKey(const Key('guitar_start_button')), findsOneWidget);
      expect(find.text('Start Practice'), findsOneWidget);

      // Check Songs button directly below
      expect(find.byKey(const Key('guitar_songs_button')), findsOneWidget);
      expect(find.text('Songs'), findsOneWidget);
    });

    testWidgets('timer start, pause, resume, and finish workflow', (tester) async {
      final timer = RoutineTimerController(
        totalDuration: const Duration(minutes: 15),
      );

      await tester.pumpWidget(buildTestWidget(timer: timer));
      await tester.pumpAndSettle();

      // Tap Start
      await tester.tap(find.byKey(const Key('guitar_start_button')));
      await tester.pump();
      expect(timer.isRunning, isTrue);
      expect(find.byKey(const Key('guitar_pause_button')), findsOneWidget);
      expect(find.byKey(const Key('guitar_finish_button')), findsOneWidget);

      // Tap Pause
      await tester.tap(find.byKey(const Key('guitar_pause_button')));
      await tester.pump();
      expect(timer.isPaused, isTrue);
      expect(find.byKey(const Key('guitar_resume_button')), findsOneWidget);

      // Tap Resume
      await tester.tap(find.byKey(const Key('guitar_resume_button')));
      await tester.pump();
      expect(timer.isRunning, isTrue);

      // Tap Finish
      await tester.tap(find.byKey(const Key('guitar_finish_button')));
      await tester.pumpAndSettle();

      expect(timer.isCompleted, isTrue);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Practice Session Done'), findsOneWidget);
      expect(repository.getActivityById('guitar')?.isCompleted, isTrue);
    });

    testWidgets('duration adjustments update activity duration when initial', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap duration control button to open picker sheet
      expect(find.byKey(const Key('duration_control_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('duration_control_button')));
      await tester.pumpAndSettle();

      // Increment minutes
      expect(find.byKey(const Key('increment_minutes_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('increment_minutes_button')));
      await tester.pumpAndSettle();

      // Save picker
      await tester.tap(find.byKey(const Key('duration_picker_save_button')));
      await tester.pumpAndSettle();

      expect(find.text('16:00'), findsOneWidget);
      expect(repository.getActivityById('guitar')?.defaultDuration, const Duration(minutes: 16));
    });

    testWidgets('tapping "Songs" navigates to SongsScreen', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('guitar_songs_button')));
      await tester.pumpAndSettle();

      // SongsScreen is visible
      expect(find.text('No Songs Added Yet'), findsOneWidget);
      expect(find.byKey(const Key('add_song_button')), findsOneWidget);
    });

    testWidgets('Songs operations do NOT alter History, Progress, or Streaks', (tester) async {
      final streakCtrl = StreakController(repository: repository, prefs: prefs);

      // Baseline checks
      final initialHistory = repository.getHistory();
      final initialStreak = streakCtrl.currentStreak;

      // Add a song
      await songsController.addSong('Eruption', 'https://youtube.com/v/eruption');
      expect(songsController.songs.length, 1);

      // Verify History unchanged
      final historyAfterSong = repository.getHistory();
      expect(historyAfterSong.length, initialHistory.length);

      // Verify Streaks unchanged
      expect(streakCtrl.currentStreak, initialStreak);

      // Update/edit the song
      await songsController.updateSong(
        songsController.songs.first.id,
        'Eruption Solo Edit',
        'https://youtube.com/v/eruption_edit',
      );
      expect(songsController.songs.length, 1);
      expect(songsController.songs.first.name, 'Eruption Solo Edit');

      // Verify History & Streaks still untouched
      final historyAfterEdit = repository.getHistory();
      expect(historyAfterEdit.length, initialHistory.length);
      expect(streakCtrl.currentStreak, initialStreak);
    });
  });
}
