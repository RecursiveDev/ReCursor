import 'package:flutter/material.dart';

import '../../../../shared/utils/ansi_parser.dart';

/// Converts a terminal output line (potentially containing ANSI escape codes)
/// into a [InlineSpan] suitable for a [RichText] widget.
class AnsiRenderer {
  AnsiRenderer._();

  static InlineSpan render(String line) {
    final spans = AnsiParser.parse(line);

    if (spans.isEmpty) {
      return const TextSpan(text: '');
    }

    final children = spans.map((span) {
      return TextSpan(
        text: span.text,
        style: TextStyle(
          color: span.color ?? const Color(0xFFD4D4D4),
          fontWeight: span.bold ? FontWeight.bold : FontWeight.normal,
          fontStyle: span.italic ? FontStyle.italic : FontStyle.normal,
          fontFamily: 'JetBrainsMono',
          fontSize: 13,
        ),
      );
    }).toList();

    return TextSpan(children: children);
  }
}
