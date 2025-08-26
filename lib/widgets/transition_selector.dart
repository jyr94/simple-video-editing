import 'package:flutter/material.dart';

import '../models/video_clip.dart';

class TransitionSelector extends StatelessWidget {
  final TransitionType initial;
  const TransitionSelector({super.key, required this.initial});

  String _labelFor(TransitionType t) {
    switch (t) {
      case TransitionType.none:
        return 'None';
      case TransitionType.fade:
        return 'Fade';
      case TransitionType.slide:
        return 'Slide';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: TransitionType.values
          .map(
            (t) => ListTile(
              title: Text(_labelFor(t)),
              trailing: t == initial ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(context, t),
            ),
          )
          .toList(),
    );
  }
}
