import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/constants/typography.dart';

// ---------------------------------------------------------------------------
// Syntax colour constants (VS Code Dark+ palette)
// ---------------------------------------------------------------------------

const _colDefault = Color(0xFFD4D4D4);
const _colKeyword = Color(0xFF569CD6);
const _colString = Color(0xFFCE9178);
const _colComment = Color(0xFF6A9955);
const _colNumber = Color(0xFFB5CEA8);
const _colType = Color(0xFF4EC9B0);

// ---------------------------------------------------------------------------
// Token model
// ---------------------------------------------------------------------------

enum _TokenKind { comment, string, keyword, number, type, plain }

class _Token {
  final String text;
  final _TokenKind kind;

  const _Token(this.text, this.kind);

  Color get color => switch (kind) {
        _TokenKind.comment => _colComment,
        _TokenKind.string => _colString,
        _TokenKind.keyword => _colKeyword,
        _TokenKind.number => _colNumber,
        _TokenKind.type => _colType,
        _TokenKind.plain => _colDefault,
      };
}

// ---------------------------------------------------------------------------
// Tokenizer
// ---------------------------------------------------------------------------

const _dartKeywords = {
  'if', 'else', 'for', 'while', 'do', 'switch', 'case', 'break', 'continue',
  'return', 'class', 'extends', 'implements', 'mixin', 'with', 'abstract',
  'import', 'export', 'const', 'final', 'var', 'late', 'required', 'async',
  'await', 'yield', 'try', 'catch', 'finally', 'throw', 'new', 'void',
  'null', 'true', 'false', 'this', 'super', 'static', 'enum', 'typedef',
  'get', 'set', 'in', 'is', 'as', 'part', 'library', 'show', 'hide',
};

const _jsKeywords = {
  'if', 'else', 'for', 'while', 'do', 'switch', 'case', 'break', 'continue',
  'return', 'class', 'extends', 'import', 'export', 'const', 'let', 'var',
  'function', 'async', 'await', 'try', 'catch', 'finally', 'throw', 'new',
  'void', 'null', 'true', 'false', 'this', 'super', 'static', 'typeof',
  'instanceof', 'in', 'of', 'from', 'default', 'yield',
};

bool _isSyntaxLanguage(String ext) =>
    ext == 'dart' || ext == 'ts' || ext == 'tsx' || ext == 'js' || ext == 'jsx';

String _ext(String filePath) {
  final dot = filePath.lastIndexOf('.');
  if (dot == -1 || dot == filePath.length - 1) return '';
  return filePath.substring(dot + 1).toLowerCase();
}

