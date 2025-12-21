
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:zego_express_engine/zego_express_engine.dart';
import 'package:zego_uikit/zego_uikit.dart';

class GiftMp4Player implements ZegoUIKitMediaEventInterface {
  static final GiftMp4Player _instance = GiftMp4Player._internal();
  factory GiftMp4Player() => _instance;
  GiftMp4Player._internal();

  bool _registerToUIKit = false;

  Widget? _mediaPlayerWidget;
  ZegoMediaPlayer? _mediaPlayer;
  int _mediaPlayerViewID = -1;

  /// callbacks
  void Function(ZegoMediaPlayerState state, int errorCode)? _onMediaPlayerStateUpdate;
  void Function(ZegoMediaPlayerFirstFrameEvent event)? _onMediaPlayerFirstFrameEvent;

  void registerCallbacks({
    Function(ZegoMediaPlayerState state, int errorCode)? onMediaPlayerStateUpdate,
    Function(ZegoMediaPlayerFirstFrameEvent event)? onMediaPlayerFirstFrameEvent,
  }) {
    if (!_registerToUIKit) {
      ZegoUIKit().registerMediaEvent(_instance);
      _registerToUIKit = true;
    }

    _onMediaPlayerStateUpdate = onMediaPlayerStateUpdate;
    _onMediaPlayerFirstFrameEvent = onMediaPlayerFirstFrameEvent;
  }

  void unregisterCallbacks() {
    _onMediaPlayerStateUpdate = null;
    _onMediaPlayerFirstFrameEvent = null;
  }

  /// create media player
  Future<Widget?> createMediaPlayer() async {
    _mediaPlayer ??= await ZegoExpressEngine.instance.createMediaPlayer();

    // create widget
    if (_mediaPlayerViewID == -1) {
      _mediaPlayerWidget = await ZegoExpressEngine.instance.createCanvasView((viewID) {
        _mediaPlayerViewID = viewID;
        _mediaPlayer?.setPlayerCanvas(ZegoCanvas(viewID, alphaBlend: true));
      });
    }
    return _mediaPlayerWidget;
  }

  @override
  void onMediaPlayerStateUpdate(mediaPlayer, state, errorCode) {
    _onMediaPlayerStateUpdate?.call(state, errorCode);
  }

  @override
  void onMediaPlayerFirstFrameEvent(mediaPlayer, event) {
    _onMediaPlayerFirstFrameEvent?.call(event);
  }

  void destroyMediaPlayer() {
    if (_mediaPlayer != null) {
      ZegoExpressEngine.instance.destroyMediaPlayer(_mediaPlayer!);
      _mediaPlayer = null;
    }
    destroyPlayerView();
  }

  void destroyPlayerView() {
    if (_mediaPlayerViewID != -1) {
      ZegoExpressEngine.instance.destroyCanvasView(_mediaPlayerViewID);
      _mediaPlayerViewID = -1;
    }
  }

  void clearView() {
    _mediaPlayer?.clearView();
  }

  Future<int> loadResource(String url, {ZegoAlphaLayoutType layoutType = ZegoAlphaLayoutType.Left}) async {
    debugPrint('Mp4 Player loadResource: $url');
    int ret = -1;
    if (_mediaPlayer != null) {
      ZegoMediaPlayerResource source = ZegoMediaPlayerResource.defaultConfig();
      source.filePath = url;
      source.loadType = ZegoMultimediaLoadType.FilePath;
      source.alphaLayout = layoutType;
      var result = await _mediaPlayer!.loadResourceWithConfig(source);
      ret = result.errorCode;
    }
    return ret;
  }

  void startMediaPlayer() {
    if (_mediaPlayer != null) {
      _mediaPlayer!.start();
    }
  }

  void pauseMediaPlayer() {
    if (_mediaPlayer != null) {
      _mediaPlayer!.pause();
    }
  }

  void resumeMediaPlayer() {
    if (_mediaPlayer != null) {
      _mediaPlayer!.resume();
    }
  }

  void stopMediaPlayer() {
    if (_mediaPlayer != null) {
      _mediaPlayer!.stop();
    }
  }

  // ============================================================
  //   ❗️ التعديلات الجديدة الخاصة بـ ZegoUIKitMediaEventInterface
  // ============================================================

  @override
void onMediaDataPublisherFileClose(
  int errorCode,     // أضف هذا المتغير
  String path,      // وأضف هذا المتغير
) {
  // اترك الكود الداخلي كما هو
}
  

// السطر 134: تغيير نوع timestamp من int إلى String
  void onMediaDataPublisherFileDataBegin(
    ZegoMediaDataPublisher publisher, 
    String timestamp) {  // تغيير int إلى String
    
  }

// السطر 140: تغيير نوع duration من int إلى String
 void onMediaDataPublisherFileOpen(
    ZegoMediaDataPublisher publisher, 
    String duration) {  // تغيير int إلى String
    
  }

  // ============================================================

  @override
  void onMediaPlayerFrequencySpectrumUpdate(
      ZegoMediaPlayer mediaPlayer, List<double> spectrumList) {}

  @override
  void onMediaPlayerNetworkEvent(
      ZegoMediaPlayer mediaPlayer, ZegoMediaPlayerNetworkEvent networkEvent) {}

  @override
  void onMediaPlayerPlayingProgress(
      ZegoMediaPlayer mediaPlayer, int millisecond) {}

  @override
  void onMediaPlayerRecvSEI(ZegoMediaPlayer mediaPlayer, Uint8List data) {}

  @override
  void onMediaPlayerRenderingProgress(
      ZegoMediaPlayer mediaPlayer, int millisecond) {}

  @override
  void onMediaPlayerSoundLevelUpdate(
      ZegoMediaPlayer mediaPlayer, double soundLevel) {}

  @override
  void onMediaPlayerVideoSizeChanged(
      ZegoMediaPlayer mediaPlayer, int width, int height) {}
}
