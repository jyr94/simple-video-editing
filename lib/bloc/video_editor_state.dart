import 'package:equatable/equatable.dart';
import 'package:video_editor/video_editor.dart';

abstract class VideoEditorState extends Equatable {
  const VideoEditorState();

  @override
  List<Object?> get props => [];
}

class VideoInitial extends VideoEditorState {}

class VideoLoading extends VideoEditorState {}

class VideoLoaded extends VideoEditorState {
  final VideoEditorController controller;
  const VideoLoaded(this.controller);

  @override
  List<Object?> get props => [controller];
}

class VideoEditing extends VideoEditorState {}

class VideoError extends VideoEditorState {
  final String message;
  const VideoError(this.message);

  @override
  List<Object?> get props => [message];
}
