import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../models/video_clip.dart';
import '../widgets/transition_selector.dart';
import '../widgets/timeline_clip.dart';

class MultiVideoEditorPage extends StatefulWidget {
  const MultiVideoEditorPage({super.key});

  @override
  State<MultiVideoEditorPage> createState() => _MultiVideoEditorPageState();
}

class _MultiVideoEditorPageState extends State<MultiVideoEditorPage> {
  final List<List<VideoClip>> _tracks = [[]];
  bool _isExporting = false;
  VideoPlayerController? _previewController;
  int _selectedTrack = 0;
  int _selectedIndex = 0;
  double _previewScale = 1.0;

  bool get _hasAnyClip => _tracks.any((t) => t.isNotEmpty);

  String _format(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final minutes = two(d.inMinutes.remainder(60));
    final seconds = two(d.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

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
      for (final file in result.files) {
        final controller = VideoPlayerController.file(File(file.path!));
        await controller.initialize();
        final Uint8List? thumb = await VideoThumbnail.thumbnailData(
          video: file.path!,
          imageFormat: ImageFormat.PNG,
          maxWidth: 120,
          quality: 75,
        );
        final wave = await _generateWaveform(file.path!);
        _tracks[0].add(
          VideoClip(
            path: file.path!,
            duration: controller.value.duration,
            thumbnail: thumb,
            waveform: wave,
            type: ClipType.video,
          ),
        );
        await controller.dispose();
      }
      _selectedTrack = 0;
      _selectedIndex = 0;
      await _initPreview();
      setState(() {});
    }
  }

