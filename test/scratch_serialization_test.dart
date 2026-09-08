import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_routine/models/activity.dart';

void main() {
  test('Serialization test', () {
    final activity = Activity(
      id: 'dumbbells',
      name: 'Dumbbells',
      activityType: ActivityType.dumbbells,
      defaultDuration: Duration(minutes: 20),
      isCompleted: false,
      isSkipped: true,
      completedSetsReps: [12, 10, 8],
    );

    final json = activity.toJson();
    final encoded = jsonEncode(json);
    final decoded = jsonDecode(encoded);
    final act2 = Activity.fromJson(decoded);
    expect(act2.name, 'Dumbbells');
    expect(act2.isSkipped, isTrue);
    expect(act2.completedSetsReps, [12, 10, 8]);
    expect(act2.defaultDuration, const Duration(minutes: 20));
  });
}
