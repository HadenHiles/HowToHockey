import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProgramDayContent {
  const ProgramDayContent({required this.lessonTitle, required this.lessonMinutes, required this.drills, required this.challengeTitle, required this.challengeDescription});

  final String lessonTitle;
  final int lessonMinutes;
  final List<({String drillId, int sets})> drills;
  final String challengeTitle;
  final String challengeDescription;
}

class TrainingProgram {
  const TrainingProgram({
    required this.id,
    required this.title,
    required this.skill,
    required this.detail,
    required this.price,
    required this.days,
    required this.entitlement,
    required this.templates,
  });

  final String id;
  final String title;
  final String skill;
  final String detail;
  final String price;
  final int days;
  final String entitlement;
  final List<ProgramDayContent> templates;

  ProgramDayContent day(int number) => templates[(number - 1) % templates.length];
}

class ProgramProgress {
  const ProgramProgress({this.completedDays = const [], this.completedChallenges = const []});

  final List<int> completedDays;
  final List<int> completedChallenges;
  int get nextDay => completedDays.length + 1;
  bool isComplete(int day) => completedDays.contains(day);
  bool isChallengeComplete(int day) => completedChallenges.contains(day);
  bool isAvailable(int day) => day == 1 || day <= nextDay;
}

class ProgramDashboard {
  const ProgramDashboard({required this.ownedProgramIds});

  final Set<String> ownedProgramIds;
}

class ProgramException implements Exception {
  const ProgramException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class ProgramRepository {
  Future<List<TrainingProgram>> loadCatalog();
  Future<ProgramDashboard> loadDashboard(String profileId);
  Stream<ProgramProgress?> watchProgress(String profileId, String programId);
  Future<String> startDay({required String profileId, required String programId, required int day});
}

class FirebaseProgramRepository implements ProgramRepository {
  FirebaseProgramRepository({FirebaseFunctions? functions, FirebaseFirestore? firestore}) : _functions = functions ?? FirebaseFunctions.instance, _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

  @override
  Future<List<TrainingProgram>> loadCatalog() async {
    try {
      final result = await _functions.httpsCallable('getProgramCatalog').call<Map<Object?, Object?>>();
      final rawPrograms = result.data['programs'];
      if (rawPrograms is! List) throw const FormatException('Program catalog is invalid.');
      return List.unmodifiable([for (final raw in rawPrograms) _program(_map(raw))]);
    } on FirebaseFunctionsException catch (error) {
      throw ProgramException(_message(error));
    } on FormatException {
      throw const ProgramException('The program catalog could not be read.');
    }
  }

  @override
  Future<ProgramDashboard> loadDashboard(String profileId) async {
    try {
      final result = await _functions.httpsCallable('getProgramDashboard').call<Map<Object?, Object?>>({'profileId': profileId});
      final ids = result.data['ownedProgramIds'];
      return ProgramDashboard(ownedProgramIds: ids is List ? ids.whereType<String>().toSet() : const {});
    } on FirebaseFunctionsException catch (error) {
      throw ProgramException(_message(error));
    }
  }

  @override
  Stream<ProgramProgress?> watchProgress(String profileId, String programId) => _firestore.collection('profiles').doc(profileId).collection('programs').doc(programId).snapshots().map((doc) {
    if (!doc.exists) return null;
    final days = doc.data()?['completedDays'];
    final challenges = doc.data()?['completedChallenges'];
    if (days is! List || (challenges != null && challenges is! List)) throw const FormatException('Program progress is invalid.');
    return ProgramProgress(
      completedDays: List.unmodifiable(days.whereType<int>().toSet().toList()..sort()),
      completedChallenges: List.unmodifiable((challenges as List? ?? const []).whereType<int>().toSet().toList()..sort()),
    );
  });

  @override
  Future<String> startDay({required String profileId, required String programId, required int day}) async {
    try {
      final result = await _functions.httpsCallable('startProgramDay').call<Map<Object?, Object?>>({'profileId': profileId, 'programId': programId, 'day': day});
      final runId = result.data['runId'];
      if (runId is! String || runId.isEmpty) throw const FormatException('Program run was not created.');
      return runId;
    } on FirebaseFunctionsException catch (error) {
      throw ProgramException(_message(error));
    } on FormatException {
      throw const ProgramException('Couldn’t start this program day. Try again.');
    }
  }
}

Map<String, dynamic> _map(Object? value) {
  if (value is! Map) throw const FormatException('Program data is invalid.');
  return Map<String, dynamic>.from(value);
}

TrainingProgram _program(Map<String, dynamic> json) {
  final rawTemplates = json['templates'];
  if (json['id'] is! String ||
      json['title'] is! String ||
      json['skill'] is! String ||
      json['detail'] is! String ||
      json['price'] is! String ||
      json['days'] is! int ||
      json['entitlement'] is! String ||
      rawTemplates is! List ||
      rawTemplates.isEmpty) {
    throw const FormatException('Program data is incomplete.');
  }
  return TrainingProgram(
    id: json['id'] as String,
    title: json['title'] as String,
    skill: json['skill'] as String,
    detail: json['detail'] as String,
    price: json['price'] as String,
    days: json['days'] as int,
    entitlement: json['entitlement'] as String,
    templates: List.unmodifiable([for (final raw in rawTemplates) _day(_map(raw))]),
  );
}

ProgramDayContent _day(Map<String, dynamic> json) {
  final ids = json['drillIds'];
  final sets = json['sets'];
  if (json['lessonTitle'] is! String || json['lessonMinutes'] is! int || ids is! List || sets is! List || ids.length != sets.length || ids.isEmpty || json['challenge'] is! Map) {
    throw const FormatException('Program day data is invalid.');
  }
  final challenge = _map(json['challenge']);
  if (challenge['title'] is! String || challenge['description'] is! String || ids.any((id) => id is! String) || sets.any((repetitions) => repetitions is! int || repetitions < 1 || repetitions > 10)) {
    throw const FormatException('Program day data is invalid.');
  }
  return ProgramDayContent(
    lessonTitle: json['lessonTitle'] as String,
    lessonMinutes: json['lessonMinutes'] as int,
    drills: List.unmodifiable([for (final (index, id) in ids.indexed) (drillId: id as String, sets: sets[index] as int)]),
    challengeTitle: challenge['title'] as String,
    challengeDescription: challenge['description'] as String,
  );
}

String _message(FirebaseFunctionsException error) => switch (error.code) {
  'unauthenticated' => 'Sign in to save program progress.',
  'permission-denied' => error.message ?? 'This program day isn’t available for this player yet.',
  'failed-precondition' => error.message ?? 'Finish the earlier program days first.',
  'not-found' => error.message ?? 'We couldn’t find that program or player.',
  'invalid-argument' => error.message ?? 'That program day isn’t valid.',
  'unavailable' || 'deadline-exceeded' => 'Couldn’t reach the server. Check your connection and try again.',
  _ => 'Something went wrong. Try again.',
};

final programRepositoryProvider = Provider<ProgramRepository>((ref) => FirebaseProgramRepository());
final programCatalogProvider = FutureProvider<List<TrainingProgram>>((ref) => ref.watch(programRepositoryProvider).loadCatalog());
final programDashboardProvider = FutureProvider.family<ProgramDashboard, String>((ref, profileId) => ref.watch(programRepositoryProvider).loadDashboard(profileId));
final programProgressProvider = StreamProvider.family<ProgramProgress?, ({String profileId, String programId})>(
  (ref, key) => ref.watch(programRepositoryProvider).watchProgress(key.profileId, key.programId),
);
