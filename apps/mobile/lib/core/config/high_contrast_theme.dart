import 'package:flutter/material.dart';

class HighContrastTheme {
  static ThemeData get theme {
    return ThemeData.dark().copyWith(
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFFFFFFF),        // white
        secondary: Color(0xFFFFFF00),      // yellow
        surface: Color(0xFF000000),        // pure black
        error: Color(0xFFFF0000),          // pure red
      ),
      scaffoldBackgroundColor: Colors.black,
      cardTheme: const CardThemeData(
        color: Color(0xFF111111),
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.white, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: Border(bottom: BorderSide(color: Colors.white, width: 1)),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
        bodyMedium: TextStyle(color: Colors.white, fontSize: 14),
        bodySmall: TextStyle(color: Colors.white, fontSize: 12),
        titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      dividerColor: Colors.white,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.black,
        border: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white, width: 2),
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white, width: 2),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.yellow, width: 2),
        ),
        labelStyle: const TextStyle(color: Colors.white),
        hintStyle: const TextStyle(color: Colors.grey),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.yellow,
        unselectedItemColor: Colors.white,
      ),
    );
  }
}
