import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand — Custom Coral Rust (#DD5842)
  static const Color primary       = Color(0xFFDD5842);
  static const Color primaryLight  = Color(0xFFE57764); // Secondary tint
  static const Color primaryDark   = Color(0xFFB83E2A); // Deeper shade for contrasts
  static const Color accentWarm    = Color(0xFFE57764); // Accent

  // Keep legacy aliases
  static const Color primaryGreen  = primary;
  static const Color accentRed     = primary;
  static const Color riverBlue     = Color(0xFF5B8AF0);
  static const Color warmSand      = Color(0xFFFFF8F7); // Background

  // Semantic
  static const Color success  = Color(0xFF10B981);
  static const Color warning  = Color(0xFFF59E0B);
  static const Color error    = Color(0xFFDD5842);

  // Neutral
  static const Color surface        = Color(0xFFFFF8F8); // Background
  static const Color textPrimary    = Color(0xFF2D2D2D); // Text
  static const Color textSecondary  = Color(0xFF6B7280);
  static const Color border         = Color(0xFFE8D9D6);

  // Dark Theme Tokens
  static const Color darkBackground    = Color(0xFF121214);
  static const Color darkSurface       = Color(0xFF1C1C20);
  static const Color darkCard          = Color(0xFF222228);
  static const Color darkTextPrimary   = Color(0xFFF3F4F6);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkBorder        = Color(0xFF2E2E36);

  // Derived
  static const Color onPrimary      = Colors.white;
  static const Color cardBackground = Color(0xFFFFFFFF); // Card
}
