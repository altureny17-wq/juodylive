import 'package:flutter/material.dart';
import 'package:flutter_svga/flutter_svga.dart';

import '../../../../models/GiftsModel.dart';
import '../gift_manager/gift_manager.dart';

class ZegoSvgaPlayerWidget extends StatefulWidget {
  const ZegoSvgaPlayerWidget({
    Key? key,
    required this.onPlayEnd,
    required this.giftItem,
    required this.count,
    this.size,
    this.textStyle,
  }) : super(key: key);

  final VoidCallback onPlayEnd;
  final GiftsModel giftItem;
  final int count;

  final Size? size;
  final TextStyle? textStyle;

  @override
  State<ZegoSvgaPlayerWidget> createState() => ZegoSvgaPlayerWidgetState();
}

class ZegoSvgaPlayerWidgetState extends State<ZegoSvgaPlayerWidget>
    with SingleTickerProviderStateMixin {

  SVGAAnimationController? animationController;
  final loadedNotifier = ValueNotifier<bool>(false);

  late Future<MovieEntity> movieEntity;

  double get fontSize => 15;

  Size get displaySize => widget.size != null
      ? Size(
          widget.size!.width - widget.count.toString().length * fontSize,
          widget.size!.height,
        )
      : MediaQuery.of(context).size;

  Size get countSize => Size(
        (widget.count.toString().length + 2) * fontSize * 1.2,
        fontSize + 2,
      );

  @override
  void initState() {
    super.initState();

    debugPrint('load ${widget.giftItem} begin:${DateTime.now()}');

    ZegoGiftManager()
        .cache
        .readFromURL(url: widget.giftItem.getFile!.url!)
        .then((byteData) {
      final parser = SVGAParser();
      movieEntity = parser.decodeFromBuffer(byteData);

      loadedNotifier.value = true;
    });
  }

  @override
  void dispose() {
    if (animationController?.isAnimating ?? false) {
      animationController?.stop();
      widget.onPlayEnd();
    }
    animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: loadedNotifier,
      builder: (context, isLoaded, _) {
        if (!isLoaded) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.red),
          );
        }

        return FutureBuilder<MovieEntity>(
          future: movieEntity,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              animationController ??= SVGAAnimationController(vsync: this)
                ..videoItem = snapshot.data!
                ..forward().whenComplete(() {
                  widget.onPlayEnd();
                });

              final countWidget = widget.count > 1
                  ? SizedBox.fromSize(
                      size: countSize,
                      child: Text(
                        'x ${widget.count}',
                        style: widget.textStyle ??
                            TextStyle(
                              fontSize: fontSize,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    )
                  : const SizedBox.shrink();

              if (displaySize.width <
                  MediaQuery.of(context).size.width) {
                return Row(
                  children: [
                    SizedBox.fromSize(
                      size: displaySize,
                      child: SVGAImage(animationController!),
                    ),
                    countWidget,
                  ],
                );
              }

              return SizedBox.fromSize(
                size: displaySize,
                child: Stack(
                  children: [
                    Center(
                      child: SizedBox.fromSize(
                        size: displaySize,
                        child: SVGAImage(animationController!),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: countWidget,
                    ),
                  ],
                ),
              );
            } else if (snapshot.hasError) {
              return Text('${snapshot.error}');
            } else {
              return const SizedBox();
            }
          },
        );
      },
    );
  }
}
