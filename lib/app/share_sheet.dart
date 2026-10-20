import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design/tokens/app_spacing.dart';
import '../features/share/share_card.dart';
import '../features/share/share_service.dart';

/// Shows the card the player is about to share, in either shape, with a Share button.
Future<void> showShareSheet(BuildContext context, {required ShareCardData data, required String fileStem}) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => _ShareSheet(data: data, fileStem: fileStem),
);

class _ShareSheet extends ConsumerStatefulWidget {
  const _ShareSheet({required this.data, required this.fileStem});

  final ShareCardData data;
  final String fileStem;

  @override
  ConsumerState<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends ConsumerState<_ShareSheet> {
  final _boundary = GlobalKey();
  final _button = GlobalKey();
  var _format = ShareFormat.story;
  var _busy = false;
  String? _error;

  Future<void> _share() async {
    final boundary = _boundary.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final box = _button.currentContext?.findRenderObject() as RenderBox?;
    final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    final service = ref.read(shareServiceProvider);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final png = await renderShareImage(boundary, _format);
      await service.shareImage(png, fileName: '${widget.fileStem}-${_format.name}.png', origin: origin);
    } on Object {
      if (mounted) setState(() => _error = 'We couldn\'t make the picture. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxHeight = MediaQuery.sizeOf(context).height * .5;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.screen),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Share your work', style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            const Text('The picture is made on your phone. Nothing is uploaded.'),
            const SizedBox(height: AppSpacing.md),
            SegmentedButton<ShareFormat>(
              segments: [for (final format in ShareFormat.values) ButtonSegment(value: format, label: Text(format.label))],
              selected: {_format},
              onSelectionChanged: _busy ? null : (selection) => setState(() => _format = selection.first),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: FittedBox(
                  child: RepaintBoundary(
                    key: _boundary,
                    child: ShareCard(data: widget.data, format: _format),
                  ),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Semantics(
                liveRegion: true,
                child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(key: _button, onPressed: _busy ? null : _share, icon: const Icon(Icons.ios_share), label: Text(_busy ? 'Making your picture…' : 'Share')),
          ],
        ),
      ),
    );
  }
}
