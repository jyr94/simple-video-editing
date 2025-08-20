import 'package:flutter/material.dart';
import 'package:video_editor/video_editor.dart';

class VideoPreview extends StatelessWidget {
  final VideoEditorController controller;
  const VideoPreview({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return VideoEditor(
      controller: controller,
      child: CoverViewer(controller: controller),
    );
  }
}
