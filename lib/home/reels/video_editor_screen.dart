// ignore_for_file: unused_element

import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:juodylive/helpers/quick_help.dart';
import 'package:juodylive/home/reels/video_crop_screen.dart';
import 'package:juodylive/models/others/video_editor_model.dart';
import 'package:juodylive/ui/container_with_corner.dart';
import 'package:juodylive/utils/colors.dart';
import 'package:video_editor/video_editor.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit.dart';

import '../../ui/app_bar.dart';
import '../../ui/text_with_tap.dart';
import '../../utils/helpers/transition.dart';

class VideoEditorScreen extends StatefulWidget {
  const VideoEditorScreen({Key? key, required this.file}) : super(key: key);

  final File file;

  @override
  State<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen> {
  final _exportingProgress = ValueNotifier<double>(0.0);
  final _isExporting = ValueNotifier<bool>(false);
  final double height = 60;

  bool _exported = false;
  String _exportText = "";
  late VideoEditorController _controller;

  @override
  void initState() {
    _controller = VideoEditorController.file(widget.file,
        maxDuration: const Duration(minutes: 3),
      cropStyle: CropGridStyle(
        //croppingBackground: Colors.black45,
        //background: kTransparentColor,
        //boundariesColor: kTransparentColor
      ),
      coverStyle: CoverSelectionStyle(
        selectedBorderColor: Colors.white,
        borderWidth: 2,
        borderRadius: 5,
      ),
      trimStyle: TrimSliderStyle(
        background: kTransparentColor,
        edgesType: TrimSliderEdgesType.bar,
        positionLineWidth: 8,
        lineWidth: 4,
        onTrimmedColor: kPrimaryColor,
        onTrimmingColor: kPrimaryColor,
      )
    )..initialize().then((_) => setState(() {}));

    super.initState();
  }

    @override
  void dispose() {
    _exportingProgress.dispose();
    _isExporting.dispose();
    _controller.dispose();
    super.dispose();
  }

  // --- هذا هو الجزء الذي كان مفقوداً ويسبب الخطأ الحالي ---
  void _openCropScreen() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => CropScreen(controller: _controller),
      ),
    );
  }
  // -------------------------------------------------------

  Future<void> _exportVideo() async {
    _exportingProgress.value = 0;
    _isExporting.value = true;

    // إعدادات الفيديو
    final videoConfig = VideoFFmpegVideoEditorConfig(_controller);
    final videoExecute = await videoConfig.getExecuteConfig();

    // التحقق من أن إعدادات الفيديو ليست فارغة (Null Safety)
    if (videoExecute == null) {
      _isExporting.value = false;
      if (mounted) setState(() => _exportText = "Error: Video config is null");
      return;
    }

    await FFmpegKit.executeAsync(
      videoExecute.command,
      (session) async {
        final returnCode = await session.getReturnCode();

        if (returnCode != null && returnCode.getValue() == 0) {
          _isExporting.value = false;
          final File videoFile = File(videoExecute.outputPath);

          try {
            // إعدادات الغلاف
            final coverConfig = CoverFFmpegVideoEditorConfig(_controller);
            final coverExecute = await coverConfig.getExecuteConfig();

            // التحقق من أن إعدادات الغلاف ليست فارغة
            if (coverExecute == null) {
               if (mounted) {
                 VideoEditorModel videoEditorModel = VideoEditorModel();
                 videoEditorModel.setVideoFile(videoFile);
                 Navigator.of(context).pop(videoEditorModel);
               }
               return;
            }

            // تنفيذ أمر الغلاف
            await FFmpegKit.executeAsync(
              coverExecute.command,
              (coverSession) async {
                final coverReturnCode = await coverSession.getReturnCode();

                if (coverReturnCode != null && coverReturnCode.getValue() == 0) {
                  final File coverFile = File(coverExecute.outputPath);

                  if (!mounted) return;

                  VideoEditorModel videoEditorModel = VideoEditorModel();
                  videoEditorModel.setCoverPath(coverFile.path);
                  videoEditorModel.setVideoFile(videoFile);

                  Navigator.of(context).pop(videoEditorModel);
                } else {
                  // فشل الغلاف، نعيد الفيديو فقط
                  if (mounted) {
                    VideoEditorModel videoEditorModel = VideoEditorModel();
                    videoEditorModel.setVideoFile(videoFile);
                    Navigator.of(context).pop(videoEditorModel);
                  }
                }
              },
            );
          } catch (e) {
            debugPrint("Error processing cover: $e");
            if (mounted) {
               VideoEditorModel videoEditorModel = VideoEditorModel();
               videoEditorModel.setVideoFile(videoFile);
               Navigator.of(context).pop(videoEditorModel);
            }
          }

          if (mounted) {
            setState(() {
              _exportText = "Video success export!";
              _exported = true;
            });
          }
        } else {
          _isExporting.value = false;
          if (mounted) {
            setState(() => _exportText = "Error on export video :(");
          }
        }
      },
      (log) => debugPrint(log.getMessage()),
      (statistics) {
        final duration = _controller.videoDuration.inMilliseconds;
        if (duration > 0) {
          final double progress = statistics.getTime() / duration;
          _exportingProgress.value = progress.clamp(0.0, 1.0);
        }
      },
    );
  }

  void _exportCover() async {
    setState(() => _exported = false);
    
    try {
      final coverConfig = CoverFFmpegVideoEditorConfig(_controller);
      final coverExecute = await coverConfig.getExecuteConfig();

      if (coverExecute == null) {
        if (mounted) setState(() => _exportText = "Error: Cover config is null");
        return;
      }

      await FFmpegKit.executeAsync(
        coverExecute.command,
        (session) async {
          final returnCode = await session.getReturnCode();

          if (returnCode != null && returnCode.getValue() == 0) {
            final File coverFile = File(coverExecute.outputPath);

            if (!mounted) return;

            setState(() {
              _exportText = "Cover exported! ${coverFile.path}";
              _exported = true;
            });

            showDialog(
              context: context,
              builder: (_) => Padding(
                padding: const EdgeInsets.all(30),
                child: Center(child: Image.file(coverFile)),
              ),
            );

            Future.delayed(const Duration(seconds: 2),
                () => setState(() => _exported = false));
          } else {
            if (mounted) setState(() => _exportText = "Error on cover exportation :(");
          }
        }
      );
    } catch (e) {
      if (mounted) {
        setState(() => _exportText = "Error on cover exportation :(");
      }
    }
  }
  
  
  @override
  Widget build(BuildContext context) {

    return ToolBar(
      title: "page_title.reels_edit_video".tr(),
      centerTitle: QuickHelp.isAndroidPlatform() ? true : false,
      leftButtonIcon: Icons.arrow_back_ios,
      onLeftButtonTap: () => QuickHelp.goBackToPreviousPage(context),
      rightButtonIcon: Icons.crop_rotate,
      rightButtonPress: _openCropScreen,
      rightButtonTwoIcon: Icons.check_sharp,
      rightButtonTwoPress: _exportVideo,
      backgroundColor: QuickHelp.isDarkModeNoContext() ? null : kColorsGrey300.withOpacity(0.5),
      child: _controller.initialized
          ? ContainerCorner(
         color: QuickHelp.isDarkModeNoContext() ? null : kColorsGrey300.withOpacity(0.5),
              padding: EdgeInsets.only(top: 10),
            child: Stack(children: [
              Column(children: [
                //_topNavBar(),
                Expanded(
                    child: DefaultTabController(
                        length: 2,
                        child: Column(children: [
                          Expanded(
                              child: TabBarView(
                                physics: const NeverScrollableScrollPhysics(),
                                children: [
                                  Stack(alignment: Alignment.center, children: [
                                    CropGridViewer.edit(
                                      controller: _controller,
                                      //showGrid: false,
                                    ),
                                    AnimatedBuilder(
                                      animation: _controller.video,
                                      builder: (_, __) => OpacityTransition(
                                        visible: !_controller.isPlaying,
                                        child: GestureDetector(
                                          onTap: _controller.video.play,
                                          child: Container(
                                            width: 40,
                                            height: 40,
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.play_arrow,
                                                color: Colors.black),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ]),
                                  CoverViewer(controller: _controller)
                                ],
                              )),
                          ContainerCorner(
                              color: kPrimacyGrayColor.withOpacity(0.2),
                              radiusTopRight: 30,
                              radiusTopLeft: 30,
                              height: 200,
                              marginTop: 10,
                              child: Column(children: [
                                TabBar(
                                  indicatorColor: Colors.white,
                                  tabs: [
                                    Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          Padding(
                                              padding: EdgeInsets.all(5),
                                              child: Icon(Icons.cut_rounded)),
                                          Text('video_editor.video_editor_trim').tr()
                                        ]),
                                    Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          Padding(
                                              padding: EdgeInsets.all(5),
                                              child: Icon(Icons.video_label_rounded)),
                                          Text('video_editor.video_editor_cover').tr()
                                        ],
                                    ),
                                  ],
                                ),
                                Expanded(
                                  child: TabBarView(
                                    children: [
                                      Column(
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          children: _trimSlider()),
                                      Column(
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          children: [_coverSelection()]),
                                    ],
                                  ),
                                )
                              ])),
                          _customSnackBar(),
                          ValueListenableBuilder(
                            valueListenable: _isExporting,
                            builder: (_, bool export, __) => OpacityTransition(
                              visible: export,
                              child: AlertDialog(
                                backgroundColor: Colors.white,
                                title: ValueListenableBuilder(
                                  valueListenable: _exportingProgress,
                                  builder: (_, double value, __) => Text("video_editor.video_editor_rendering",
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ).tr(namedArgs: {"percent" : "${(value * 100).ceil()}"}),
                                ),
                              ),
                            ),
                          )
                        ])))
              ])
            ]),
          )
          : Center(child: QuickHelp.showLoadingAnimation()),
    );
  }

  Widget _topNavBar() {
    return SafeArea(
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            Expanded(
              child: IconButton(
                onPressed: () =>
                    _controller.rotate90Degrees(RotateDirection.left),
                icon: const Icon(Icons.rotate_left, color: Colors.white),
              ),
            ),
            Expanded(
              child: IconButton(
                onPressed: () =>
                    _controller.rotate90Degrees(RotateDirection.right),
                icon: const Icon(Icons.rotate_right, color: Colors.white),
              ),
            ),
            Expanded(
              child: IconButton(
                onPressed: _openCropScreen,
                icon: const Icon(Icons.crop_rotate, color: Colors.white),
              ),
            ),
            Expanded(
              child: IconButton(
                onPressed: _exportCover,
                icon: const Icon(Icons.save_alt, color: Colors.white),
              ),
            ),
           /* Expanded(
              child: IconButton(
                onPressed: _exportVideo,
                icon: const Icon(Icons.save, color: Colors.white),
              ),
            ),*/
          ],
        ),
      ),
    );
  }

  String formatter(Duration duration) => [
        duration.inMinutes.remainder(60).toString().padLeft(2, '0'),
        duration.inSeconds.remainder(60).toString().padLeft(2, '0')
      ].join(":");

  List<Widget> _trimSlider() {
    return [
      AnimatedBuilder(
        animation: _controller.video,
        builder: (_, __) {
          final duration = _controller.video.value.duration.inSeconds;
          final pos = _controller.trimPosition * duration;
          final start = _controller.minTrim * duration;
          final end = _controller.maxTrim * duration;

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: height / 4),
            child: Row(children: [
              TextWithTap(formatter(Duration(seconds: pos.toInt())), color: null,),
              const Expanded(child: SizedBox()),
              OpacityTransition(
                visible: true, //_controller.isTrimming,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  TextWithTap(formatter(Duration(seconds: start.toInt())), color: Colors.red,),
                  const SizedBox(width: 10),
                  TextWithTap(formatter(Duration(seconds: end.toInt())), color: null,),
                ]),
              )
            ]),
          );
        },
      ),
      Container(
        //color: kTransparentColor,
        width: MediaQuery.of(context).size.width,
        margin: EdgeInsets.symmetric(vertical: height / 4),
        child: TrimSlider(
            controller: _controller,
            height: height,
            horizontalMargin: height / 4,
            child: TrimTimeline(
              textStyle: TextStyle(color: null),
                controller: _controller,
                padding: const EdgeInsets.only(top: 10, bottom: 10))),
      )
    ];
  }

  Widget _coverSelection() {
    return Container(
        margin: EdgeInsets.symmetric(horizontal: height / 4),
        child: CoverSelection(
          controller: _controller,
          //height: height,
          quantity: 8,
        ));
  }

  Widget _customSnackBar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SwipeTransition(
        visible: _exported,
        axisAlignment: 1.0,
        child: Container(
          height: height,
          width: double.infinity,
          color: Colors.black.withOpacity(0.8),
          child: Center(
            child: Text(_exportText,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}
