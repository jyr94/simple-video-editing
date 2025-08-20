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

  Future<void> _onLoadVideo(
    LoadVideo event,
    Emitter<VideoEditorState> emit,
  ) async {
    try {
      emit(VideoLoading());
      final controller = VideoEditorController.file(File(event.path));
      await controller.initialize();
      emit(VideoLoaded(controller));
    } catch (e) {
      emit(VideoError('Failed to load video: ' + e.toString()));
    }
  }

  Future<void> _onTrimVideo(
    TrimVideo event,
    Emitter<VideoEditorState> emit,
  ) async {
    final currentState = state;
    if (currentState is VideoLoaded) {
      emit(VideoEditing());
      try {
        await currentState.controller.video
            .trim(start: event.start, end: event.end);
        emit(VideoLoaded(currentState.controller));
      } catch (e) {
        emit(VideoError('Failed to trim video: ' + e.toString()));
      }
    }
  }
}
