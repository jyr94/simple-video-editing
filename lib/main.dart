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
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF21CFF3),
          secondary: Color(0xFF21CFF3),
          background: Color(0xFF0F0F0F),
          surface: Color(0xFF161616),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F0F0F),
          elevation: 0,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        useMaterial3: true,
      ),
      home: const MultiVideoEditorPage(),
    );
  }
}
