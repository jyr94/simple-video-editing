import 'package:video_editor/video_editor.dart';

abstract class VideoEditorState {}

class VideoInitial extends VideoEditorState {}

class VideoLoading extends VideoEditorState {}

class VideoLoaded extends VideoEditorState {
  final VideoEditorController controller;
  VideoLoaded(this.controller);
}

class VideoEditing extends VideoEditorState {}

class VideoExporting extends VideoEditorState {}

class VideoExported extends VideoEditorState {
  final String outputPath;
  VideoExported(this.outputPath);
}

class VideoError extends VideoEditorState {
  final String message;
  VideoError(this.message);
}
