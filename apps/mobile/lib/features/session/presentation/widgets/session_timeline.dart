import 'package:flutter/material.dart';

import '../../../../core/models/session_models.dart';
import 'timeline_tile.dart';

/// Renders the full list of [SessionEvent]s as a vertical timeline.
class SessionTimeline extends StatelessWidget {
  final List<SessionEvent> events;

  const SessionTimeline({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Center(
        child: Text(
          'No events yet',
          style: TextStyle(color: Color(0xFF9E9E9E)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: events.length,
      itemBuilder: (context, index) {
        return TimelineTile(
          event: events[index],
          isFirst: index == 0,
          isLast: index == events.length - 1,
        );
      },
    );
  }
}
