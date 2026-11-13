import 'package:flutter/material.dart';

import 'screens/split_bill_screen.dart';

void main() {
  runApp(const SplitEaseApp());
}

class SplitEaseApp extends StatelessWidget {
  const SplitEaseApp({super.key});

  static const Color _primary = Color(0xFFE9868B);
  static const Color _secondary = Color(0xFFAD2632);
  static const Color _background = Color(0xFFFFF1EE);
  static const Color _text = Color(0xFF333333);

  ThemeData _buildTheme() {
    final scheme = ColorScheme.fromSeed(seedColor: _primary).copyWith(
      primary: _primary,
      // Dark text on the pink primary keeps button labels readable.
      onPrimary: _text,
      secondary: _secondary,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: _text,
      error: _secondary,
    );

    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: _background,
      textTheme: ThemeData(brightness: Brightness.light)
          .textTheme
          .apply(bodyColor: _text, displayColor: _text),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: border(const Color(0xFFE5C7C4), 1),
        enabledBorder: border(const Color(0xFFE5C7C4), 1),
        focusedBorder: border(_primary, 2),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SplitEase',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const SplitBillScreen(),
    );
  }
}
