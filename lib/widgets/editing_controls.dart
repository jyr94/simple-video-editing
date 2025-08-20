import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_editor/video_editor.dart';
import '../bloc/video_editor_bloc.dart';
import '../bloc/video_editor_event.dart';

class EditingControls extends StatelessWidget {
  final VideoEditorController controller;
  const EditingControls({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.content_cut),
          onPressed: () {
            final start = controller.trimPosition.start;
            final end = controller.trimPosition.end;
            context
                .read<VideoEditorBloc>()
                .add(TrimVideo(start: start, end: end));
          },
        ),
      ],
    );
  }
}
