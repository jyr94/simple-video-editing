import 'package:flutter/material.dart';

class EditorAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onAdd;
  final VoidCallback onExport;
  final VoidCallback onClear;
  final bool hasClips;
  final bool isExporting;

  const EditorAppBar({
    super.key,
    required this.onAdd,
    required this.onExport,
    required this.onClear,
    required this.hasClips,
    required this.isExporting,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.black,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: const Text('Edit'),
      actions: [
        IconButton(
          icon: const Icon(Icons.video_library),
          onPressed: onAdd,
        ),
        IconButton(
          icon: const Icon(Icons.delete_forever),
          tooltip: 'Clear all',
          onPressed: hasClips ? onClear : null,
        ),
        IconButton(
          icon: isExporting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_alt),
          onPressed: isExporting ? null : onExport,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
