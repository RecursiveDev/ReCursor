import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../constants/colors.dart';
import '../constants/typography.dart';

class MarkdownView extends StatelessWidget {
  final String data;
  final bool shrinkWrap;

  const MarkdownView({
    super.key,
    required this.data,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return Markdown(
      data: data,
      shrinkWrap: shrinkWrap,
      styleSheet: _buildStyleSheet(context),
      padding: EdgeInsets.zero,
    );
  }

  MarkdownStyleSheet _buildStyleSheet(BuildContext context) {
    final base = MarkdownStyleSheet.fromTheme(Theme.of(context));
    return base.copyWith(
      code: AppTypography.code,
      codeblockDecoration: BoxDecoration(
        color: kSurfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kBorder),
      ),
      codeblockPadding: const EdgeInsets.all(12),
      blockquoteDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: kPrimary.withOpacity(0.6),
            width: 3,
          ),
        ),
      ),
    );
  }
}
