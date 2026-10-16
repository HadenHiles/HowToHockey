import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../design/components/training_components.dart';
import '../design/tokens/app_colors.dart';
import '../design/tokens/app_shapes.dart';
import '../features/drills/drill_media.dart';
import '../features/drills/models/drill.dart';

/// Looping, muted video for a Storage path (a drill demo or the shared placeholder clip).
/// Falls back to the illustrated placeholder when there is no video or it cannot be loaded.
class DrillMediaCard extends ConsumerWidget {
  const DrillMediaCard({required this.title, required this.mediaPath, super.key});

  DrillMediaCard.forDrill(Drill drill, {Key? key}) : this(key: key, title: drill.title, mediaPath: drill.mediaAssetPath);

  final String title;
  final String mediaPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(drillMediaProvider(mediaPath))
      .when(
        data: (media) => media == null ? DrillMediaPlaceholder(title: title) : _DrillVideo(key: ValueKey(media.video.path), title: title, media: media),
        loading: () => _MediaFrame(
          child: Center(child: CircularProgressIndicator(semanticsLabel: 'Loading video for $title')),
        ),
        error: (_, _) => DrillMediaPlaceholder(title: title),
      );
}

class _MediaFrame extends StatelessWidget {
  const _MediaFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(AppRadii.card),
    child: AspectRatio(
      aspectRatio: 16 / 9,
      child: ColoredBox(color: AppColors.dark.background, child: child),
    ),
  );
}

class _DrillVideo extends StatefulWidget {
  const _DrillVideo({required this.title, required this.media, super.key});

  final String title;
  final DrillMedia media;

  @override
  State<_DrillVideo> createState() => _DrillVideoState();
}

class _DrillVideoState extends State<_DrillVideo> with WidgetsBindingObserver {
  late final VideoPlayerController _controller = VideoPlayerController.file(widget.media.video, videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true));
  var _ready = false;
  var _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller.addListener(_onChanged);
    _start();
  }

  Future<void> _start() async {
    try {
      await _controller.initialize();
      await _controller.setLooping(true);
      await _controller.setVolume(0);
      if (!mounted) return;
      setState(() => _ready = true);
      // People who reduce motion get a still poster until they choose to play.
      if (!MediaQuery.disableAnimationsOf(context)) await _controller.play();
    } on Object {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _ready) _controller.pause();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayback() => _controller.value.isPlaying ? _controller.pause() : _controller.play();

  @override
  Widget build(BuildContext context) {
    if (_failed || _controller.value.hasError) return DrillMediaPlaceholder(title: widget.title);
    final playing = _ready && _controller.value.isPlaying;
    return Semantics(
      button: true,
      label: '${widget.title} video. ${playing ? 'Playing. Double tap to pause.' : 'Paused. Double tap to play.'}',
      child: GestureDetector(
        onTap: _ready ? _togglePlayback : null,
        child: _MediaFrame(
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_ready)
                FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(width: _controller.value.size.width, height: _controller.value.size.height, child: VideoPlayer(_controller)),
                )
              else if (widget.media.poster != null)
                Image.file(widget.media.poster!, fit: BoxFit.cover, excludeFromSemantics: true),
              if (!_ready) const Center(child: CircularProgressIndicator()),
              if (_ready && !playing) Center(child: Icon(Icons.play_circle_fill, size: 56, color: AppColors.dark.brandCream)),
            ],
          ),
        ),
      ),
    );
  }
}
