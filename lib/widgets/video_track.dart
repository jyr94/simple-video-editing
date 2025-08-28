import 'package:flutter/material.dart';

import '../models/video_clip.dart';
import 'timeline_clip.dart';

class VideoTrack extends StatelessWidget {
  final List<VideoClip> clips;
  final int selectedIndex;
  final ValueChanged<int>? onSelect;
  final void Function(int from, int to)? onReorder;
  final VoidCallback? onAppend;
  final ValueChanged<int>? onRemove;
  final void Function(int index, Duration newStart, Duration newEnd)? onTrim;
  final double height;

  const VideoTrack({
    super.key,
    required this.clips,
    required this.selectedIndex,
    this.onSelect,
    this.onReorder,
    this.onAppend,
    this.onRemove,
    this.onTrim,
    this.height = 80,
  });

  Widget _buildDraggableClip(BuildContext context, int index) {
    final clip = clips[index];
    return LongPressDraggable<Map<String, int>>(
      data: {'index': index},
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Material(
        borderRadius: BorderRadius.circular(8),
        child: TimelineClip(clip: clip, selected: true),
      ),
      childWhenDragging: const SizedBox(width: 116),
      child: GestureDetector(
        onTap: () => onSelect?.call(index),
        onDoubleTap: () => onRemove?.call(index),
        child: TimelineClip(
          clip: clip,
          selected: selectedIndex == index,
          onTrim: (s, e) => onTrim?.call(index, s, e),
        ),
      ),
    );
  }

  Widget _buildDragTarget(int index, Widget child) {
    return DragTarget<Map<String, int>>(
      onWillAccept: (from) => from!['index'] != index,
      onAccept: (from) => onReorder?.call(from['index']!, index),
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
                onTap: onAppend,
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: const Color(0xFF2A2A2A),
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
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

