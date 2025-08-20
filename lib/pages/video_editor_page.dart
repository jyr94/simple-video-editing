import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/video_editor_bloc.dart';
import '../bloc/video_editor_event.dart';
import '../bloc/video_editor_state.dart';
import '../widgets/video_preview.dart';
import '../widgets/editing_controls.dart';

class VideoEditorPage extends StatelessWidget {
  const VideoEditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video Editor')),
      body: BlocConsumer<VideoEditorBloc, VideoEditorState>(
        listener: (context, state) {
          if (state is VideoError) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is VideoInitial) {
            return Center(
              child: ElevatedButton(
                onPressed: () {
                  const path = '/path/to/video.mp4';
                  context.read<VideoEditorBloc>().add(LoadVideo(path));
                },
                child: const Text('Pick Video'),
              ),
            );
          } else if (state is VideoLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is VideoLoaded) {
            return Column(
              children: [
                Expanded(child: VideoPreview(controller: state.controller)),
                EditingControls(controller: state.controller),
              ],
            );
          } else if (state is VideoEditing || state is VideoExporting) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is VideoExported) {
            return Center(
              child: Text('Video saved: ${state.outputPath}'),
            );
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }
}
