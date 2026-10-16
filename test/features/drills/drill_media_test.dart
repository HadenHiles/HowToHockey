import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/features/drills/drill_media.dart';
import 'package:how_to_hockey/features/drills/models/drill.dart';

Drill drill(String path) => Drill(
  id: 'd',
  title: 'D',
  mediaAssetPath: path,
  formCues: const ['cue'],
  trackingType: TrackingType.volume,
  allowedLocations: const [LocationOption.basement],
  minPuckInventory: PuckInventory.low,
  requiresPasser: false,
  skillWeights: const {SkillPillar.hands: 1},
  tier: AccessTier.free,
  supportedBalls: const [],
  passerTypes: const [],
  defaultPrescription: const DrillPrescription(sets: 1),
  estimatedSecondsPerSet: 30,
  difficulty: 1,
  tags: const [],
);

void main() {
  late Directory cache;
  setUp(() async => cache = await Directory.systemTemp.createTemp('hth-media-'));
  tearDown(() => cache.delete(recursive: true));

  FirebaseDrillMediaSource source(Future<void> Function(String, File) downloader) => FirebaseDrillMediaSource(downloader: downloader, cacheDirectory: () async => cache);

  test('downloads the video and poster once, then serves them from disk', () async {
    final downloads = <String>[];
    final media = source((path, file) async {
      downloads.add(path);
      await file.writeAsBytes([1, 2, 3]);
    });

    final first = await media.load(drill('drills/toe-drag.mp4'));
    expect(first?.video.path, endsWith('toe-drag.mp4'));
    expect(first?.poster?.path, endsWith('toe-drag.jpg'));
    await media.load(drill('drills/toe-drag.mp4'));
    expect(downloads, ['drills/toe-drag.mp4', 'drills/toe-drag.jpg']);
  });

  test('prefetch warms the cache so a later load needs no download', () async {
    var downloads = 0;
    final media = source((path, file) async {
      downloads++;
      await file.writeAsBytes([1]);
    });

    await media.prefetch(drill('drills/a.mp4'));
    expect(downloads, 2);
    expect(await media.load(drill('drills/a.mp4')), isNotNull);
    expect(downloads, 2);
  });

  test('concurrent requests for the same file share one download', () async {
    var downloads = 0;
    final media = source((path, file) async {
      downloads++;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await file.writeAsBytes([1]);
    });

    await Future.wait([media.load(drill('drills/a.mp4')), media.load(drill('drills/a.mp4'))]);
    expect(downloads, 2);
  });

  test('a failed download returns null and leaves no partial file', () async {
    final media = source((path, file) async {
      await file.writeAsBytes([1]);
      throw const FileSystemException('offline');
    });

    expect(await media.load(drill('drills/a.mp4')), isNull);
    expect(cache.listSync(), isEmpty);
  });

  test('a missing poster still plays the video', () async {
    final media = source((path, file) async {
      if (path.endsWith('.jpg')) throw const FileSystemException('missing');
      await file.writeAsBytes([1]);
    });

    final result = await media.load(drill('drills/a.mp4'));
    expect(result?.video.existsSync(), isTrue);
    expect(result?.poster, isNull);
  });

  test('drills without hosted media are skipped without downloading', () async {
    var downloads = 0;
    final media = source((path, file) async => downloads++);

    expect(await media.load(drill('placeholder/quick-release')), isNull);
    await media.prefetch(drill('placeholder/quick-release'));
    expect(downloads, 0);
  });
}
