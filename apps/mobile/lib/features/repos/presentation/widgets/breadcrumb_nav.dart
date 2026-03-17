import 'package:flutter/material.dart';

import '../../../../shared/constants/colors.dart';

/// Horizontal scrollable breadcrumb navigation for a file path.
///
/// [path] is split on `/` and `\` into segments. Each segment is rendered as
/// a tappable [TextButton]. Tapping a segment calls [onSegmentTap] with the
/// cumulative path up to and including that segment. The last (current)
/// segment is rendered in bold primary colour. Adjacent segments are separated
/// by a small chevron icon. The row auto-scrolls to the trailing end whenever
/// [path] changes.
class BreadcrumbNav extends StatefulWidget {
  final String path;
  final void Function(String path) onSegmentTap;

  const BreadcrumbNav({
    super.key,
    required this.path,
    required this.onSegmentTap,
  });

  @override
  State<BreadcrumbNav> createState() => _BreadcrumbNavState();
}

class _BreadcrumbNavState extends State<BreadcrumbNav> {
  final _scrollController = ScrollController();

  @override
  void didUpdateWidget(BreadcrumbNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      // Scroll to the end after layout completes.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<_Segment> _buildSegments(String path) {
    final normalised = path.replaceAll('\\', '/');
    final parts = normalised.split('/').where((s) => s.isNotEmpty).toList();

    final segments = <_Segment>[];
    // Root segment.
    segments.add(_Segment(label: '/', cumulativePath: '/'));

    for (var i = 0; i < parts.length; i++) {
      final cumulative = '/${parts.sublist(0, i + 1).join('/')}';
      segments.add(_Segment(label: parts[i], cumulativePath: cumulative));
    }

    return segments;
  }

  @override
  Widget build(BuildContext context) {
    final segments = _buildSegments(widget.path);
    final lastIndex = segments.length - 1;

    return SizedBox(
      height: 40,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: segments.length * 2 - 1,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemBuilder: (context, index) {
          // Even indices → segment buttons, odd indices → separators.
          if (index.isOdd) {
            return const Icon(
              Icons.chevron_right,
              size: 16,
              color: Color(0xFF9E9E9E),
            );
          }
          final segIndex = index ~/ 2;
          final seg = segments[segIndex];
          final isCurrent = segIndex == lastIndex;

          return TextButton.icon(
            onPressed: () => widget.onSegmentTap(seg.cumulativePath),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: segIndex == 0
                ? const Icon(Icons.folder, size: 14, color: kTextSecondary)
                : const SizedBox.shrink(),
            label: Text(
              seg.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    isCurrent ? FontWeight.w700 : FontWeight.w400,
                color: isCurrent ? kPrimary : kTextSecondary,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Segment {
  final String label;
  final String cumulativePath;

  const _Segment({required this.label, required this.cumulativePath});
}
