import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:flutter/material.dart';
import 'package:video_editor/video_editor.dart';
import 'package:video_player/video_player.dart';

import '../models/video_clip.dart';
import '../widgets/transition_selector.dart';
import '../widgets/timeline_clip.dart';
import '../widgets/video_preview.dart';
import '../widgets/editor_toolbar.dart';

class MultiVideoEditorPage extends StatefulWidget {
  const MultiVideoEditorPage({super.key});

  @override
  State<MultiVideoEditorPage> createState() => _MultiVideoEditorPageState();
}

class _MultiVideoEditorPageState extends State<MultiVideoEditorPage> {
  final List<VideoClip> _clips = [];
  bool _isExporting = false;
  VideoEditorController? _previewController;
  int _selectedIndex = 0;

  bool get _hasAnyClip => _clips.isNotEmpty;

  Future<Uint8List?> _generateWaveform(String path) async {
    final wavePath =
        '${Directory.systemTemp.path}/wave_${DateTime.now().millisecondsSinceEpoch}.png';
    final cmd =
        "-i '$path' -filter_complex \"aformat=channel_layouts=mono,showwavespic=s=120x40\" -frames:v 1 '$wavePath'";
    await FFmpegKit.execute(cmd);
    final file = File(wavePath);
    if (await file.exists()) {
      return await file.readAsBytes();
    }
    return null;
  }

