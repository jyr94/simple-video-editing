import 'package:flutter/foundation.dart';

enum TransitionType { none, fade }

class VideoClip {
  final String path;
  final Duration duration;
  TransitionType transition;

  VideoClip({
    required this.path,
    required this.duration,
    this.transition = TransitionType.fade,
  });
}
