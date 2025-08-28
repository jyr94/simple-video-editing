import 'package:flutter/material.dart';
import 'pages/multi_video_editor_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Video Editor',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          secondary: Color(0xFF22C55E),
        ),
        scaffoldBackgroundColor: const Color(0xFF0E0E0F),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        useMaterial3: true,
      ),
      home: const MultiVideoEditorPage(),
    );
  }
}
