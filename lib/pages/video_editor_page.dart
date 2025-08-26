import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../bloc/video_editor_bloc.dart';
import '../bloc/video_editor_event.dart';
import '../bloc/video_editor_state.dart';
import '../widgets/video_preview.dart';
import '../widgets/video_track.dart';
import '../models/video_clip.dart';

class VideoEditorPage extends StatelessWidget {
  const VideoEditorPage({super.key});

  Future<void> _pickVideo(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickVideo(source: ImageSource.gallery);
    if (file != null) {
      // ignore: use_build_context_synchronously
      context.read<VideoEditorBloc>().add(LoadVideo(file.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Editor'),
        backgroundColor: Colors.grey[900],
        actions: [
          IconButton(
            tooltip: 'Open Video',
            icon: const Icon(Icons.folder_open),
            onPressed: () => _pickVideo(context),
          ),
        ],
      ),
      body: BlocConsumer<VideoEditorBloc, VideoEditorState>(
        listener: (context, state) {
          if (state is VideoError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is VideoInitial) {
            return Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.video_library),
                label: const Text('Import Video'),
                onPressed: () => _pickVideo(context),
              ),
            );
          }

          if (state is VideoLoading || state is VideoEditing) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is VideoLoaded) {
            final clip = VideoClip(
              duration: state.controller.videoDuration,
              start: state.controller.startTrim,
              end: state.controller.endTrim,
            );

            return Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        border: Border.all(color: Colors.grey.shade800),
                      ),
                      child: VideoPreview(controller: state.controller),
                    ),
                  ),
                ),
                VideoTrack(
                  clips: [clip],
                  selectedIndex: 0,
                  onSelect: (_) {},
                  onReorder: (from, to) {},
                  onAppend: () => _pickVideo(context),
                  onRemove: (_) {},
                  onTrim: (index, start, end) {
                    context.read<VideoEditorBloc>().add(
                          TrimVideo(start: start, end: end),
                        );
                  },
                ),
              ],
            );
          }

          // Error & fallback
          if (state is VideoError) {
            return Center(child: Text(state.message));
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
