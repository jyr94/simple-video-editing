import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:simple_video_editing/main.dart';

void main() {
  testWidgets('shows add videos button on start', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Add Videos'), findsOneWidget);
    expect(find.byIcon(Icons.video_library), findsOneWidget);
  });
}
