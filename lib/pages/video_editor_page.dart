import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is VideoInitial) {
            return Center(
              child: ElevatedButton(
                onPressed: () async {
                  final picker = ImagePicker();
                  final XFile? file =
                      await picker.pickVideo(source: ImageSource.gallery);
                  if (file != null) {
                    // ignore: use_build_context_synchronously
                    context.read<VideoEditorBloc>().add(LoadVideo(file.path));
                  }
                },
                child: const Text('Pick Video'),
              ),
            );
          }

          if (state is VideoLoading || state is VideoEditing) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is VideoLoaded) {
            return Column(
              children: [
                Expanded(child: VideoPreview(controller: state.controller)),
                EditingControls(controller: state.controller),
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
