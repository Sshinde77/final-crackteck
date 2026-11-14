import 'package:flutter/material.dart';

/// App-wide color constants
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // Primary Colors
  static const Color primary = Color(0xFF020F37);
  static const Color secondary = Color(0xFFEE2D2A);
  static const Color primarySurface = Color(0xFFF1F3F8);
  static const Color secondarySurface = Color(0xFFFFF1F0);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  // Kept as an alias for screens that still use the older semantic name.
  static const Color darkGreen = primary;
  static const Color lightGrey = Color(0xFF9E9E9E);
  static const Color borderGrey = Color(0xFFE0E0E0);

  // Button Colors
  static const Color buttonBackground = primary;
  static const Color buttonText = white;
  static const Color buttonIcon = white;

  // Input Field Colors
  static const Color inputBackground = white;
  static const Color inputBorder = borderGrey;
  static const Color inputFocusedBorder = primary;
  static const Color inputText = black;
  static const Color inputLabel = lightGrey;

  //Badge Colors
  static const Color badgeBackground = secondary;
}
