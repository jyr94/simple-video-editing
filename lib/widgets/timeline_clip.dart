import 'package:flutter/material.dart';

import '../models/video_clip.dart';

class TimelineClip extends StatelessWidget {
  final VideoClip clip;
  final bool selected;
  final void Function(Duration newStart, Duration newEnd)? onTrim;

  const TimelineClip({
    super.key,
    required this.clip,
    this.selected = false,
    this.onTrim,
  });

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    const double width = 100;
    return Container(
      width: width,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(
          color: selected ? Colors.white : Colors.transparent,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (clip.thumbnail != null)
            Image.memory(clip.thumbnail!, fit: BoxFit.cover),
          if (clip.type == ClipType.text)
            Center(
              child: Text(
                clip.text ?? '',
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          if (clip.waveform != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Image.memory(
                clip.waveform!,
                fit: BoxFit.cover,
                height: 20,
                width: double.infinity,
              ),
            ),
          if (selected)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanUpdate: (details) {
                  final totalMs = clip.duration.inMilliseconds;
                  final deltaMs =
                      (details.delta.dx / width * totalMs).round();
                  var newStart = clip.start.inMilliseconds + deltaMs;
                  newStart = newStart.clamp(0, clip.end.inMilliseconds - 1) as int;
                  onTrim?.call(
                    Duration(milliseconds: newStart),
                    clip.end,
                  );
                },
                child: Container(
                  width: 8,
                  color: Colors.white24,
                ),
              ),
            ),
          if (selected)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanUpdate: (details) {
                  final totalMs = clip.duration.inMilliseconds;
                  final deltaMs =
                      (details.delta.dx / width * totalMs).round();
                  var newEnd = clip.end.inMilliseconds + deltaMs;
                  newEnd = newEnd.clamp(
                    clip.start.inMilliseconds + 1,
                    clip.duration.inMilliseconds,
                  ) as int;
                  onTrim?.call(
                    clip.start,
                    Duration(milliseconds: newEnd),
                  );
                },
                child: Container(
                  width: 8,
                  color: Colors.white24,
                ),
              ),
            ),
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                _formatDuration(clip.end - clip.start),
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
