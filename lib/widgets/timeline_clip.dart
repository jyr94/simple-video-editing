import 'package:flutter/material.dart';

import '../models/video_clip.dart';

class TimelineClip extends StatelessWidget {
  final VideoClip clip;
  final bool selected;

  const TimelineClip({super.key, required this.clip, this.selected = false});

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(
          color: selected ? Colors.teal : Colors.transparent,
          width: 3,
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
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                _formatDuration(clip.duration),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
