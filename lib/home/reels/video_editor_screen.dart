// ignore_for_file: unused_element

import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:trace/helpers/quick_help.dart';
import 'package:trace/home/reels/video_crop_screen.dart';
import 'package:trace/models/others/video_editor_model.dart';
import 'package:trace/ui/container_with_corner.dart';
import 'package:trace/utils/colors.dart';
import 'package:video_editor/video_editor.dart';

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
    super.initState();

    _controller = VideoEditorController.file(
      widget.file,
      maxDuration: const Duration(minutes: 3),
      cropStyle: CropGridStyle(),
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
      ),
    )..initialize().then((_) => setState(() {}));
  }

  @override
  void dispose() {
    _exportingProgress.dispose();
    _isExporting.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _openCropScreen() => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => CropScreen(controller: _controller),
        ),
      );

  /// ✅ تصدير الفيديو + الكوفر (video_editor 3.x)
  Future<void> _exportVideo() async {
    _exportingProgress.value = 0;
    _isExporting.value = true;

    try {
      final File videoFile = await _controller.exportVideo();
      final cover = await _controller.extractCoverFrame();

      if (!mounted || cover == null) return;

      VideoEditorModel model = VideoEditorModel();
      model.setVideoFile(videoFile);
      model.setCoverPath(cover.path);

      _exportText = "Video success export!";
      setState(() => _exported = true);

      _isExporting.value = false;

      QuickHelp.goBackToPreviousPage(context, result: model);
    } catch (e) {
      _isExporting.value = false;
      _exportText = "Error on export video :(";
      setState(() {});
    }
  }

  /// ✅ تصدير الكوفر فقط
  Future<void> _exportCover() async {
    setState(() => _exported = false);

    try {
      final cover = await _controller.extractCoverFrame();

      if (!mounted || cover == null) return;

      _exportText = "Cover exported! ${cover.path}";

      showDialog(
        context: context,
        builder: (_) => Padding(
          padding: const EdgeInsets.all(30),
          child: Center(
            child: Image.memory(cover.readAsBytesSync()),
          ),
        ),
      );

      setState(() => _exported = true);

      Future.delayed(
        const Duration(seconds: 2),
        () => setState(() => _exported = false),
      );
    } catch (e) {
      _exportText = "Error on cover exportation :(";
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return ToolBar(
      title: "page_title.reels_edit_video".tr(),
      centerTitle: QuickHelp.isAndroidPlatform(),
      leftButtonIcon: Icons.arrow_back_ios,
      onLeftButtonTap: () => QuickHelp.goBackToPreviousPage(context),
      rightButtonIcon: Icons.crop_rotate,
      rightButtonPress: _openCropScreen,
      rightButtonTwoIcon: Icons.check_sharp,
      rightButtonTwoPress: _exportVideo,
      backgroundColor:
          QuickHelp.isDarkModeNoContext() ? null : kColorsGrey300.withOpacity(0.5),
      child: _controller.initialized
          ? ContainerCorner(
              color: QuickHelp.isDarkModeNoContext()
                  ? null
                  : kColorsGrey300.withOpacity(0.5),
              padding: const EdgeInsets.only(top: 10),
              child: Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: DefaultTabController(
                          length: 2,
                          child: Column(
                            children: [
                              Expanded(
                                child: TabBarView(
                                  physics:
                                      const NeverScrollableScrollPhysics(),
                                  children: [
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        CropGridViewer.edit(
                                          controller: _controller,
                                        ),
                                        AnimatedBuilder(
                                          animation: _controller.video,
                                          builder: (_, __) =>
                                              OpacityTransition(
                                            visible: !_controller.isPlaying,
                                            child: GestureDetector(
                                              onTap: _controller.video.play,
                                              child: Container(
                                                width: 40,
                                                height: 40,
                                                decoration:
                                                    const BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.play_arrow,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    CoverViewer(controller: _controller),
                                  ],
                                ),
                              ),
                              _customSnackBar(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : Center(child: QuickHelp.showLoadingAnimation()),
    );
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
            child: Text(
              _exportText,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
