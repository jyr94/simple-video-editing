import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/video_clip.dart';

class MultiVideoEditorPage extends StatefulWidget {
  const MultiVideoEditorPage({super.key});

  @override
  State<MultiVideoEditorPage> createState() => _MultiVideoEditorPageState();
}

class _MultiVideoEditorPageState extends State<MultiVideoEditorPage> {
  final List<VideoClip> _clips = [];
  bool _isExporting = false;
  VideoPlayerController? _previewController;
  int _selectedIndex = 0;
  double _previewScale = 1.0;

  String _format(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final minutes = two(d.inMinutes.remainder(60));
    final seconds = two(d.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<void> _addVideos() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: true,
    );
    if (result != null) {
      for (final file in result.files) {
        final controller = VideoPlayerController.file(File(file.path!));
        await controller.initialize();
        _clips.add(
          VideoClip(
            path: file.path!,
            duration: controller.value.duration,
          ),
        );
        await controller.dispose();
      }
      _selectedIndex = 0;
      await _initPreview();
      setState(() {});
    }
  }

  Future<void> _initPreview() async {
    if (_clips.isEmpty) {
      await _previewController?.dispose();
      _previewController = null;
      return;
    }
    await _previewController?.dispose();
    final clip = _clips[_selectedIndex];
    _previewController = VideoPlayerController.file(File(clip.path));
    await _previewController!.initialize();
    setState(() {});
  }

  Future<void> _onSelectClip(int index) async {
    _selectedIndex = index;
    await _initPreview();
  }

  Future<void> _export() async {
    if (_clips.isEmpty || _isExporting) return;
    setState(() => _isExporting = true);

    final output = '${Directory.systemTemp.path}/output.mp4';
    final inputs = _clips.map((c) => "-i '${c.path}'").join(' ');

    String filter = '';
    String currentV = '[0:v]';
    String currentA = '[0:a]';
    double currentDur = _clips.first.duration.inSeconds.toDouble();

    for (var i = 1; i < _clips.length; i++) {
      final prev = _clips[i - 1];
      if (prev.transition == TransitionType.fade) {
        filter +=
            '$currentV$currentA[$i:v][$i:a]xfade=transition=fade:duration=1:offset=${currentDur - 1}[v$i][a$i];';
        currentV = '[v$i]';
        currentA = '[a$i]';
        currentDur += _clips[i].duration.inSeconds.toDouble() - 1;
      } else {
        filter +=
            '$currentV$currentA[$i:v][$i:a]concat=n=2:v=1:a=1[v$i][a$i];';
        currentV = '[v$i]';
        currentA = '[a$i]';
        currentDur += _clips[i].duration.inSeconds.toDouble();
      }
    }

    final cmd = _clips.length == 1
        ? "$inputs -c copy $output"
        : "$inputs -filter_complex \"$filter\" -map $currentV -map $currentA $output";

    await FFmpegKit.execute(cmd);
    setState(() => _isExporting = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Export complete: $output')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Editor'),
      ),
      body: _clips.isEmpty
          ? Center(
              child: ElevatedButton.icon(
                onPressed: _addVideos,
                icon: const Icon(Icons.video_library),
                label: const Text('Add Videos'),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: Center(
                    child: _previewController == null ||
                            !_previewController!.value.isInitialized
                        ? const Text('No clip selected')
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final controller = _previewController!;
                              return ValueListenableBuilder<VideoPlayerValue>(
                                valueListenable: controller,
                                builder: (context, value, child) {
                                  final duration = value.duration;
                                  final position = value.position;
                                  final width = constraints.maxWidth;

                                  return GestureDetector(
                                    onTap: () {
                                      value.isPlaying
                                          ? controller.pause()
                                          : controller.play();
                                    },
                                    onHorizontalDragUpdate: (details) {
                                      final relative = details.delta.dx / width;
                                      final newPosition = position.inMilliseconds +
                                          duration.inMilliseconds * relative;
                                      final clamped = newPosition.clamp(
                                        0,
                                        duration.inMilliseconds.toDouble(),
                                      );
                                      controller.seekTo(
                                        Duration(milliseconds: clamped.toInt()),
                                      );
                                    },
                                    onScaleUpdate: (details) {
                                      setState(() {
                                        _previewScale =
                                            details.scale.clamp(1.0, 5.0);
                                      });
                                    },
                                    child: Stack(
                                      children: [
                                        Center(
                                          child: AspectRatio(
                                            aspectRatio: value.aspectRatio,
                                            child: Transform.scale(
                                              scale: _previewScale,
                                              child: VideoPlayer(controller),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 8,
                                          left: 8,
                                          child: Icon(
                                            value.isPlaying
                                                ? Icons.pause_circle
                                                : Icons.play_circle,
                                            size: 48,
                                            color: Colors.white70,
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          left: 0,
                                          right: 0,
                                          child: Column(
                                            children: [
                                              Slider(
                                                value: position
                                                    .inMilliseconds
                                                    .toDouble(),
                                                min: 0,
                                                max: duration.inMilliseconds
                                                    .toDouble(),
                                                onChanged: (v) => controller
                                                    .seekTo(Duration(
                                                        milliseconds:
                                                            v.toInt())),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 4),
                                                child: Text(
                                                  '${_format(position)} / ${_format(duration)}',
                                                  style: const TextStyle(
                                                      color: Colors.white),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 28,
                                          left: 0,
                                          child: Container(
                                            width: 4,
                                            height: 20,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 28,
                                          right: 0,
                                          child: Container(
                                            width: 4,
                                            height: 20,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ),
                SizedBox(
                  height: 120,
                  child: ReorderableListView.builder(
                    scrollDirection: Axis.horizontal,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex--;
                        final item = _clips.removeAt(oldIndex);
                        _clips.insert(newIndex, item);
                        if (_selectedIndex == oldIndex) {
                          _selectedIndex = newIndex;
                          _initPreview();
                        } else if (oldIndex < _selectedIndex &&
                            newIndex > _selectedIndex) {
                          _selectedIndex--;
                        } else if (oldIndex > _selectedIndex &&
                            newIndex <= _selectedIndex) {
                          _selectedIndex++;
                        }
                      });
                    },
                    itemCount: _clips.length,
                    itemBuilder: (context, index) {
                      final clip = _clips[index];
                      return GestureDetector(
                        key: ValueKey(clip.path),
                        onTap: () => _onSelectClip(index),
                        onLongPress: () {
                          setState(() {
                            _clips.removeAt(index);
                            if (_clips.isEmpty) {
                              _selectedIndex = 0;
                              _initPreview();
                            } else if (_selectedIndex >= _clips.length) {
                              _selectedIndex = _clips.length - 1;
                              _initPreview();
                            }
                          });
                        },
                        child: Container(
                          width: 120,
                          margin: const EdgeInsets.all(8),
                          color: _selectedIndex == index
                              ? Colors.teal
                              : Colors.grey[800],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Clip ${index + 1}'),
                              DropdownButton<TransitionType>(
                                value: clip.transition,
                                items: TransitionType.values
                                    .map(
                                      (t) => DropdownMenuItem(
                                        value: t,
                                        child: Text(t.name),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() => clip.transition = value);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _addVideos,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Videos'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _export,
                          icon: _isExporting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save_alt),
                          label: const Text('Export'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _previewController?.dispose();
    super.dispose();
  }
}
