import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:how_to_hockey/features/drills/drill_catalog.dart';
import 'package:how_to_hockey/features/drills/drill_media.dart';

/// Widget tests cannot finish real asset I/O under fake time, so they read the
/// same catalog file from disk and provide it directly.
final testCatalogOverride = drillCatalogProvider.overrideWithValue(AsyncData(parseDrillCatalog(File(drillCatalogAsset).readAsStringSync())));

class _NoMedia implements DrillMediaSource {
  @override
  Future<DrillMedia?> load(String videoPath) async => null;

  @override
  Future<void> prefetch(String videoPath) async {}
}

/// Keeps widget tests off Firebase Storage; drills simply show their illustrated placeholder.
final testMediaOverride = drillMediaSourceProvider.overrideWithValue(_NoMedia());
