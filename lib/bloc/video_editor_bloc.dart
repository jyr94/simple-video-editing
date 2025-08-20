import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:video_editor/video_editor.dart';

import 'video_editor_event.dart';
import 'video_editor_state.dart';

class VideoEditorBloc extends Bloc<VideoEditorEvent, VideoEditorState> {
  VideoEditorBloc() : super(VideoInitial()) {
    on<LoadVideo>(_onLoadVideo);
    on<TrimVideo>(_onTrimVideo);
  }

  VideoEditorController? _controller; // simpan untuk dispose saat close

  Future<void> _onLoadVideo(
    LoadVideo event,
    Emitter<VideoEditorState> emit,
  ) async {
    try {
      emit(VideoLoading());

      // Tutup controller lama kalau ada
      if (_controller != null && _controller!.initialized) {
        await _controller!.dispose();
      }

      final controller = VideoEditorController.file(
        File(event.path),
        // opsional: atur batas durasi trim
        // minDuration: const Duration(seconds: 1),
        // maxDuration: const Duration(seconds: 30),
      );

      await controller.initialize();
      _controller = controller;

      emit(VideoLoaded(controller));
    } catch (e) {
      emit(VideoError('Failed to load video: $e'));
    }
  }

  Future<void> _onTrimVideo(
    TrimVideo event,
    Emitter<VideoEditorState> emit,
  ) async {
    final currentState = state;
    if (currentState is! VideoLoaded) return;

    emit(VideoEditing());

    try {
      // Set posisi trim di controller video_editor menggunakan rasio (0 - 1)
      final controller = currentState.controller;
      final duration = controller.videoDuration.inMilliseconds.toDouble();
      final start = event.start.inMilliseconds / duration;
      final end = event.end.inMilliseconds / duration;
      controller.updateTrim(start, end);

      // Balik ke state loaded (controller sudah ter-update)
      emit(VideoLoaded(controller));
    } catch (e) {
      emit(VideoError('Failed to trim video: $e'));
    }
  }

  @override
  Future<void> close() async {
    try {
      if (_controller != null && _controller!.initialized) {
        await _controller!.dispose();
      }
    } catch (_) {}
    return super.close();
  }
}
