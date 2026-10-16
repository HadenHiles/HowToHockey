import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/features/drills/drill_media.dart';

void main() {
  late Directory cache;
  setUp(() async => cache = await Directory.systemTemp.createTemp('hth-media-'));
  tearDown(() => cache.delete(recursive: true));

  FirebaseDrillMediaSource source(Future<void> Function(String, File) downloader, {Future<String?> Function(String)? version}) =>
      FirebaseDrillMediaSource(downloader: downloader, versionLookup: version ?? (_) async => 'v1', cacheDirectory: () async => cache);

  test('downloads the video and poster once, then serves them from disk', () async {
    final downloads = <String>[];
    final media = source((path, file) async {
      downloads.add(path);
      await file.writeAsBytes([1, 2, 3]);
    });

    final first = await media.load('drills/toe-drag.mp4');
    expect(first?.video.path, endsWith('toe-drag.mp4'));
    expect(first?.poster?.path, endsWith('toe-drag.jpg'));
    await media.load('drills/toe-drag.mp4');
    expect(downloads, ['drills/toe-drag.mp4', 'drills/toe-drag.jpg']);
  });

  test('prefetch warms the cache so a later load needs no download', () async {
    var downloads = 0;
    final media = source((path, file) async {
      downloads++;
      await file.writeAsBytes([1]);
    });

    await media.prefetch('drills/a.mp4');
    expect(downloads, 2);
    expect(await media.load('drills/a.mp4'), isNotNull);
    expect(downloads, 2);
  });

  test('concurrent requests for the same file share one download', () async {
    var downloads = 0;
    final media = source((path, file) async {
      downloads++;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await file.writeAsBytes([1]);
    });

    await Future.wait([media.load('drills/a.mp4'), media.load('drills/a.mp4')]);
    expect(downloads, 2);
  });

  test('a failed download returns null and leaves no partial file', () async {
    final media = source((path, file) async {
      await file.writeAsBytes([1]);
      throw const FileSystemException('offline');
    });

    expect(await media.load('drills/a.mp4'), isNull);
    expect(cache.listSync(), isEmpty);
  });

  test('a missing poster still plays the video', () async {
    final media = source((path, file) async {
      if (path.endsWith('.jpg')) throw const FileSystemException('missing');
      await file.writeAsBytes([1]);
    });

    final result = await media.load('drills/a.mp4');
    expect(result?.video.existsSync(), isTrue);
    expect(result?.poster, isNull);
  });

  test('drills without hosted media are skipped without downloading', () async {
    var downloads = 0;
    final media = source((path, file) async => downloads++);

    expect(await media.load('placeholder/quick-release'), isNull);
    await media.prefetch('placeholder/quick-release');
    expect(downloads, 0);
  });

  test('a replaced upload refreshes the cached copy on the next run', () async {
    var content = 1;
    var version = 'v1';
    Future<void> download(String path, File file) => file.writeAsBytes([content]);

    final first = source(download, version: (_) async => version);
    final cached = (await first.load('drills/a.mp4'))!.video;
    expect(cached.readAsBytesSync(), [1]);

    // The video is replaced in Storage; a later app run checks the version and refreshes.
    content = 2;
    version = 'v2';
    final secondRun = source(download, version: (_) async => version);
    expect(((await secondRun.load('drills/a.mp4'))!.video).readAsBytesSync(), [1], reason: 'served from disk immediately');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(cached.readAsBytesSync(), [2]);
  });

  test('an unchanged or unreachable version keeps the cached copy without re-downloading', () async {
    var downloads = 0;
    Future<void> download(String path, File file) async {
      downloads++;
      await file.writeAsBytes([downloads]);
    }

    await source(download).load('drills/a.mp4');
    final afterFirst = downloads;
    await source(download).load('drills/a.mp4');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(downloads, afterFirst);

    await source(download, version: (_) async => throw const FileSystemException('offline')).load('drills/a.mp4');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(downloads, afterFirst);
  });
}
