import 'package:flutter/material.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';

/// Legacy theme file - kept for backwards compatibility
/// New code should use AppTheme directly from theme/app_theme.dart

class AppColors {
  // Map old colors to new theme
  static Color primaryColor = AppTheme.primary;
  static Color primaryAccent = AppTheme.primaryDark;
  static Color secondaryColor = AppTheme.secondary;
  static Color secondaryAccent = AppTheme.secondaryLight;
  static Color titleBarColor = AppTheme.textMedium;
  static Color titleColor = AppTheme.textLight;
  static Color textColor = AppTheme.textWhite;
  static Color successColor = AppTheme.success;
  static Color highlightColor = AppTheme.xp;
  static Gradient primaryGradient = AppTheme.primaryGradient;
}

// Legacy theme - use AppTheme.lightTheme instead
ThemeData primaryTheme = AppTheme.lightTheme;
