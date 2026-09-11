import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_routine/models/guitar_song.dart';
import 'package:daily_routine/controllers/guitar_songs_controller.dart';
import 'package:daily_routine/screens/songs_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GuitarSong Model', () {
    test('toJson and fromJson work correctly', () {
      final now = DateTime(2026, 9, 11, 8, 30);
      final song = GuitarSong(
        id: 'song-1',
        name: 'Classical Gas',
        videoLink: 'https://youtube.com/watch?v=123',
        createdAt: now,
      );

      final json = song.toJson();
      expect(json['id'], 'song-1');
      expect(json['name'], 'Classical Gas');
      expect(json['videoLink'], 'https://youtube.com/watch?v=123');
      expect(json['createdAt'], now.toIso8601String());

      final restored = GuitarSong.fromJson(json);
      expect(restored.id, song.id);
      expect(restored.name, song.name);
      expect(restored.videoLink, song.videoLink);
      expect(restored, equals(song));
    });

    test('equality and hashCode are based on id, name, and videoLink', () {
      final now1 = DateTime(2026, 1, 1);
      final now2 = DateTime(2026, 1, 2);
      final s1 = GuitarSong(
        id: '1',
        name: 'Stairway to Heaven',
        videoLink: 'https://youtu.be/abc',
        createdAt: now1,
      );
      final s2 = GuitarSong(
        id: '1',
        name: 'Stairway to Heaven',
        videoLink: 'https://youtu.be/abc',
        createdAt: now2,
      );
      final s3 = GuitarSong(
        id: '2',
        name: 'Stairway to Heaven',
        videoLink: 'https://youtu.be/abc',
        createdAt: now1,
      );

      expect(s1, equals(s2));
      expect(s1.hashCode, equals(s2.hashCode));
      expect(s1, isNot(equals(s3)));
    });
  });

  group('GuitarSongsController', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('initializes empty when no stored data', () async {
      final controller = await GuitarSongsController.init(prefs: prefs);
      expect(controller.songs, isEmpty);
      expect(controller.value, isEmpty);
    });

    test('adds song with valid trimmed name and link', () async {
      final controller = await GuitarSongsController.init(prefs: prefs);
      final success = await controller.addSong(
        '  Hotel California Solo  ',
        '  https://youtube.com/watch?v=xyz  ',
      );

      expect(success, isTrue);
      expect(controller.songs.length, 1);
      expect(controller.songs.first.name, 'Hotel California Solo');
      expect(controller.songs.first.videoLink, 'https://youtube.com/watch?v=xyz');

      // Check persistence
      final reloadedController = await GuitarSongsController.init(prefs: prefs);
      expect(reloadedController.songs.length, 1);
      expect(reloadedController.songs.first.name, 'Hotel California Solo');
    });

    test('rejects empty or whitespace-only name or link', () async {
      final controller = await GuitarSongsController.init(prefs: prefs);

      expect(await controller.addSong('', 'https://youtube.com/watch?v=1'), isFalse);
      expect(await controller.addSong('   ', 'https://youtube.com/watch?v=1'), isFalse);
      expect(await controller.addSong('Blackbird', ''), isFalse);
      expect(await controller.addSong('Blackbird', '   '), isFalse);
      expect(controller.songs, isEmpty);
    });

    test('allows unlimited songs', () async {
      final controller = await GuitarSongsController.init(prefs: prefs);
      for (int i = 1; i <= 25; i++) {
        final ok = await controller.addSong('Song $i', 'https://youtube.com/$i');
        expect(ok, isTrue);
      }
      expect(controller.songs.length, 25);
    });

    test('updates existing song and preserves stable ID and createdAt', () async {
      final controller = await GuitarSongsController.init(prefs: prefs);
      await controller.addSong('Song A', 'https://linkA.com');
      final original = controller.songs.first;
      final originalId = original.id;
      final originalCreatedAt = original.createdAt;

      final success = await controller.updateSong(
        originalId,
        'Updated Song A',
        'https://updated-link.com',
      );

      expect(success, isTrue);
      expect(controller.songs.length, 1);
      final updated = controller.songs.first;
      expect(updated.id, originalId);
      expect(updated.name, 'Updated Song A');
      expect(updated.videoLink, 'https://updated-link.com');
      expect(updated.createdAt, originalCreatedAt);

      // Verify persistence after reload
      final reloaded = await GuitarSongsController.init(prefs: prefs);
      expect(reloaded.songs.length, 1);
      expect(reloaded.songs.first.id, originalId);
      expect(reloaded.songs.first.name, 'Updated Song A');
      expect(reloaded.songs.first.videoLink, 'https://updated-link.com');
    });

    test('updateSong rejects empty or invalid inputs', () async {
      final controller = await GuitarSongsController.init(prefs: prefs);
      await controller.addSong('Song A', 'https://linkA.com');
      final originalId = controller.songs.first.id;

      expect(await controller.updateSong(originalId, '', 'https://link.com'), isFalse);
      expect(await controller.updateSong(originalId, '   ', 'https://link.com'), isFalse);
      expect(await controller.updateSong(originalId, 'Song A', ''), isFalse);
      expect(await controller.updateSong(originalId, 'Song A', '   '), isFalse);
      expect(await controller.updateSong('non-existent-id', 'Name', 'https://link.com'), isFalse);

      // Name remains unchanged
      expect(controller.songs.first.name, 'Song A');
    });
  });

  group('SongsScreen Widget', () {
    late SharedPreferences prefs;
    late GuitarSongsController controller;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      controller = await GuitarSongsController.init(prefs: prefs);
    });

    testWidgets('shows empty state when no songs exist', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SongsScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Songs'), findsOneWidget);
      expect(find.text('No Songs Added Yet'), findsOneWidget);
      expect(find.byKey(const Key('add_song_button')), findsOneWidget);
    });

    testWidgets('opens Add Song dialog, validates input, and saves song', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SongsScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      // Tap + button
      await tester.tap(find.byKey(const Key('add_song_button')));
      await tester.pumpAndSettle();

      expect(find.text('Add Song'), findsOneWidget);
      expect(find.byKey(const Key('song_name_input')), findsOneWidget);
      expect(find.byKey(const Key('song_link_input')), findsOneWidget);

      // Attempt save with empty inputs -> shows validation error
      await tester.tap(find.byKey(const Key('save_song_button')));
      await tester.pumpAndSettle();

      expect(find.text('Song name and video link cannot be empty.'), findsOneWidget);
      expect(controller.songs, isEmpty);

      // Enter valid name and link
      await tester.enterText(
        find.byKey(const Key('song_name_input')),
        'Tears in Heaven',
      );
      await tester.enterText(
        find.byKey(const Key('song_link_input')),
        'https://youtube.com/watch?v=tears',
      );
      await tester.tap(find.byKey(const Key('save_song_button')));
      await tester.pumpAndSettle();

      // Dialog closed and song displayed in list
      expect(find.text('Add Song'), findsNothing);
      expect(find.text('Tears in Heaven'), findsOneWidget);
      expect(find.text('https://youtube.com/watch?v=tears'), findsOneWidget);
      expect(controller.songs.length, 1);
    });

    testWidgets('copies video link to clipboard when copy button tapped', (tester) async {
      String? copiedText;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            copiedText = (methodCall.arguments as Map)['text'] as String?;
            return null;
          }
          return null;
        },
      );

      await controller.addSong(
        'Nothing Else Matters',
        'https://youtu.be/nem123',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SongsScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      final songId = controller.songs.first.id;
      final copyButton = find.byKey(Key('copy_link_button_$songId'));
      expect(copyButton, findsOneWidget);

      await tester.tap(copyButton);
      await tester.pump(); // Show snackbar

      expect(copiedText, 'https://youtu.be/nem123');
      expect(find.text('Link copied to clipboard!'), findsOneWidget);
    });

    testWidgets('can cancel Add Song dialog without saving', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SongsScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add_song_button')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('song_name_input')),
        'Draft Song',
      );
      await tester.tap(find.byKey(const Key('cancel_add_song_button')));
      await tester.pumpAndSettle();

      expect(find.text('Add Song'), findsNothing);
      expect(controller.songs, isEmpty);
    });

    testWidgets('can edit/replace an existing song and retain stable ID', (tester) async {
      await controller.addSong('Old Song', 'https://old.link');
      final originalId = controller.songs.first.id;

      await tester.pumpWidget(
        MaterialApp(
          home: SongsScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Old Song'), findsOneWidget);
      expect(find.text('https://old.link'), findsOneWidget);

      // Tap Edit button
      final editButton = find.byKey(Key('edit_song_button_$originalId'));
      expect(editButton, findsOneWidget);
      await tester.tap(editButton);
      await tester.pumpAndSettle();

      // Dialog opens with prefilled content
      expect(find.text('Edit Song'), findsOneWidget);
      expect(find.byKey(const Key('edit_song_name_input')), findsOneWidget);
      expect(find.byKey(const Key('edit_song_link_input')), findsOneWidget);

      // Change content
      await tester.enterText(find.byKey(const Key('edit_song_name_input')), 'New Song Title');
      await tester.enterText(find.byKey(const Key('edit_song_link_input')), 'https://new.link');

      await tester.tap(find.byKey(const Key('save_edit_song_button')));
      await tester.pumpAndSettle();

      // Dialog is dismissed and UI reflects updated song
      expect(find.text('Edit Song'), findsNothing);
      expect(find.text('New Song Title'), findsOneWidget);
      expect(find.text('https://new.link'), findsOneWidget);
      expect(find.text('Old Song'), findsNothing);

      // Verify stable ID preserved
      expect(controller.songs.first.id, originalId);
      expect(controller.songs.first.name, 'New Song Title');
    });

    testWidgets('strictly NO delete button, trash icon, or delete menu exists on SongsScreen', (tester) async {
      await controller.addSong('Song 1', 'https://song1.link');
      await controller.addSong('Song 2', 'https://song2.link');

      await tester.pumpWidget(
        MaterialApp(
          home: SongsScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delete), findsNothing);
      expect(find.byIcon(Icons.delete_outline), findsNothing);
      expect(find.byIcon(Icons.delete_forever), findsNothing);
      expect(find.byIcon(Icons.delete_sweep), findsNothing);
      expect(find.text('Delete'), findsNothing);
    });
  });
}
