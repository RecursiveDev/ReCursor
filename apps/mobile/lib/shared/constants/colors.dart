import 'package:flutter/material.dart';

import '../../core/config/theme.dart';

// Re-export AppColors constants
const kBackground = AppColors.background;
const kSurface = AppColors.surface;
const kSurfaceVariant = AppColors.surfaceVariant;
const kPrimary = AppColors.primary;
const kSecondary = AppColors.secondary;
const kError = AppColors.error;
const kAdded = AppColors.added;
const kRemoved = AppColors.removed;
const kAccent = AppColors.accent;
const kTextPrimary = AppColors.textPrimary;
const kTextSecondary = AppColors.textSecondary;
const kBorder = AppColors.border;

// Diff line background colors
const kDiffAdded = Color(0x334EC9B0);
const kDiffRemoved = Color(0x33F44747);
const kDiffContext = Color(0x00000000); // transparent

// Risk level colors
const kRiskLow = Color(0xFF4CAF50);
const kRiskMedium = Color(0xFFFF9800);
const kRiskHigh = Color(0xFFF44747);
const kRiskCritical = Color(0xFF8B0000);

// Tool status colors
const kToolPending = Color(0xFF569CD6);
const kToolRunning = Color(0xFFFF9800);
const kToolCompleted = Color(0xFF4EC9B0);
const kToolError = Color(0xFFF44747);
