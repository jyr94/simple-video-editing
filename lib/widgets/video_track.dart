import 'package:flutter/material.dart';

import '../models/video_clip.dart';
import 'timeline_clip.dart';

class VideoTrack extends StatelessWidget {
  final List<VideoClip> clips;
  final int selectedIndex;
  final ValueChanged<int>? onSelectClip;
  final void Function(int from, int to)? onReorderClip;
  final VoidCallback? onAppendClip;
  final ValueChanged<int>? onRemoveClip;
  final double height;

  const VideoTrack({
    super.key,
    required this.clips,
    required this.selectedIndex,
    this.onSelectClip,
    this.onReorderClip,
    this.onAppendClip,
    this.onRemoveClip,
    this.height = 80,
  });

  Widget _buildDraggableClip(BuildContext context, int index) {
    final clip = clips[index];
    return Draggable<Map<String, int>>(
      data: {'index': index},
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Material(
        borderRadius: BorderRadius.circular(8),
        child: TimelineClip(clip: clip, selected: true),
      ),
      childWhenDragging: const SizedBox(width: 116),
      child: GestureDetector(
        onTap: () => onSelectClip?.call(index),
        onDoubleTap: () => onRemoveClip?.call(index),
        child: TimelineClip(
          clip: clip,
          selected: selectedIndex == index,
        ),
      ),
    );
  }

  Widget _buildDragTarget(int index, Widget child) {
    return DragTarget<Map<String, int>>(
      onWillAccept: (from) => from!['index'] != index,
      onAccept: (from) => onReorderClip?.call(from['index']!, index),
      builder: (context, candidate, rejected) => child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: clips.length + 1,
        itemBuilder: (context, index) {
          if (index == clips.length) {
            return _buildDragTarget(
              index,
              GestureDetector(
                onTap: onAppendClip,
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade300,
                  ),
                  child: const Icon(Icons.add),
                ),
              ),
            );
          }
          return _buildDragTarget(
            index,
            _buildDraggableClip(context, index),
          );
        },
      ),
    );
  }
}

