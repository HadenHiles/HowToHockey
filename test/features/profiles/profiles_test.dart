import 'dart:convert';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/features/profiles/display_name.dart';
import 'package:how_to_hockey/features/profiles/player_profile.dart';
import 'package:how_to_hockey/features/profiles/profile_repository.dart';

final now = DateTime.utc(2026, 10, 16);

void main() {
  // The server tests read the same file, so the app and the Cloud Function cannot disagree.
  final vectors = jsonDecode(File('functions/test/vectors/display-names.json').readAsStringSync()) as Map<String, dynamic>;

  group('display names (shared vectors with the server)', () {
    for (final entry in (vectors['valid'] as List).cast<Map<String, dynamic>>()) {
      test('accepts and tidies ${jsonEncode(entry['input'])}', () => expect(normalizeDisplayName(entry['input'] as String), entry['expected']));
    }
    for (final input in (vectors['invalid'] as List).cast<String>()) {
      test('rejects ${jsonEncode(input)}', () => expect(normalizeDisplayName(input), isNull));
    }
  });

  group('age rules', () {
    test('an account needs 14 or more years since birth year', () {
      expect(canHaveOwnAccount(2012, now), isTrue);
      expect(canHaveOwnAccount(2013, now), isFalse);
      expect(canHaveOwnAccount(2026, now), isFalse);
    });

    test('a child profile needs 17 or fewer years and a real year', () {
      expect(canBeChildProfile(2009, now), isTrue);
      expect(canBeChildProfile(2008, now), isFalse);
      expect(canBeChildProfile(2026, now), isTrue);
      expect(canBeChildProfile(2027, now), isFalse);
    });

    test('teens can be either, but never both unsafe', () {
      expect(canHaveOwnAccount(2010, now) && canBeChildProfile(2010, now), isTrue);
      expect(canHaveOwnAccount(2020, now), isFalse);
    });

    test('the cap matches the server', () => expect(maxChildProfiles, 3));
  });

  group('ProfileRepository', () {
    test('checks the form before calling the server, then sends the tidied values', () async {
      final calls = <(String, Map<String, dynamic>)>[];
      final repository = ProfileRepository(
        call: (name, data) async {
          calls.add((name, data));
          return {'profileId': 'abc'};
        },
      );

      expect(await repository.createChildProfile(displayName: ' avery  h ', birthYear: 2015, now: now), 'abc');
      expect(calls.single.$1, 'createChildProfile');
      expect(calls.single.$2, {'displayName': 'Avery H.', 'birthYear': 2015});

      await expectLater(repository.createChildProfile(displayName: 'Avery', birthYear: 2015, now: now), throwsA(isA<ProfileException>()));
      await expectLater(repository.createChildProfile(displayName: 'Avery H.', birthYear: 1990, now: now), throwsA(isA<ProfileException>()));
      await expectLater(repository.createOwnProfile(displayName: 'Pat H.', birthYear: 2015, now: now), throwsA(isA<ProfileException>()));
      expect(calls, hasLength(1), reason: 'bad forms never reach the server');
    });

    test('the adult profile call uses its own function', () async {
      String? called;
      final repository = ProfileRepository(
        call: (name, data) async {
          called = name;
          return {'profileId': 'me'};
        },
      );
      expect(await repository.createOwnProfile(displayName: 'Pat H.', birthYear: 1985, now: now), 'me');
      expect(called, 'createOwnProfile');
    });

    test('server errors become friendly messages', () async {
      Future<String> messageFor(String code, [String? message]) async {
        final repository = ProfileRepository(
          call: (_, _) async => throw FirebaseFunctionsException(code: code, message: message ?? code),
        );
        try {
          await repository.createChildProfile(displayName: 'Avery H.', birthYear: 2015, now: now);
        } on ProfileException catch (error) {
          return error.message;
        }
        return 'no error';
      }

      expect(await messageFor('failed-precondition', 'You can add up to 3 child profiles.'), 'You can add up to 3 child profiles.');
      expect(await messageFor('unauthenticated'), 'Sign in to continue.');
      expect(await messageFor('unavailable'), contains('reach the server'));
      expect(await messageFor('internal'), 'Something went wrong. Try again.');
    });

    test('a malformed response is an error, not a silent success', () async {
      final repository = ProfileRepository(call: (_, _) async => {'nope': true});
      await expectLater(repository.createChildProfile(displayName: 'Avery H.', birthYear: 2015, now: now), throwsA(isA<ProfileException>()));
    });
  });

  test('profiles round-trip through JSON', () {
    const profile = PlayerProfile(id: 'p1', ownerUid: 'u1', displayName: 'Avery H.', birthYear: 2015, isChild: true, teamIds: ['t1']);
    expect(PlayerProfile.fromJson(profile.toJson()), profile);
    expect(PlayerProfile.fromJson({'id': 'p', 'ownerUid': 'u', 'displayName': 'A B.', 'birthYear': 2000, 'isChild': false}).teamIds, isEmpty);
  });
}
