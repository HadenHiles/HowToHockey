import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'share_card.dart';

/// Turns the card on screen into a PNG at full size. Nothing is sent anywhere.
Future<Uint8List> renderShareImage(RenderRepaintBoundary boundary, ShareFormat format) async {
  final image = await boundary.toImage(pixelRatio: format.pixelRatio);
  try {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) throw StateError('The picture couldn\'t be made.');
    return bytes.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}

/// Hands a finished picture to the phone's share sheet.
abstract class ShareService {
  /// [origin] is where the share sheet points from on iPad.
  Future<void> shareImage(Uint8List png, {required String fileName, Rect? origin});
}

class SystemShareService implements ShareService {
  @override
  Future<void> shareImage(Uint8List png, {required String fileName, Rect? origin}) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(png, flush: true);
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          sharePositionOrigin: origin,
        ),
      );
    } finally {
      // The picture only lives long enough to be shared.
      if (file.existsSync()) await file.delete();
    }
  }
}

final shareServiceProvider = Provider<ShareService>((ref) => SystemShareService());
