import 'package:flutter/material.dart';

import 'ansi_renderer.dart';

/// Renders a list of terminal output lines with ANSI colour support.
class TerminalOutput extends StatelessWidget {
  final List<String> lines;

  const TerminalOutput({super.key, required this.lines});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D1117),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        itemCount: lines.length,
        itemBuilder: (context, index) {
          return RichText(
            text: AnsiRenderer.render(lines[index]),
          );
        },
      ),
    );
  }
}
