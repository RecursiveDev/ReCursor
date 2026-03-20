import 'package:flutter/material.dart';

class AppTypography {
  static const String monoFont = 'JetBrainsMono';

  static const TextStyle code = TextStyle(
    fontFamily: monoFont,
    fontSize: 13,
    color: Color(0xFFD4D4D4),
  );

  static const TextStyle codeSmall = TextStyle(
    fontFamily: monoFont,
    fontSize: 11,
    color: Color(0xFF9E9E9E),
  );

  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  static const TextStyle sectionHeader = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.0,
  );
}
