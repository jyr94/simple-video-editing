import 'package:equatable/equatable.dart';

abstract class VideoEditorEvent extends Equatable {
  const VideoEditorEvent();

  @override
  List<Object?> get props => [];
}

class LoadVideo extends VideoEditorEvent {
  final String path; // path file lokal (mis. dari ImagePicker)
  const LoadVideo(this.path);

  @override
  List<Object?> get props => [path];
}

class TrimVideo extends VideoEditorEvent {
  final Duration start;
  final Duration end;
  const TrimVideo({required this.start, required this.end});

  @override
  List<Object?> get props => [start, end];
}
