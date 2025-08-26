import 'dart:typed_data';

import 'package:flutter/foundation.dart';

enum TransitionType { none, fade, slide }

class VideoClip {
  final String path;
  final Duration duration;
  final Uint8List? thumbnail;
  TransitionType transition;

  VideoClip({
    required this.path,
    required this.duration,
    this.thumbnail,
    this.transition = TransitionType.none,
  });
}