List<_Token> _tokeniseLine(String line, String ext) {
  if (!_isSyntaxLanguage(ext)) return [_Token(line, _TokenKind.plain)];

  final keywords = ext == 'dart' ? _dartKeywords : _jsKeywords;
  final tokens = <_Token>[];

  // State machine — process character by character.
  var i = 0;
  final buf = StringBuffer();

  void flush({_TokenKind kind = _TokenKind.plain}) {
    if (buf.isEmpty) return;
    tokens.add(_Token(buf.toString(), kind));
    buf.clear();
  }

  while (i < line.length) {
    // Single-line comment //
    if (i + 1 < line.length && line[i] == '/' && line[i + 1] == '/') {
      flush();
      tokens.add(_Token(line.substring(i), _TokenKind.comment));
      return tokens;
    }

    // Block comment start /* (treat rest of line as comment for simplicity)
    if (i + 1 < line.length && line[i] == '/' && line[i + 1] == '*') {
      flush();
      final end = line.indexOf('*/', i + 2);
      if (end == -1) {
        tokens.add(_Token(line.substring(i), _TokenKind.comment));
        return tokens;
      }
      tokens.add(_Token(line.substring(i, end + 2), _TokenKind.comment));
      i = end + 2;
      continue;
    }

    // String literals " or '
    if (line[i] == '"' || line[i] == "'") {
      flush();
      final quote = line[i];
      final sb = StringBuffer(quote);
      i++;
      while (i < line.length) {
        if (line[i] == '\\' && i + 1 < line.length) {
          sb.write(line[i]);
          sb.write(line[i + 1]);
          i += 2;
          continue;
        }
        sb.write(line[i]);
        if (line[i] == quote) {
          i++;
          break;
        }
        i++;
      }
      tokens.add(_Token(sb.toString(), _TokenKind.string));
      continue;
    }

    // Template literal `
    if (line[i] == '`') {
      flush();
      final end = line.indexOf('`', i + 1);
      final close = end == -1 ? line.length : end + 1;
      tokens.add(_Token(line.substring(i, close), _TokenKind.string));
      i = close;
      continue;
    }

    // Number literal
    if (line[i].codeUnitAt(0) >= 48 && line[i].codeUnitAt(0) <= 57) {
      flush();
      final start = i;
      while (i < line.length &&
          (RegExp(r'[0-9._xXa-fA-F]').hasMatch(line[i]))) {
        i++;
      }
      tokens.add(_Token(line.substring(start, i), _TokenKind.number));
      continue;
    }

    // Word (keyword, type, or identifier)
    if (RegExp(r'[a-zA-Z_$]').hasMatch(line[i])) {
      flush();
      final start = i;
      while (i < line.length && RegExp(r'[\w$]').hasMatch(line[i])) {
        i++;
      }
      final word = line.substring(start, i);
      _TokenKind kind;
      if (keywords.contains(word)) {
        kind = _TokenKind.keyword;
      } else if (word.isNotEmpty &&
          word[0].toUpperCase() == word[0] &&
          word[0] != word[0].toLowerCase()) {
        kind = _TokenKind.type;
      } else {
        kind = _TokenKind.plain;
      }
      tokens.add(_Token(word, kind));
      continue;
    }

    buf.write(line[i]);
    i++;
  }

  flush();
  return tokens;
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

const int _pageSize = 500;

/// Scrollable syntax-highlighted file viewer with a line-number gutter.
///
/// For files over [_pageSize] lines the first page is shown with a
/// "Load more" button at the bottom.
class SyntaxHighlightedFile extends StatefulWidget {
  final String content;
  final String filePath;

  const SyntaxHighlightedFile({
    super.key,
    required this.content,
    required this.filePath,
  });

  @override
  State<SyntaxHighlightedFile> createState() => _SyntaxHighlightedFileState();
}

class _SyntaxHighlightedFileState extends State<SyntaxHighlightedFile> {
  late List<String> _allLines;
  late int _visibleCount;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(SyntaxHighlightedFile old) {
    super.didUpdateWidget(old);
    if (old.content != widget.content || old.filePath != widget.filePath) {
      _init();
    }
  }

  void _init() {
    _allLines = widget.content.split('\n');
    _visibleCount = _allLines.length.clamp(0, _pageSize);
  }

  void _loadMore() {
    setState(() {
      _visibleCount =
          (_visibleCount + _pageSize).clamp(0, _allLines.length);
    });
  }

  Future<void> _copyAll() async {
    await Clipboard.setData(ClipboardData(text: widget.content));
  }

  @override
  Widget build(BuildContext context) {
    final ext = _ext(widget.filePath);
    final totalLines = _allLines.length;
    final gutterWidth = '$totalLines'.length * 9.0 + 12;
    final showLargeWarning = totalLines > 1000 && _visibleCount <= _pageSize;
    final hasMore = _visibleCount < totalLines;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showLargeWarning)
          Container(
            color: const Color(0xFF2D2D2D),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 14,
                  color: Color(0xFFFF9800),
                ),
                const SizedBox(width: 6),
                Text(
                  'Large file — $totalLines lines total, showing first $_visibleCount.',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFFF9800),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: Scrollbar(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: IntrinsicWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Code lines
                      for (var i = 0; i < _visibleCount; i++)
                        _CodeLine(
                          lineNumber: i + 1,
                          line: _allLines[i],
                          ext: ext,
                          gutterWidth: gutterWidth,
                        ),
                      // Load more button
                      if (hasMore)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Center(
                            child: TextButton.icon(
                              onPressed: _loadMore,
                              icon: const Icon(Icons.expand_more, size: 16),
                              label: Text(
                                'Load more (${totalLines - _visibleCount} remaining)',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Single code line
// ---------------------------------------------------------------------------

class _CodeLine extends StatelessWidget {
  final int lineNumber;
  final String line;
  final String ext;
  final double gutterWidth;

  const _CodeLine({
    required this.lineNumber,
    required this.line,
    required this.ext,
    required this.gutterWidth,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = _tokeniseLine(line, ext);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gutter
        SizedBox(
          width: gutterWidth,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            child: Text(
              '$lineNumber',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 13,
                color: Color(0xFF5A5A5A),
                height: 1.5,
              ),
            ),
          ),
        ),
        // Separator
        Container(
          width: 1,
          color: const Color(0xFF2A2A2A),
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        ),
        // Code
        Padding(
          padding: const EdgeInsets.only(right: 16, top: 1, bottom: 1),
          child: RichText(
            text: TextSpan(
              children: tokens
                  .map(
                    (t) => TextSpan(
                      text: t.text,
                      style: AppTypography.code.copyWith(
                        color: t.color,
                        height: 1.5,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}
