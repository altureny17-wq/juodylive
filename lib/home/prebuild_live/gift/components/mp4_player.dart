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

  // --- الدوال الجديدة المطلوبة لحل المشكلة ---
  // تم إضافتها لتتوافق مع تحديث ZegoUIKitMediaEventInterface

 
// هذا الكود يحل مشكلة السطر 126

 @override
 void onMediaDataPublisherFileClose(ZegoMediaDataPublisher publisher, [String? path]) {
  // يمكن أن يكون هناك معامل ثاني اختياري [String? path]
 }

  // السطر 133 (الذي كان يسبب خطأ fewer positional arguments)
 @override
 void onMediaDataPublisherFileDataBegin(ZegoMediaDataPublisher publisher, [String? path]) {
  // يمكن أن يكون هناك معامل ثاني اختياري [String? path]
 }




 @override
 void onMediaDataPublisherFileOpen(ZegoMediaDataPublisher publisher, String path) {
  // Implementation not needed for GiftMp4Player
 }
  

  // --- بقية الدوال الموجودة سابقاً ---

  @override
  void onMediaPlayerFrequencySpectrumUpdate(ZegoMediaPlayer mediaPlayer, List<double> spectrumList) {
    // TODO: implement onMediaPlayerFrequencySpectrumUpdate
  }

  @override
  void onMediaPlayerNetworkEvent(ZegoMediaPlayer mediaPlayer, ZegoMediaPlayerNetworkEvent networkEvent) {
    // TODO: implement onMediaPlayerNetworkEvent
  }

  @override
  void onMediaPlayerPlayingProgress(ZegoMediaPlayer mediaPlayer, int millisecond) {
    // TODO: implement onMediaPlayerPlayingProgress
  }

  @override
  void onMediaPlayerRecvSEI(ZegoMediaPlayer mediaPlayer, Uint8List data) {
    // TODO: implement onMediaPlayerRecvSEI
  }

  @override
  void onMediaPlayerRenderingProgress(ZegoMediaPlayer mediaPlayer, int millisecond) {
    // TODO: implement onMediaPlayerRenderingProgress
  }

  @override
  void onMediaPlayerSoundLevelUpdate(ZegoMediaPlayer mediaPlayer, double soundLevel) {
    // TODO: implement onMediaPlayerSoundLevelUpdate
  }

  @override
  void onMediaPlayerVideoSizeChanged(ZegoMediaPlayer mediaPlayer, int width, int height) {
    // TODO: implement onMediaPlayerVideoSizeChanged
  }
}
