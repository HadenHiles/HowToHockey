import 'dart:async';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'models/drill.dart';

/// Locally cached demo files for one drill.
class DrillMedia {
  const DrillMedia({required this.video, this.poster});

  final File video;
  final File? poster;
}

abstract class DrillMediaSource {
  /// Returns the cached files, downloading them first if needed.
  /// Returns null when the drill has no demo yet or it cannot be fetched.
  Future<DrillMedia?> load(Drill drill);

  /// Warms the cache so the drill is ready when the player gets to it.
  Future<void> prefetch(Drill drill);
}

/// Downloads drill demos from Firebase Storage once and serves them from disk after that,
/// so a drill you have already seen plays offline.
class FirebaseDrillMediaSource implements DrillMediaSource {
  FirebaseDrillMediaSource({Future<void> Function(String remotePath, File destination)? downloader, Future<Directory> Function()? cacheDirectory})
    : _downloader = downloader ?? _downloadFromStorage,
      _cacheDirectory = cacheDirectory ?? _defaultCacheDirectory;

  final Future<void> Function(String remotePath, File destination) _downloader;
  final Future<Directory> Function() _cacheDirectory;
  final _inFlight = <String, Future<File?>>{};

  static Future<Directory> _defaultCacheDirectory() async {
    final root = await getApplicationSupportDirectory();
    return Directory('${root.path}/drill_media').create(recursive: true);
  }

  static Future<void> _downloadFromStorage(String remotePath, File destination) => FirebaseStorage.instance.ref(remotePath).writeToFile(destination);

  static bool hasRemoteMedia(Drill drill) => drill.mediaAssetPath.startsWith('drills/');

  static String posterPath(String videoPath) => '${videoPath.substring(0, videoPath.length - 4)}.jpg';

  @override
  Future<DrillMedia?> load(Drill drill) async {
    if (!hasRemoteMedia(drill)) return null;
    final video = await _fetch(drill.mediaAssetPath);
    if (video == null) return null;
    return DrillMedia(video: video, poster: await _fetch(posterPath(drill.mediaAssetPath)));
  }

  @override
  Future<void> prefetch(Drill drill) async {
    if (!hasRemoteMedia(drill)) return;
    await _fetch(drill.mediaAssetPath);
    await _fetch(posterPath(drill.mediaAssetPath));
  }

  Future<File?> _fetch(String remotePath) => _inFlight.putIfAbsent(remotePath, () {
    final download = _download(remotePath);
    // A block body matters: returning the future from whenComplete would make it wait on itself.
    unawaited(
      download.whenComplete(() {
        _inFlight.remove(remotePath);
      }),
    );
    return download;
  });

  Future<File?> _download(String remotePath) async {
    final directory = await _cacheDirectory();
    final file = File('${directory.path}/${remotePath.split('/').last}');
    if (await file.exists() && await file.length() > 0) return file;
    final partial = File('${file.path}.part');
    try {
      await _downloader(remotePath, partial);
      return await partial.rename(file.path);
    } on Object {
      // Offline, missing, or interrupted: callers fall back to the illustrated placeholder.
      if (await partial.exists()) await partial.delete();
      return null;
    }
  }
}

final drillMediaSourceProvider = Provider<DrillMediaSource>((ref) => FirebaseDrillMediaSource());

final drillMediaProvider = FutureProvider.family<DrillMedia?, Drill>((ref, drill) => ref.watch(drillMediaSourceProvider).load(drill));
