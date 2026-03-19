import 'package:flutter/material.dart';

class AppColors {
  // Vibrant Pink & Mint theme (Modern & Energetic)
  static const Color primary = Color(0xFFFF187C); // Vibrant Pink/Magenta
  static const Color secondary = Color(0xFF63DAB9); // Fresh Mint Green
  static const Color accent = Color(0xFF63DAB9); // Using Mint as accent too
  static const Color background = Color(0xFFFDFDFD); // Cleanest white
  static const Color text = Color(0xFF1F1F1F); // Dark Slate Text
  static const Color textLight = Color(0xFF8E8E8E); // Muted Grey Text
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color success = Color(0xFF63DAB9); // Mint for success
  static const Color error = Color(0xFFFF187C); // Pink for error/urgency
  static const Color warning = Color(0xFFF97316);
  static const Color border = Color(0xFFEEEEEE);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color shadow = Color(0x0D000000); // Very subtle shadow

  // Specific UI components
  static const Color teamHeader = Color(0xFFFF187C);
  static const Color darkRectangle = Color(0xFF1F1F1F);
  static const Color btnTextColor = Color(0xFFFFFFFF);
  static const Color blue = Color(0xFF3B82F6);
  static const Color deepBlue = Color(0xFF1D4ED8);
  static const Color selectedIcon = Color(0xFFFF187C);
  static const Color unselectedIcon = Color(0xFFBDBDBD);
  
  // FLAT COLORS (No Gradients as requested)
  static const List<Color> primaryGradient = [Color(0xFFFF187C), Color(0xFFFF187C)];
  static const List<Color> secondaryGradient = [Color(0xFF63DAB9), Color(0xFF63DAB9)];
  static const List<Color> successGradient = [Color(0xFF63DAB9), Color(0xFF63DAB9)];
}
