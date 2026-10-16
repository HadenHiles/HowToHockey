import 'dart:async';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Locally cached demo files for one drill.
class DrillMedia {
  const DrillMedia({required this.video, this.poster});

  final File video;
  final File? poster;
}

/// Shared stand-in for lesson, trailer, and welcome video until real footage exists.
/// The clip has "PLACEHOLDER VIDEO" burned into it so it cannot ship unnoticed.
const placeholderLessonMediaPath = 'drills/placeholder-lesson.mp4';

abstract class DrillMediaSource {
  /// Returns the cached files for a Storage video path, downloading them first if needed.
  /// Returns null when there is no hosted video or it cannot be fetched.
  Future<DrillMedia?> load(String videoPath);

  /// Warms the cache so the video is ready when the player gets to it.
  Future<void> prefetch(String videoPath);
}

/// Downloads drill demos from Firebase Storage once and serves them from disk after that,
/// so a drill you have already seen plays offline.
class FirebaseDrillMediaSource implements DrillMediaSource {
  FirebaseDrillMediaSource({
    Future<void> Function(String remotePath, File destination)? downloader,
    Future<String?> Function(String remotePath)? versionLookup,
    Future<Directory> Function()? cacheDirectory,
  }) : _downloader = downloader ?? _downloadFromStorage,
       _versionLookup = versionLookup ?? _versionFromStorage,
       _cacheDirectory = cacheDirectory ?? _defaultCacheDirectory;

  final Future<void> Function(String remotePath, File destination) _downloader;
  final Future<String?> Function(String remotePath) _versionLookup;
  final Future<Directory> Function() _cacheDirectory;
  final _checkedThisRun = <String>{};
  final _inFlight = <String, Future<File?>>{};

  static Future<Directory> _defaultCacheDirectory() async {
    final root = await getApplicationSupportDirectory();
    return Directory('${root.path}/drill_media').create(recursive: true);
  }

  static Future<void> _downloadFromStorage(String remotePath, File destination) => FirebaseStorage.instance.ref(remotePath).writeToFile(destination);

  /// A value that changes whenever the uploaded file's content changes.
  static Future<String?> _versionFromStorage(String remotePath) async {
    final metadata = await FirebaseStorage.instance.ref(remotePath).getMetadata();
    return metadata.md5Hash ?? metadata.updated?.toIso8601String();
  }

  static bool hasRemoteMedia(String videoPath) => videoPath.startsWith('drills/');

  static String posterPath(String videoPath) => '${videoPath.substring(0, videoPath.length - 4)}.jpg';

  @override
  Future<DrillMedia?> load(String videoPath) async {
    if (!hasRemoteMedia(videoPath)) return null;
    final video = await _fetch(videoPath);
    if (video == null) return null;
    return DrillMedia(video: video, poster: await _fetch(posterPath(videoPath)));
  }

  @override
  Future<void> prefetch(String videoPath) async {
    if (!hasRemoteMedia(videoPath)) return;
    await _fetch(videoPath);
    await _fetch(posterPath(videoPath));
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
    if (await file.exists() && await file.length() > 0) {
      // Serve what is on disk right away; a replaced upload is picked up in the background.
      if (_checkedThisRun.add(remotePath)) unawaited(_refreshIfChanged(remotePath, file));
      return file;
    }
    return _fetchTo(remotePath, file);
  }

  File _versionFile(File file) => File('${file.path}.version');

  Future<File?> _fetchTo(String remotePath, File file) async {
    final partial = File('${file.path}.part');
    try {
      await _downloader(remotePath, partial);
      final saved = await partial.rename(file.path);
      final version = await _versionLookup(remotePath).catchError((Object _) => null);
      if (version != null) await _versionFile(file).writeAsString(version);
      return saved;
    } on Object {
      // Offline, missing, or interrupted: callers fall back to the illustrated placeholder.
      if (await partial.exists()) await partial.delete();
      return null;
    }
  }

  Future<void> _refreshIfChanged(String remotePath, File file) async {
    try {
      final remote = await _versionLookup(remotePath);
      if (remote == null) return;
      final versionFile = _versionFile(file);
      final local = await versionFile.exists() ? await versionFile.readAsString() : null;
      if (local == remote) return;
      final partial = File('${file.path}.part');
      await _downloader(remotePath, partial);
      await partial.rename(file.path);
      await versionFile.writeAsString(remote);
    } on Object {
      // Offline or interrupted: keep the cached copy.
    }
  }
}

final drillMediaSourceProvider = Provider<DrillMediaSource>((ref) => FirebaseDrillMediaSource());

final drillMediaProvider = FutureProvider.family<DrillMedia?, String>((ref, videoPath) => ref.watch(drillMediaSourceProvider).load(videoPath));
