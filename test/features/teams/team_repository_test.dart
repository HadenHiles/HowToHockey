import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/features/teams/team_repository.dart';

void main() {
  test('invite codes and mobile links round trip', () {
    expect(inviteCodeFrom(' abcd ef01 2345 6789 '), 'ABCDEF0123456789');
    expect(inviteCodeFrom(teamInviteLink('ABCDEF0123456789')), 'ABCDEF0123456789');
  });

  test('calls the right server functions with selected profile and approval', () async {
    final calls = <(String, Map<String, dynamic>)>[];
    final repo = TeamRepository(
      call: (name, data) async {
        calls.add((name, data));
        return switch (name) {
          'previewTeamInvite' => {'teamId': 't', 'name': 'Stars', 'kind': 'player'},
          'joinTeam' => {'status': 'parentPending'},
          'createTeamInvite' => {'code': 'ABCDEF0123456789'},
          'reviewTeamRequest' => {'status': 'joined'},
          _ => {},
        };
      },
    );
    expect((await repo.preview(teamInviteLink('ABCDEF0123456789'))).name, 'Stars');
    expect(await repo.join(profileId: 'child', code: 'abcd ef01 2345 6789'), 'parentPending');
    expect(calls.last.$1, 'joinTeam');
    expect(calls.last.$2, {'profileId': 'child', 'code': 'ABCDEF0123456789'});
    await repo.review(const TeamRequest(teamId: 't', profileId: 'child', teamName: 'Stars', displayName: 'Kid H.', status: 'parentPending'), true);
    expect(calls.last.$1, 'reviewTeamRequest');
    expect(calls.last.$2, {'teamId': 't', 'profileId': 'child', 'approve': true});
    expect(await repo.createInvite('t', coach: true), 'ABCDEF0123456789');
  });

  test('rejects invalid codes before a network call and never fabricates a success', () async {
    int calls = 0;
    final repo = TeamRepository(
      call: (_, _) async {
        calls++;
        return {};
      },
    );
    await expectLater(repo.preview('BAD'), throwsA(isA<TeamException>()));
    expect(calls, 0);
    await expectLater(repo.preview('ABCDEF0123456789'), throwsA(isA<TeamException>()));
    await expectLater(repo.join(profileId: 'p', teamId: 't'), throwsA(isA<TeamException>()));
    await expectLater(repo.createInvite('t', coach: true), throwsA(isA<TeamException>()));
    await expectLater(repo.create('Team'), throwsA(isA<TeamException>()));
    await expectLater(repo.setVisibility('t', true), throwsA(isA<TeamException>()));
    await expectLater(repo.acceptCoach('ABCDEF0123456789'), throwsA(isA<TeamException>()));
    await expectLater(repo.remove('t', 'p'), throwsA(isA<TeamException>()));
  });

  test('network and permission failures have actionable messages', () async {
    final repo = TeamRepository(
      call: (_, _) async => throw FirebaseFunctionsException(code: 'unavailable', message: 'Offline'),
    );
    await expectLater(repo.create('Stars'), throwsA(isA<TeamException>().having((e) => e.message, 'message', contains('connection'))));
    final denied = TeamRepository(
      call: (_, _) async => throw FirebaseFunctionsException(code: 'permission-denied', message: 'Only a coach can do this.'),
    );
    await expectLater(denied.create('Stars'), throwsA(isA<TeamException>().having((e) => e.message, 'message', 'Only a coach can do this.')));
  });
}
