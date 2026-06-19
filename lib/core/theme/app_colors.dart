// lib/core/theme/app_colors.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppColors {
  // ===== 🟠 Orange Palette =====
  static const Color primaryOrange = Color(0xffE6820A);
  static const Color lightOrange = Color(0xFFFF8C42);
  static const Color darkOrange = Color(0xffE6820A);
  static const Color softOrange = Color(0xFFFFF3EC);

  // ===== ⚫ Text =====
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textGrey = Color(0xFF9E9E9E);

  // ===== ⚪ Backgrounds =====
  static const Color white = Colors.white;
  static const Color backgroundGrey = Color(0xFFF5F6FA);
  static Color get cardWhite => Get.isDarkMode ? darkSurface : Colors.white;

  // ===== Dark SaaS Palette =====
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkSurfaceElevated = Color(0xFF1F2937);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFF9FAFB);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);

  // ===== 🔴 Status Colors =====
  static const Color error = Color(0xFFE63946);
  static const Color success = Color(0xFF06D6A0);
  static const Color warning = Color(0xFFFFB703);

  // ===== 🎨 Gradients =====
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [lightOrange, primaryOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ===== 📦 Aliases =====
  static const Color primaryColor = primaryOrange;
  static const Color secondaryColor = lightOrange;
  static Color get backgroundColor =>
      Get.isDarkMode ? darkBackground : backgroundGrey;
  static Color get textPrimary => Get.isDarkMode ? darkTextPrimary : textDark;
  static Color get textSecondary =>
      Get.isDarkMode ? darkTextSecondary : textGrey;
  static const Color successColor = success;
}
