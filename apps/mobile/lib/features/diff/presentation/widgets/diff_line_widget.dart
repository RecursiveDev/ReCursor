import 'package:flutter/material.dart';

import '../../../../core/models/git_models.dart';

class DiffLineWidget extends StatelessWidget {
  final DiffLine line;
  const DiffLineWidget({super.key, required this.line});

  Color get _backgroundColor {
    return switch (line.type) {
      DiffLineType.added => const Color(0xFF1A3A1A),
      DiffLineType.removed => const Color(0xFF3A1A1A),
      DiffLineType.context => Colors.transparent,
    };
  }

  String get _prefix {
    return switch (line.type) {
      DiffLineType.added => '+',
      DiffLineType.removed => '-',
      DiffLineType.context => ' ',
    };
  }

  Color get _prefixColor {
    return switch (line.type) {
      DiffLineType.added => const Color(0xFF4EC9B0),
      DiffLineType.removed => Colors.redAccent,
      DiffLineType.context => Colors.grey,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _backgroundColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Old line number gutter
          SizedBox(
            width: 36,
            child: Text(
              line.oldLineNumber?.toString() ?? '',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.grey,
                fontFamily: 'JetBrainsMono',
                fontSize: 11,
              ),
            ),
          ),
          // New line number gutter
          SizedBox(
            width: 36,
            child: Text(
              line.newLineNumber?.toString() ?? '',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.grey,
                fontFamily: 'JetBrainsMono',
                fontSize: 11,
              ),
            ),
          ),
          // Prefix (+/-/space)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              _prefix,
              style: TextStyle(
                color: _prefixColor,
                fontFamily: 'JetBrainsMono',
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Content
          Expanded(
            child: Text(
              line.content,
              style: TextStyle(
                color: line.type == DiffLineType.context
                    ? const Color(0xFFD4D4D4)
                    : Colors.white,
                fontFamily: 'JetBrainsMono',
                fontSize: 12,
              ),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}
