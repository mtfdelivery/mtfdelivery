import 'package:flutter/material.dart';

/// App color palette - Green-focused food delivery theme
class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primary = Color(0xFF2ECC71); // Emerald Green
  static const Color primaryLight = Color(0xFF58D68D); // Light Green
  static const Color primaryDark = Color(0xFF27AE60); // Forest Green

  // Secondary Colors
  static const Color secondary = Color(0xFFF39C12); // Orange (food accent)
  static const Color secondaryLight = Color(0xFFF5B041);

  // Accent Colors
  static const Color accent = Color(0xFF3498DB); // Blue
  static const Color accentLight = Color(0xFF5DADE2);

  // Background Colors
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F3F4);

  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status Colors
  static const Color success = Color(0xFF2ECC71);
  static const Color error = Color(0xFFE74C3C);
  static const Color warning = Color(0xFFF39C12);
  static const Color info = Color(0xFF3498DB);

  // Border & Divider
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFEEEEEE);

  // Shadow
  static const Color shadow = Color(0x1A000000);

  // Rating Star
  static const Color starFilled = Color(0xFFFFB800);
  static const Color starEmpty = Color(0xFFE0E0E0);

  // Shimmer
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);

  // Category Colors (for food categories)
  static const Color categoryPizza = Color(0xFFE74C3C);
  static const Color categoryBurger = Color(0xFFF39C12);
  static const Color categorySushi = Color(0xFF9B59B6);
  static const Color categoryPasta = Color(0xFFE67E22);
  static const Color categorySalad = Color(0xFF2ECC71);
  static const Color categoryDessert = Color(0xFFE91E63);
  static const Color categoryDrinks = Color(0xFF3498DB);
  static const Color categoryAsian = Color(0xFFFF5722);
}