  Future<void> _addVideos() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: true,
    );
    if (result != null) {
      var insertIndex = _clips.isEmpty ? 0 : _selectedIndex + 1;
      for (final file in result.files) {
        final controller = VideoPlayerController.file(File(file.path!));
        await controller.initialize();
        final wave = await _generateWaveform(file.path!);
        _clips.insert(
          insertIndex,
          VideoClip(
            path: file.path!,
            duration: controller.value.duration,
            waveform: wave,
            type: ClipType.video,
          ),
        );
        insertIndex++;
        await controller.dispose();
      }
      _selectedIndex = insertIndex - 1;
      await _initPreview();
      setState(() {});
    }
  }

  Future<void> _addText() async {
    final textController = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Text'),
          content: TextField(controller: textController),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, textController.text),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
    if (text != null && text.isNotEmpty) {
      _clips.add(
        VideoClip(
          path: null,
          duration: const Duration(seconds: 3),
          text: text,
          type: ClipType.text,
        ),
      );
      setState(() {});
    }
  }

  Future<void> _initPreview() async {
    await _previewController?.dispose();
    _previewController = null;
    if (!_hasAnyClip || _selectedIndex >= _clips.length) return;
    final clip = _clips[_selectedIndex];
    if (clip.type != ClipType.video || clip.path == null) {
      setState(() {});
      return;
    }
    final file = File(clip.path!);
    final probe = VideoPlayerController.file(file);
    await probe.initialize();
    final videoDuration = probe.value.duration;
    await probe.dispose();
    const minDuration = Duration(milliseconds: 1);
    final maxDuration =
        videoDuration > minDuration ? videoDuration : minDuration * 2;
    final controller = VideoEditorController.file(
      file,
      minDuration: minDuration,
      maxDuration: maxDuration,
    );
    await controller.initialize();
    controller.updateTrim(
      clip.start.inMilliseconds / clip.duration.inMilliseconds,
      clip.end.inMilliseconds / clip.duration.inMilliseconds,
    );
    controller.addListener(() {
      setState(() {
        clip.start = controller.startTrim;
        clip.end = controller.endTrim;
      });
    });
    _previewController = controller;
    setState(() {});
  }

  Future<void> _onSelectClip(int index) async {
    _selectedIndex = index;
    await _initPreview();
  }

  Widget _buildDraggableClip(int index) {
    final clip = _clips[index];
    return Draggable<Map<String, int>>(
      data: {'index': index},
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Material(
        borderRadius: BorderRadius.circular(8),
        child: TimelineClip(clip: clip, selected: true),
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
        child: TimelineClip(
          clip: clip,
          selected: _selectedIndex == index,
        ),
      ),
    );
  }

  Widget _buildDragTarget(int index, Widget child) {
    return DragTarget<Map<String, int>>(
      onWillAccept: (from) => from!['index'] != index,
      onAccept: (from) {
        setState(() {
          final item = _clips.removeAt(from['index']!);
          var newIndex = index;
          if (from['index']! < index) newIndex--;
          _clips.insert(newIndex, item);
          if (_selectedIndex == from['index']!) {
            _selectedIndex = newIndex;
            _initPreview();
          }
        });
      },
      builder: (context, candidate, rejected) => child,
    );
  }

  Future<void> _export() async {
    final clips = _clips;
    if (clips.isEmpty || _isExporting) return;
    setState(() => _isExporting = true);

    final output = '${Directory.systemTemp.path}/output.mp4';
    final inputs = clips.map((c) => "-i '${c.path}'").join(' ');

    String filter = '';
    String currentV = '[0:v]';
    String currentA = '[0:a]';
    double currentDur = clips.first.duration.inSeconds.toDouble();

    for (var i = 1; i < clips.length; i++) {
      final prev = clips[i - 1];
      if (prev.transition != TransitionType.none) {
        final transition =
            prev.transition == TransitionType.fade ? 'fade' : 'slideleft';
        filter +=
            '$currentV$currentA[$i:v][$i:a]xfade=transition=$transition:duration=1:offset=${currentDur - 1}[v$i][a$i];';
        currentV = '[v$i]';
        currentA = '[a$i]';
        currentDur += clips[i].duration.inSeconds.toDouble() - 1;
      } else {
        filter +=
            '$currentV$currentA[$i:v][$i:a]concat=n=2:v=1:a=1[v$i][a$i];';
        currentV = '[v$i]';
        currentA = '[a$i]';
        currentDur += clips[i].duration.inSeconds.toDouble();
      }
    }

    final cmd = clips.length == 1
        ? "$inputs -c copy $output"
        : "$inputs -filter_complex \"$filter\" -map $currentV -map $currentA $output";

    await FFmpegKit.execute(cmd);
    setState(() => _isExporting = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Export complete: $output')),
    );
  }

  Future<void> _splitClip() async {
    if (_clips.isEmpty || _previewController == null) return;
    final clip = _clips[_selectedIndex];
    if (clip.type != ClipType.video || clip.path == null) return;
    final position = _previewController!.video.value.position;
    if (position <= Duration.zero || position >= clip.duration) return;

    final tmp = Directory.systemTemp.path;
    final base = DateTime.now().millisecondsSinceEpoch;
    final firstPath = '$tmp/split_${base}_1.mp4';
    final secondPath = '$tmp/split_${base}_2.mp4';
    final posSeconds = position.inMilliseconds / 1000.0;

    final firstCmd =
        "-i '${clip.path}' -t $posSeconds -c copy '$firstPath'";
    final secondCmd =
        "-i '${clip.path}' -ss $posSeconds -c copy '$secondPath'";

    await FFmpegKit.execute(firstCmd);
    await FFmpegKit.execute(secondCmd);

    final wave1 = await _generateWaveform(firstPath);
    final wave2 = await _generateWaveform(secondPath);

    final clip1 = VideoClip(
      path: firstPath,
      duration: position,
      waveform: wave1,
      type: ClipType.video,
    );
    final clip2 = VideoClip(
      path: secondPath,
      duration: clip.duration - position,
      waveform: wave2,
      type: ClipType.video,
    );

    setState(() {
      _clips.removeAt(_selectedIndex);
      _clips.insertAll(_selectedIndex, [clip1, clip2]);
    });
    await _initPreview();
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

  Future<void> _openTransitionSettings() async {
    if (_clips.isEmpty) return;
    final clip = _clips[_selectedIndex];
    if (clip.type != ClipType.video) return;
    final selected = await showModalBottomSheet<TransitionType>(
      context: context,
      builder: (context) =>
          TransitionSelector(initial: clip.transition),
    );
    if (selected != null) {
      setState(() {
        clip.transition = selected;
      });
    }
  }

  void _showPlaceholder(String feature) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$feature not implemented')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Editor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.video_library),
            onPressed: _addVideos,
          ),
          IconButton(
            icon: _isExporting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_alt),
            onPressed: _isExporting ? null : _export,
          ),
        ],
      ),
      body: !_hasAnyClip
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
                            !_previewController!.initialized
                        ? const Text('No clip selected')
                        : VideoPreview(controller: _previewController!),
                  ),
                ),
                SizedBox(
                  height: 80,
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
                  top: false,
                  child: EditorToolbar(
                    onEdit: _splitClip,
                    onAudio: () => _showPlaceholder('Audio'),
                    onText: _addText,
                    onEffect: _openTransitionSettings,
                    onOverlay: () => _showPlaceholder('Overlay'),
                    onCaption: () => _showPlaceholder('Keterangan'),
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
