import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svga/flutter_svga.dart';

import '../gift_manager/gift_manager.dart';
import '../gift_manager/gift_extras.dart';

/// Overlay يُعرض فوق الغرفة عند استقبال تأثير دخول
class EntranceEffectOverlay extends StatefulWidget {
  const EntranceEffectOverlay({Key? key}) : super(key: key);

  @override
  State<EntranceEffectOverlay> createState() =>
      _EntranceEffectOverlayState();
}

class _EntranceEffectOverlayState extends State<EntranceEffectOverlay> {
  ZegoEntranceEffectItem? _current;

  @override
  void initState() {
    super.initState();
    ZegoGiftManager()
        .service
        .entranceEffectNotifier
        .addListener(_onNew);
  }

  @override
  void dispose() {
    ZegoGiftManager()
        .service
        .entranceEffectNotifier
        .removeListener(_onNew);
    super.dispose();
  }

  void _onNew() {
    final item =
        ZegoGiftManager().service.entranceEffectNotifier.value;
    if (item == null || !mounted) return;
    setState(() => _current = item);
  }

  void _onDone() {
    if (!mounted) return;
    setState(() => _current = null);
    ZegoGiftManager().service.entranceEffectNotifier.value = null;
  }

  @override
  Widget build(BuildContext context) {
    if (_current == null) return const SizedBox.shrink();

    final url = _current!.fileUrl;
    final isMp4 = url.toLowerCase().endsWith('.mp4');

    return Positioned.fill(
      child: IgnorePointer(
        child: isMp4
            ? _Mp4EntrancePlayer(
                key: ValueKey(url),
                url: url,
                onDone: _onDone,
              )
            : _SvgaEntrancePlayer(
                key: ValueKey(url),
                url: url,
                onDone: _onDone,
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SVGA player بسيط مباشر من URL
// ─────────────────────────────────────────────────────────────────────────────
class _SvgaEntrancePlayer extends StatefulWidget {
  final String url;
  final VoidCallback onDone;
  const _SvgaEntrancePlayer(
      {Key? key, required this.url, required this.onDone})
      : super(key: key);

  @override
  State<_SvgaEntrancePlayer> createState() =>
      _SvgaEntrancePlayerState();
}

class _SvgaEntrancePlayerState extends State<_SvgaEntrancePlayer>
    with SingleTickerProviderStateMixin {
  SVGAAnimationController? _ctrl;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bytes = await ZegoGiftManager()
        .cache
        .readFromURL(url: widget.url);
    if (!mounted) return;
    final entity = await SVGAParser().decodeFromBuffer(bytes);
    _ctrl = SVGAAnimationController(vsync: this)
      ..videoItem = entity
      ..forward().whenComplete(() {
        widget.onDone();
      });
    setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ctrl == null) return const SizedBox.shrink();
    return SizedBox.expand(
      child: SVGAImage(_ctrl!),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MP4 player بسيط مباشر من URL عبر VideoPlayer
// ─────────────────────────────────────────────────────────────────────────────
class _Mp4EntrancePlayer extends StatefulWidget {
  final String url;
  final VoidCallback onDone;
  const _Mp4EntrancePlayer(
      {Key? key, required this.url, required this.onDone})
      : super(key: key);

  @override
  State<_Mp4EntrancePlayer> createState() =>
      _Mp4EntrancePlayerState();
}

class _Mp4EntrancePlayerState extends State<_Mp4EntrancePlayer> {
  VideoPlayerController? _vpc;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // حاول الكاش أولاً
    String? filePath;
    try {
      final fi =
          await DefaultCacheManager().getFileFromCache(widget.url);
      filePath = fi?.file.path;
    } catch (_) {}

    if (filePath != null) {
      _vpc = VideoPlayerController.file(File(filePath));
    } else {
      _vpc = VideoPlayerController.networkUrl(
          Uri.parse(widget.url));
    }

    await _vpc!.initialize();
    if (!mounted) { _vpc!.dispose(); return; }

    _vpc!.addListener(() {
      if (!mounted) return;
      if (_vpc!.value.position >= _vpc!.value.duration &&
          _vpc!.value.duration > Duration.zero) {
        widget.onDone();
      }
    });

    await _vpc!.play();
    setState(() => _ready = true);
  }

  @override
  void dispose() {
    _vpc?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready || _vpc == null) return const SizedBox.shrink();
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _vpc!.value.size.width,
          height: _vpc!.value.size.height,
          child: VideoPlayer(_vpc!),
        ),
      ),
    );
  }
}
