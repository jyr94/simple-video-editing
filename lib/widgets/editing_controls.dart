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
    final duration = controller.videoDuration;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Slider trim bawaan package
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TrimSlider(
              controller: controller,
              height: 48,
            ),
          ),

          // Info kecil
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Duration: ${duration.inSeconds}s | '
              'Trim: ${controller.startTrim.inSeconds}s - ${controller.endTrim.inSeconds}s',
              style: const TextStyle(fontSize: 12),
            ),
          ),

          // Tombol contoh set trim cepat
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton(
                onPressed: () {
                  // Contoh: set 0s - 5s
                  context.read<VideoEditorBloc>().add(
                        TrimVideo(
                          start: const Duration(seconds: 0),
                          end: const Duration(seconds: 5),
                        ),
                      );
                },
                child: const Text('Trim 0s–5s'),
              ),
              const SizedBox(width: 12),
              FilledButton.tonal(
                onPressed: () {
                  // Contoh: set 5s – 10s (dibatasi oleh total durasi)
                  final end =
                      duration.inSeconds >= 10 ? 10 : duration.inSeconds;
                  if (end > 5) {
                    context.read<VideoEditorBloc>().add(
                          TrimVideo(
                            start: const Duration(seconds: 5),
                            end: Duration(seconds: end),
                          ),
                        );
                  }
                },
                child: const Text('Trim 5s–10s'),
              ),
            ],
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
