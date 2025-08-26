import 'dart:typed_data';

import 'package:flutter/foundation.dart';

enum TransitionType { none, fade, slide }

enum ClipType { video, audio, text }

class VideoClip {
  final String? path;
  final Duration duration;
  final Uint8List? thumbnail;
  final Uint8List? waveform;
  final ClipType type;
  final String? text;
  TransitionType transition;
  Duration start;
  Duration end;

  VideoClip({
    this.path,
    required this.duration,
    this.thumbnail,
    this.waveform,
    this.type = ClipType.video,
    this.text,
    this.transition = TransitionType.none,
    Duration? start,
    Duration? end,
  })  : start = start ?? Duration.zero,
        end = end ?? duration;
}
