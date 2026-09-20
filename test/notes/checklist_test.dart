import 'package:flutter_test/flutter_test.dart';
import 'package:daily_routine/notes/models/checklist.dart';
import 'package:daily_routine/notes/models/checklist_item.dart';
import 'package:daily_routine/notes/utils/uuid.dart';

void main() {
  group('Checklist & ChecklistItem Model Tests', () {
    test('3. Checklist item creation and JSON round-trip', () {
      final item = ChecklistItem(
        id: 'item-1',
        text: 'Buy groceries',
        isCompleted: true,
        order: 1,
      );

      final json = item.toJson();
      expect(json['id'], 'item-1');
      expect(json['text'], 'Buy groceries');
      expect(json['isCompleted'], isTrue);
      expect(json['order'], 1);

      final roundTrip = ChecklistItem.fromJson(json);
      expect(roundTrip.id, item.id);
      expect(roundTrip.text, item.text);
      expect(roundTrip.isCompleted, item.isCompleted);
      expect(roundTrip.order, item.order);
      expect(roundTrip, equals(item));
    });

    test('2. Checklist creation and JSON round-trip', () {
      final created = DateTime(2026, 9, 13, 11, 0, 0);
      final updated = DateTime(2026, 9, 13, 11, 45, 0);

      final itemA = ChecklistItem(id: 'item-a', text: 'Task Alpha', isCompleted: false);
      final itemB = ChecklistItem(id: 'item-b', text: 'Task Beta', isCompleted: true);

      final checklist = Checklist(
        id: 'chk-uuid-1',
        title: 'Launch Preparation',
        items: [itemA, itemB],
        isPinned: true,
        createdAt: created,
        updatedAt: updated,
      );

      final json = checklist.toJson();
      expect(json['id'], 'chk-uuid-1');
      expect(json['title'], 'Launch Preparation');
      expect(json['isPinned'], isTrue);
      expect(json['createdAt'], created.toIso8601String());
      expect(json['updatedAt'], updated.toIso8601String());
      expect(json['items'], isA<List>());
      expect((json['items'] as List).length, 2);

      final roundTrip = Checklist.fromJson(json);
      expect(roundTrip.id, checklist.id);
      expect(roundTrip.title, checklist.title);
      expect(roundTrip.isPinned, checklist.isPinned);
      expect(roundTrip.items.length, 2);
      expect(roundTrip.items[0].id, 'item-a');
      expect(roundTrip.items[0].text, 'Task Alpha');
      expect(roundTrip.items[0].isCompleted, isFalse);
      expect(roundTrip.items[1].id, 'item-b');
      expect(roundTrip.items[1].text, 'Task Beta');
      expect(roundTrip.items[1].isCompleted, isTrue);
      expect(roundTrip.createdAt.isAtSameMomentAs(checklist.createdAt), isTrue);
      expect(roundTrip.updatedAt.isAtSameMomentAs(checklist.updatedAt), isTrue);
      expect(roundTrip, equals(checklist));
    });

    test('4. Stable UUID preservation for Checklist and Items', () {
      final item1 = ChecklistItem(id: 'item-fixed-1', text: 'Item 1');
      final item2 = ChecklistItem(id: 'item-fixed-2', text: 'Item 2');
      final checklist = Checklist(
        id: 'chk-fixed',
        title: 'Tasks',
        items: [item1, item2],
      );

      final modified = checklist.copyWith(title: 'Updated Tasks Title');
      expect(modified.id, 'chk-fixed');
      expect(modified.items[0].id, 'item-fixed-1');
      expect(modified.items[1].id, 'item-fixed-2');
    });

    test('7. Checklist item IDs remain unchanged after editing and reordering', () {
      final item1 = ChecklistItem(id: 'uuid-item-1', text: 'First item', order: 0);
      final item2 = ChecklistItem(id: 'uuid-item-2', text: 'Second item', order: 1);
      final item3 = ChecklistItem(id: 'uuid-item-3', text: 'Third item', order: 2);

      final originalChecklist = Checklist(
        id: 'chk-reorder-test',
        title: 'Weekly Chores',
        items: [item1, item2, item3],
      );

      // Edit item2 text and completion status
      final editedItem2 = item2.copyWith(
        text: 'Second item modified',
        isCompleted: true,
      );
      expect(editedItem2.id, 'uuid-item-2'); // ID preserved

      // Reorder: Move item3 to position 0, item1 to position 1, item2 to position 2
      final reorderedItems = [
        item3.copyWith(order: 0),
        item1.copyWith(order: 1),
        editedItem2.copyWith(order: 2),
      ];

      final updatedChecklist = originalChecklist.copyWith(items: reorderedItems);

      // Verify identities are perfectly preserved
      expect(updatedChecklist.items.length, 3);
      expect(updatedChecklist.items[0].id, 'uuid-item-3');
      expect(updatedChecklist.items[0].text, 'Third item');

      expect(updatedChecklist.items[1].id, 'uuid-item-1');
      expect(updatedChecklist.items[1].text, 'First item');

      expect(updatedChecklist.items[2].id, 'uuid-item-2');
      expect(updatedChecklist.items[2].text, 'Second item modified');
      expect(updatedChecklist.items[2].isCompleted, isTrue);
    });

    test('5 & 6. Checklist createdAt remains unchanged and updatedAt changes on copyWith update', () async {
      final created = DateTime(2026, 9, 1, 9, 0);
      final initialUpdated = DateTime(2026, 9, 1, 9, 0);
      final checklist = Checklist(
        id: 'chk-time-test',
        title: 'Initial',
        createdAt: created,
        updatedAt: initialUpdated,
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));
      final updated = checklist.copyWith(title: 'Changed Title');

      expect(updated.createdAt, created);
      expect(updated.updatedAt.isAfter(initialUpdated), isTrue);
    });

    test('10. Malformed JSON handled defensively for Checklist and items', () {
      final malformedChecklistJson = <String, dynamic>{
        'id': null,
        'title': null,
        'isPinned': 'invalid',
        'createdAt': 'broken-time',
        'updatedAt': null,
        'items': [
          // Malformed individual item (not a map)
          'just-a-string',
          // Malformed item with wrong types
          {
            'id': null,
            'text': 999,
            'isCompleted': 'yes',
            'order': 'not-an-int',
          },
          // Valid item
          {
            'id': 'item-valid',
            'text': 'Legit item',
            'isCompleted': true,
            'order': 5,
          },
        ],
      };

      final checklist = Checklist.fromJson(malformedChecklistJson);

      expect(checklist.id, isNotEmpty);
      expect(Uuid.isValid(checklist.id), isTrue);
      expect(checklist.title, isEmpty);
      expect(checklist.isPinned, isFalse);
      expect(checklist.createdAt, isNotNull);
      expect(checklist.updatedAt, isNotNull);

      // Two items survived: the skipped string was ignored, the malformed map was recovered, and the valid one parsed
      expect(checklist.items.length, 2);
      expect(checklist.items[0].id, isNotEmpty);
      expect(checklist.items[0].text, '999');
      expect(checklist.items[0].isCompleted, isFalse);
      expect(checklist.items[0].order, 0);

      expect(checklist.items[1].id, 'item-valid');
      expect(checklist.items[1].text, 'Legit item');
      expect(checklist.items[1].isCompleted, isTrue);
      expect(checklist.items[1].order, 5);
    });

    test('calculates counts: totalItemsCount, completedItemsCount, isAllCompleted', () {
      final checklist = Checklist(
        items: [
          ChecklistItem(id: '1', isCompleted: true),
          ChecklistItem(id: '2', isCompleted: false),
          ChecklistItem(id: '3', isCompleted: true),
        ],
      );

      expect(checklist.totalItemsCount, 3);
      expect(checklist.completedItemsCount, 2);
      expect(checklist.isAllCompleted, isFalse);

      final allDone = checklist.copyWith(
        items: [
          ChecklistItem(id: '1', isCompleted: true),
          ChecklistItem(id: '2', isCompleted: true),
        ],
      );
      expect(allDone.isAllCompleted, isTrue);
    });
  });
}
