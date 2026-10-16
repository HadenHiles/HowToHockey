import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/features/drills/models/drill.dart';

void main() {
  test('the seed catalog decodes into Drill models', () {
    final catalog = jsonDecode(File('tool/seed/drills.json').readAsStringSync()) as Map<String, dynamic>;
    final drills = (catalog['drills'] as List).cast<Map<String, dynamic>>().map(Drill.fromJson).toList();

    expect(drills, hasLength(20));
    expect(drills.map((d) => d.id).toSet(), hasLength(20));
    expect(drills.expand((d) => d.skillWeights.keys).toSet(), SkillPillar.values.toSet());
    expect(drills.map((d) => d.trackingType).toSet(), TrackingType.values.toSet());
    for (final drill in drills) {
      expect(drill.skillWeights.values.fold<double>(0, (a, b) => a + b), closeTo(1, 1e-6), reason: drill.id);
    }
  });
}
