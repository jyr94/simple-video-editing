import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

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

  Future<void> _addVideos() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: true,
    );
    if (result != null) {
      for (final file in result.files) {
        final controller = VideoPlayerController.file(File(file.path!));
        await controller.initialize();
        final Uint8List? thumb = await VideoThumbnail.thumbnailData(
          video: file.path!,
          imageFormat: ImageFormat.PNG,
          maxWidth: 120,
          quality: 75,
        );
        _clips.add(
          VideoClip(
            path: file.path!,
            duration: controller.value.duration,
            thumbnail: thumb,
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

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _clipThumbnail(VideoClip clip, bool selected) {
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
          clip.thumbnail != null
              ? Image.memory(clip.thumbnail!, fit: BoxFit.cover)
              : Container(color: Colors.black),
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              color: Colors.black54,
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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

  Widget _buildDraggableClip(int index) {
    final clip = _clips[index];
    return LongPressDraggable<int>(
      data: index,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Material(
        borderRadius: BorderRadius.circular(8),
        child: _clipThumbnail(clip, true),
      ),
      childWhenDragging: const SizedBox(width: 116),
      child: GestureDetector(
        onTap: () => _onSelectClip(index),
        onDoubleTap: () {
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
        child: _clipThumbnail(clip, _selectedIndex == index),
      ),
    );
  }

  Widget _buildDragTarget(int index, Widget child) {
    return DragTarget<int>(
      onWillAccept: (from) => from != index,
      onAccept: (from) {
        setState(() {
          final item = _clips.removeAt(from);
          var newIndex = index;
          if (newIndex > from) newIndex--;
          _clips.insert(newIndex, item);
          if (_selectedIndex == from) {
            _selectedIndex = newIndex;
            _initPreview();
          } else if (from < _selectedIndex && newIndex >= _selectedIndex) {
            _selectedIndex--;
          } else if (from > _selectedIndex && newIndex <= _selectedIndex) {
            _selectedIndex++;
          }
        });
      },
      builder: (context, candidate, rejected) {
        return child;
      },
    );
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

  void _splitClip() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Split feature coming soon')),
    );
  }

  Future<void> _deleteSelectedClip() async {
    if (_clips.isEmpty) return;
    _clips.removeAt(_selectedIndex);
    if (_clips.isEmpty) {
      _selectedIndex = 0;
    } else if (_selectedIndex >= _clips.length) {
      _selectedIndex = _clips.length - 1;
    }
    await _initPreview();
    setState(() {});
  }

  void _openTransitionSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transition settings coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Editor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addVideos,
          ),
        ],
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
                        : AspectRatio(
                            aspectRatio:
                                _previewController!.value.aspectRatio,
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                VideoPlayer(_previewController!),
                                VideoProgressIndicator(
                                  _previewController!,
                                  allowScrubbing: true,
                                ),
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: IconButton(
                                    icon: Icon(
                                      _previewController!
                                              .value.isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        if (_previewController!
                                            .value.isPlaying) {
                                          _previewController!.pause();
                                        } else {
                                          _previewController!.play();
                                        }
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _clips.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _clips.length) {
                        return _buildDragTarget(
                          index,
                          const SizedBox(width: 116),
                        );
                      }
                      return _buildDragTarget(
                        index,
                        _buildDraggableClip(index),
                      );
                    },
                  ),
                ),
                SafeArea(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.call_split),
                        onPressed: _splitClip,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: _deleteSelectedClip,
                      ),
                      IconButton(
                        icon: const Icon(Icons.tune),
                        onPressed: _openTransitionSettings,
                      ),
                      IconButton(
                        icon: _isExporting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_alt),
                        onPressed: _isExporting ? null : _export,
                      ),
                    ],
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
