import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const primary      = Color(0xFF1565C0); // blue 800
  static const primaryLight = Color(0xFF1E88E5); // blue 600
  static const primaryDark  = Color(0xFF0D47A1); // blue 900
  static const accent       = Color(0xFF00BCD4); // cyan

  // Neutrals
  static const white        = Color(0xFFFFFFFF);
  static const background   = Color(0xFFF5F7FA);
  static const surface      = Color(0xFFFFFFFF);
  static const border       = Color(0xFFE0E6ED);
  static const divider      = Color(0xFFF0F2F5);

  // Text
  static const textPrimary   = Color(0xFF1A1F2E);
  static const textSecondary = Color(0xFF6B7280);
  static const textHint      = Color(0xFFADB5BD);

  // Status
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error   = Color(0xFFEF4444);
  static const info    = Color(0xFF3B82F6);

  // Gradient
  static const List<Color> primaryGradient = [primary, primaryLight];
}