  Future<void> _addAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
    );
    if (result != null) {
      if (_tracks.length < 2) _tracks.add([]);
      for (final file in result.files) {
        final controller = VideoPlayerController.file(File(file.path!));
        await controller.initialize();
        final wave = await _generateWaveform(file.path!);
        _tracks[1].add(
          VideoClip(
            path: file.path!,
            duration: controller.value.duration,
            waveform: wave,
            type: ClipType.audio,
          ),
        );
        await controller.dispose();
      }
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
      if (_tracks.length < 3) _tracks.add([]);
      _tracks[2].add(
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
    if (!_hasAnyClip) return;
    if (_selectedTrack >= _tracks.length ||
        _tracks[_selectedTrack].isEmpty) {
      return;
    }
    final clip = _tracks[_selectedTrack][_selectedIndex];
    if (clip.type != ClipType.video || clip.path == null) {
      setState(() {});
      return;
    }
    _previewController = VideoPlayerController.file(File(clip.path!));
    await _previewController!.initialize();
    setState(() {});
  }

  Future<void> _onSelectClip(int track, int index) async {
    _selectedTrack = track;
    _selectedIndex = index;
    await _initPreview();
  }

  Widget _buildDraggableClip(int track, int index) {
    final clip = _tracks[track][index];
    return LongPressDraggable<Map<String, int>>(
      data: {'track': track, 'index': index},
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Material(
        borderRadius: BorderRadius.circular(8),
        child: TimelineClip(clip: clip, selected: true),
      ),
      childWhenDragging: const SizedBox(width: 116),
      child: GestureDetector(
        onTap: () => _onSelectClip(track, index),
        onDoubleTap: () {
          setState(() {
            _tracks[track].removeAt(index);
            if (_tracks[track].isEmpty) {
              _selectedIndex = 0;
              _initPreview();
            } else if (_selectedTrack == track &&
                _selectedIndex >= _tracks[track].length) {
              _selectedIndex = _tracks[track].length - 1;
              _initPreview();
            }
          });
        },
        child: TimelineClip(
          clip: clip,
          selected: _selectedTrack == track && _selectedIndex == index,
        ),
      ),
    );
  }

  Widget _buildDragTarget(int track, int index, Widget child) {
    return DragTarget<Map<String, int>>(
      onWillAccept: (from) =>
          from!['track'] != track || from['index'] != index,
      onAccept: (from) {
        setState(() {
          final item = _tracks[from['track']!].removeAt(from['index']!);
          var newIndex = index;
          if (from['track'] == track && from['index']! < index) newIndex--;
          _tracks[track].insert(newIndex, item);
          if (_selectedTrack == from['track']! &&
              _selectedIndex == from['index']!) {
            _selectedTrack = track;
            _selectedIndex = newIndex;
            _initPreview();
          }
        });
      },
      builder: (context, candidate, rejected) => child,
    );
  }

  Future<void> _export() async {
    final clips = _tracks[0];
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
    if (_tracks[_selectedTrack].isEmpty || _previewController == null) return;
    final clip = _tracks[_selectedTrack][_selectedIndex];
    if (clip.type != ClipType.video || clip.path == null) return;
    final position = _previewController!.value.position;
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

    final thumb1 = await VideoThumbnail.thumbnailData(
      video: firstPath,
      imageFormat: ImageFormat.PNG,
      maxWidth: 120,
      quality: 75,
    );
    final thumb2 = await VideoThumbnail.thumbnailData(
      video: secondPath,
      imageFormat: ImageFormat.PNG,
      maxWidth: 120,
      quality: 75,
    );
    final wave1 = await _generateWaveform(firstPath);
    final wave2 = await _generateWaveform(secondPath);

    final clip1 = VideoClip(
      path: firstPath,
      duration: position,
      thumbnail: thumb1,
      waveform: wave1,
      type: ClipType.video,
    );
    final clip2 = VideoClip(
      path: secondPath,
      duration: clip.duration - position,
      thumbnail: thumb2,
      waveform: wave2,
      type: ClipType.video,
    );

    setState(() {
      _tracks[_selectedTrack].removeAt(_selectedIndex);
      _tracks[_selectedTrack].insertAll(_selectedIndex, [clip1, clip2]);
    });
    await _initPreview();
  }

  Future<void> _deleteSelectedClip() async {
    if (_tracks[_selectedTrack].isEmpty) return;
    _tracks[_selectedTrack].removeAt(_selectedIndex);
    if (_tracks[_selectedTrack].isEmpty) {
      _selectedIndex = 0;
    } else if (_selectedIndex >= _tracks[_selectedTrack].length) {
      _selectedIndex = _tracks[_selectedTrack].length - 1;
    }
    await _initPreview();
    setState(() {});
  }

  Future<void> _openTransitionSettings() async {
    if (_tracks[_selectedTrack].isEmpty) return;
    final clip = _tracks[_selectedTrack][_selectedIndex];
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
            icon: const Icon(Icons.audiotrack),
            onPressed: _addAudio,
          ),
          IconButton(
            icon: const Icon(Icons.text_fields),
            onPressed: _addText,
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
                                                        milliseconds: v
                                                            .toInt())),
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
                  height: 80.0 * _tracks.length,
                  child: Column(
                    children: [
                      for (var t = 0; t < _tracks.length; t++)
                        SizedBox(
                          height: 80,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _tracks[t].length + 1,
                            itemBuilder: (context, index) {
                              if (index == _tracks[t].length) {
                                return _buildDragTarget(
                                  t,
                                  index,
                                  const SizedBox(width: 116),
                                );
                              }
                              return _buildDragTarget(
                                t,
                                index,
                                _buildDraggableClip(t, index),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                SafeArea(
                  child: Row(
                    children: [
                      if (_previewController != null &&
                          _previewController!.value.isInitialized)
                        Expanded(
                          child: ValueListenableBuilder<VideoPlayerValue>(
                            valueListenable: _previewController!,
                            builder: (context, value, child) {
                              final max =
                                  value.duration.inMilliseconds.toDouble();
                              final pos = value.position.inMilliseconds
                                  .clamp(0.0, max)
                                  .toDouble();
                              return Slider(
                                min: 0,
                                max: max,
                                value: pos,
                                onChanged: (v) => _previewController!.seekTo(
                                  Duration(milliseconds: v.toInt()),
                                ),
                              );
                            },
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.call_split),
                        onPressed: () => _splitClip(),
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
