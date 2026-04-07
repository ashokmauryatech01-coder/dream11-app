import 'package:flutter/material.dart';

class AppColors {
  // Clean White Theme with Red Primary (Dream11 inspired)
  static const Color primary = Color(0xFFD82D2D); // Red Primary
  static const Color secondary = Color(0xFFFFE5E5); // Light Red Background
  static const Color accent = Color(0xFFD82D2D); // Using Red as accent
  static const Color background = Color(0xFFFFFFFF); // Pure White
  static const Color text = Color(0xFF1A1A1A); // Dark Text
  static const Color textLight = Color(0xFF6B7280); // Light Grey Text
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color white70 = Color(0xB3FFFFFF); // 70% opacity white
  static const Color white60 = Color(0x99FFFFFF); // 60% opacity white
  static const Color success = Color(0xFF10B981); // Green for success
  static const Color error = Color(0xFFEF4444); // Red for error
  static const Color warning = Color(0xFFF59E0B); // Orange for warning
  static const Color border = Color(0xFFF3F4F6); // Light Border
  static const Color surface = Color(0xFFFFFFFF); // White surface
  static const Color shadow = Color(0x0A000000); // Very subtle shadow

  // Specific UI components
  static const Color teamHeader = Color(0xFFD82D2D);
  static const Color darkRectangle = Color(0xFFFFF5F5); // Very light red background
  static const Color btnTextColor = Color(0xFFFFFFFF);
  static const Color blue = Color(0xFFD82D2D);
  static const Color deepBlue = Color(0xFFB71C1C);
  static const Color selectedIcon = Color(0xFFD82D2D);
  static const Color unselectedIcon = Color(0xFF9CA3AF);
  
  // FLAT COLORS (No Gradients as requested)
  static const List<Color> primaryGradient = [Color(0xFFD82D2D), Color(0xFFD82D2D)];
  static const List<Color> secondaryGradient = [Color(0xFFFFE5E5), Color(0xFFFFE5E5)];
  static const List<Color> successGradient = [Color(0xFF10B981), Color(0xFF10B981)];
  static const List<Color> errorGradient = [Color(0xFFEF4444), Color(0xFFEF4444)];
  static const List<Color> warningGradient = [Color(0xFFF59E0B), Color(0xFFF59E0B)];
  static const List<Color> infoGradient = [Color(0xFFD82D2D), Color(0xFFD82D2D)];
}
