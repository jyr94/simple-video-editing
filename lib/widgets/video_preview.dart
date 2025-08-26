import 'package:flutter/material.dart';
import 'package:video_editor/video_editor.dart';
import 'package:video_player/video_player.dart';

class VideoPreview extends StatefulWidget {
  final VideoEditorController controller;
  const VideoPreview({super.key, required this.controller});

  @override
  State<VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<VideoPreview> {
  double _scale = 1.0;

  String _format(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final minutes = two(d.inMinutes.remainder(60));
    final seconds = two(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final videoController = widget.controller.video;

    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: videoController,
      builder: (context, value, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final duration = value.duration;
            final position = value.position;

            final showHandles = widget.controller.startTrim > Duration.zero ||
                widget.controller.endTrim < widget.controller.videoDuration;

            final startPos = widget.controller.startTrim.inMilliseconds /
                widget.controller.videoDuration.inMilliseconds *
                width;
            final endPos = widget.controller.endTrim.inMilliseconds /
                widget.controller.videoDuration.inMilliseconds *
                width;

            return GestureDetector(
              onTap: () {
                value.isPlaying
                    ? videoController.pause()
                    : videoController.play();
              },
              onHorizontalDragUpdate: (details) {
                final relative = details.delta.dx / width;
                final newPosition = position.inMilliseconds +
                    duration.inMilliseconds * relative;
                final clamped = newPosition.clamp(
                  0,
                  duration.inMilliseconds.toDouble(),
                );
                videoController.seekTo(
                  Duration(milliseconds: clamped.toInt()),
                );
              },
              onScaleUpdate: (details) {
                setState(() {
                  _scale = details.scale.clamp(1.0, 5.0);
                });
              },
              child: Stack(
                children: [
                  Center(
                    child: AspectRatio(
                      aspectRatio:
                          value.aspectRatio == 0 ? 16 / 9 : value.aspectRatio,
                      child: Transform.scale(
                        scale: _scale,
                        child: VideoPlayer(videoController),
                      ),
                    ),
                  ),
                  Center(
                    child: Icon(
                      value.isPlaying
                          ? Icons.pause_circle
                          : Icons.play_circle,
                      color: Colors.white70,
                      size: 64,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        Slider(
                          value: position.inMilliseconds.toDouble(),
                          min: 0,
                          max: duration.inMilliseconds.toDouble(),
                          onChanged: (v) => videoController.seekTo(
                            Duration(milliseconds: v.toInt()),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '${_format(position)} / ${_format(duration)}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showHandles) ...[
                    Positioned(
                      bottom: 28,
                      left: startPos - 2,
                      child: Container(
                        width: 4,
                        height: 20,
                        color: Colors.white,
                      ),
                    ),
                    Positioned(
                      bottom: 28,
                      left: endPos - 2,
                      child: Container(
                        width: 4,
                        height: 20,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

