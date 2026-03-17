import 'package:flutter/material.dart';

import '../constants/colors.dart';

class RiskBadge extends StatelessWidget {
  final String riskLevel;

  const RiskBadge({super.key, required this.riskLevel});

  Color get _color => switch (riskLevel.toLowerCase()) {
        'low' => kRiskLow,
        'medium' => kRiskMedium,
        'high' => kRiskHigh,
        'critical' => kRiskCritical,
        _ => kRiskMedium,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _color.withOpacity(0.6)),
      ),
      child: Text(
        riskLevel.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: _color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
