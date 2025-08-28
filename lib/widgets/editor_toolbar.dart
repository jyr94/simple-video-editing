import 'package:flutter/material.dart';

class EditorToolbar extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onAudio;
  final VoidCallback? onText;
  final VoidCallback? onEffect;
  final VoidCallback? onOverlay;
  final VoidCallback? onCaption;

  const EditorToolbar({
    super.key,
    this.onEdit,
    this.onAudio,
    this.onText,
    this.onEffect,
    this.onOverlay,
    this.onCaption,
  });

  Widget _buildItem(IconData icon, String label, VoidCallback? onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: const Border(
          top: BorderSide(color: Colors.white24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildItem(Icons.edit, 'Edit', onEdit),
          _buildItem(Icons.audiotrack, 'Audio', onAudio),
          _buildItem(Icons.text_fields, 'Teks', onText),
          _buildItem(Icons.movie_filter, 'Efek', onEffect),
          _buildItem(Icons.layers, 'Overlay', onOverlay),
          _buildItem(Icons.closed_caption, 'Keterangan', onCaption),
        ],
      ),
    );
  }
}

