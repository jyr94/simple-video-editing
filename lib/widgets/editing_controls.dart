import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_editor/video_editor.dart';
import 'package:video_player/video_player.dart';

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
      child: Container(
        color: Colors.grey[900],
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: controller.video,
              builder: (context, value, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        value.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        value.isPlaying
                            ? controller.video.pause()
                            : controller.video.play();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.replay, color: Colors.white),
                      onPressed: () => controller.video.seekTo(Duration.zero),
                    ),
                  ],
                );
              },
            ),

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
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ),

            // Tombol contoh set trim cepat
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: () {
                    context.read<VideoEditorBloc>().add(
                          TrimVideo(
                            start: const Duration(seconds: 0),
                            end: const Duration(seconds: 5),
                          ),
                        );
                  },
                  icon: const Icon(Icons.content_cut),
                  label: const Text('0–5s'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () {
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
                  icon: const Icon(Icons.content_cut),
                  label: const Text('5–10s'),
                ),
              ],
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
