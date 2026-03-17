import 'package:flutter/material.dart';

class AnsiSpan {
  final String text;
  final Color? color;
  final bool bold;
  final bool italic;

  const AnsiSpan(
    this.text, {
    this.color,
    this.bold = false,
    this.italic = false,
  });
}

/// Parses ANSI escape codes from terminal output.
class AnsiParser {
  static final _ansiEscapePattern = RegExp(r'\x1B\[[0-9;]*m');

  // Standard 8/16 ANSI foreground color table (codes 30–37, bright 90–97)
  static const _fgColors = {
    30: Color(0xFF000000), // black
    31: Color(0xFFCD3131), // red
    32: Color(0xFF0DBC79), // green
    33: Color(0xFFE5E510), // yellow
    34: Color(0xFF2472C8), // blue
    35: Color(0xFFBC3FBC), // magenta
    36: Color(0xFF11A8CD), // cyan
    37: Color(0xFFE5E5E5), // white
    90: Color(0xFF666666), // bright black (gray)
    91: Color(0xFFF14C4C), // bright red
    92: Color(0xFF23D18B), // bright green
    93: Color(0xFFF5F543), // bright yellow
    94: Color(0xFF3B8EEA), // bright blue
    95: Color(0xFFD670D6), // bright magenta
    96: Color(0xFF29B8DB), // bright cyan
    97: Color(0xFFFFFFFF), // bright white
  };

  /// Remove all ANSI escape sequences from [text].
  static String stripAnsi(String text) {
    return text.replaceAll(_ansiEscapePattern, '');
  }

  /// Parse [text] containing ANSI escape sequences into a list of [AnsiSpan]s.
  static List<AnsiSpan> parse(String text) {
    final spans = <AnsiSpan>[];

    Color? currentColor;
    bool bold = false;
    bool italic = false;

    int cursor = 0;

    final matches = _ansiEscapePattern.allMatches(text).toList();

    for (final match in matches) {
      // Append plain text before this escape sequence
      if (match.start > cursor) {
        final plain = text.substring(cursor, match.start);
        if (plain.isNotEmpty) {
          spans.add(AnsiSpan(plain, color: currentColor, bold: bold, italic: italic));
        }
      }

      // Parse the escape sequence codes
      final sequence = match.group(0)!;
      final inner = sequence.substring(2, sequence.length - 1); // strip ESC[ and m
      final codes = inner.isEmpty
          ? [0]
          : inner.split(';').map((s) => int.tryParse(s) ?? 0).toList();

      for (final code in codes) {
        if (code == 0) {
          // Reset
          currentColor = null;
          bold = false;
          italic = false;
        } else if (code == 1) {
          bold = true;
        } else if (code == 3) {
          italic = true;
        } else if (code == 22) {
          bold = false;
        } else if (code == 23) {
          italic = false;
        } else if (_fgColors.containsKey(code)) {
          currentColor = _fgColors[code];
        }
        // Background colors (40–47) are parsed but ignored for spans
      }

      cursor = match.end;
    }

    // Remaining text after the last escape sequence
    if (cursor < text.length) {
      final remaining = text.substring(cursor);
      if (remaining.isNotEmpty) {
        spans.add(AnsiSpan(remaining, color: currentColor, bold: bold, italic: italic));
      }
    }

    // If no escape sequences were found, return the whole string as one span
    if (spans.isEmpty && text.isNotEmpty) {
      spans.add(AnsiSpan(text));
    }

    return spans;
  }
}
