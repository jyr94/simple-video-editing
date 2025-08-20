abstract class VideoEditorEvent {}

class LoadVideo extends VideoEditorEvent {
  final String path;
  LoadVideo(this.path);
}

class TrimVideo extends VideoEditorEvent {
  final Duration start;
  final Duration end;
  TrimVideo({required this.start, required this.end});
}
// Additional events like AddFilter, ExportVideo can be added later.
