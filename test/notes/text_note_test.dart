import 'package:flutter_test/flutter_test.dart';
import 'package:daily_routine/notes/models/text_note.dart';
import 'package:daily_routine/notes/utils/uuid.dart';

void main() {
  group('TextNote Model Tests', () {
    test('creates TextNote with default values and valid UUID', () {
      final note = TextNote();

      expect(note.id, isNotEmpty);
      expect(Uuid.isValid(note.id), isTrue);
      expect(note.title, isEmpty);
      expect(note.content, isEmpty);
      expect(note.isPinned, isFalse);
      expect(note.createdAt, isNotNull);
      expect(note.updatedAt, isNotNull);
      expect(note.createdAt.isAtSameMomentAs(note.updatedAt), isTrue);
    });

    test('creates TextNote with custom values', () {
      final created = DateTime(2026, 9, 13, 10, 0);
      final updated = DateTime(2026, 9, 13, 11, 0);
      final note = TextNote(
        id: 'test-custom-id',
        title: 'Meeting Notes',
        content: 'Discuss sprint goals',
        isPinned: true,
        createdAt: created,
        updatedAt: updated,
      );

      expect(note.id, 'test-custom-id');
      expect(note.title, 'Meeting Notes');
      expect(note.content, 'Discuss sprint goals');
      expect(note.isPinned, isTrue);
      expect(note.createdAt, created);
      expect(note.updatedAt, updated);
    });

    test('1. Text Note creation and JSON round-trip', () {
      final created = DateTime(2026, 9, 13, 12, 0, 0);
      final updated = DateTime(2026, 9, 13, 12, 30, 0);
      final note = TextNote(
        id: 'note-uuid-12345',
        title: 'Project Architecture',
        content: 'V3 Notes Module Foundation',
        isPinned: true,
        createdAt: created,
        updatedAt: updated,
      );

      final json = note.toJson();
      expect(json['id'], 'note-uuid-12345');
      expect(json['title'], 'Project Architecture');
      expect(json['content'], 'V3 Notes Module Foundation');
      expect(json['isPinned'], isTrue);
      expect(json['createdAt'], created.toIso8601String());
      expect(json['updatedAt'], updated.toIso8601String());

      final roundTrip = TextNote.fromJson(json);
      expect(roundTrip.id, note.id);
      expect(roundTrip.title, note.title);
      expect(roundTrip.content, note.content);
      expect(roundTrip.isPinned, note.isPinned);
      expect(roundTrip.createdAt.isAtSameMomentAs(note.createdAt), isTrue);
      expect(roundTrip.updatedAt.isAtSameMomentAs(note.updatedAt), isTrue);
      expect(roundTrip, equals(note));
    });

    test('4. Stable UUID preservation across copyWith', () {
      final originalId = Uuid.v4();
      final note = TextNote(
        id: originalId,
        title: 'Original Title',
        content: 'Original Content',
      );

      final updated = note.copyWith(title: 'Edited Title');
      expect(updated.id, originalId);
    });

    test('5 & 6. createdAt remains unchanged and updatedAt changes on copyWith update', () async {
      final created = DateTime(2026, 9, 1, 10, 0);
      final initialUpdated = DateTime(2026, 9, 1, 10, 0);
      final note = TextNote(
        id: 'stable-id',
        title: 'Initial',
        createdAt: created,
        updatedAt: initialUpdated,
      );

      // Small delay to ensure timestamp advancement
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final modified = note.copyWith(title: 'Modified Title');

      expect(modified.id, 'stable-id');
      expect(modified.createdAt, created);
      expect(modified.updatedAt.isAfter(initialUpdated), isTrue);
    });

    test('10. Malformed JSON is handled defensively without throwing', () {
      final malformedJson = <String, dynamic>{
        'id': null,
        'title': 12345, // wrong type
        'content': null,
        'isPinned': 'not-a-bool',
        'createdAt': 'invalid-date-string',
        'updatedAt': 99999, // wrong type
      };

      final note = TextNote.fromJson(malformedJson);

      expect(note.id, isNotEmpty);
      expect(Uuid.isValid(note.id), isTrue);
      expect(note.title, '12345');
      expect(note.content, isEmpty);
      expect(note.isPinned, isFalse);
      expect(note.createdAt, isNotNull);
      expect(note.updatedAt, isNotNull);
    });
  });
}
