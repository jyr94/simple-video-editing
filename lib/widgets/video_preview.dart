import 'package:flutter/material.dart';
import 'package:video_editor/video_editor.dart';
import 'package:video_player/video_player.dart';

class VideoPreview extends StatelessWidget {
  final VideoEditorController controller;
  const VideoPreview({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    // VideoEditor menyediakan VideoViewer untuk playback
    return Container(
      color: Colors.black,
      child: Center(
        child: AspectRatio(
          aspectRatio: controller.video.value.aspectRatio == 0
              ? 16 / 9
              : controller.video.value.aspectRatio,
          child: VideoPlayer(controller.video),
        ),
      ),
    );
  }
}
