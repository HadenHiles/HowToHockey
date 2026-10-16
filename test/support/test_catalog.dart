import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:how_to_hockey/features/drills/drill_catalog.dart';

/// Widget tests cannot finish real asset I/O under fake time, so they read the
/// same catalog file from disk and provide it directly.
final testCatalogOverride = drillCatalogProvider.overrideWithValue(AsyncData(parseDrillCatalog(File(drillCatalogAsset).readAsStringSync())));
