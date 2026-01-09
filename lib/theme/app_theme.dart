import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand & Zinc Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  
  static const Color zinc50 = Color(0xFFFAFAFA);
  static const Color zinc100 = Color(0xFFF4F4F5);
  static const Color zinc200 = Color(0xFFE4E4E7);
  static const Color zinc300 = Color(0xFFD4D4D8);
  static const Color zinc400 = Color(0xFFA1A1AA);
  static const Color zinc500 = Color(0xFF71717A); // Secondary Text
  static const Color zinc600 = Color(0xFF52525B);
  static const Color zinc700 = Color(0xFF3F3F46);
  static const Color zinc800 = Color(0xFF27272A);
  static const Color zinc900 = Color(0xFF18181B); // Primary Text

  // Accent & Status
  static const Color accentOrange = Color(0xFFEA580C); // Orange-600
  static const Color primaryBrand = black; // FAB & Buttons Anchor
  static const Color textMain = zinc900;
  static const Color textSub = zinc500;
  
  // Status Colors (ShadCN Tints)
  static const Color statusSafeBg = Color(0xFFF0FDF4); // Green-50
  static const Color statusSafeText = Color(0xFF15803D); // Green-700
  
  static const Color statusWarningBg = Color(0xFFFFF7ED); // Orange-50
  static const Color statusWarningText = Color(0xFFC2410C); // Orange-700
  
  static const Color statusExpiredBg = Color(0xFFFEF2F2); // Red-50
  static const Color statusExpiredText = Color(0xFFB91C1C); // Red-700

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryBrand,
    scaffoldBackgroundColor: zinc100, // Zinc-100 Background for contrast
    
    colorScheme: const ColorScheme.light(
      primary: primaryBrand,
      onPrimary: white,
      surface: white,
      onSurface: zinc900,
      error: statusExpiredText,
      outline: zinc200,
    ),
    
    // Typography
    textTheme: TextTheme(
      displayLarge: GoogleFonts.manrope(
        fontSize: 32, fontWeight: FontWeight.bold, color: zinc900, height: 1.1
      ),
      titleLarge: GoogleFonts.manrope(
        fontSize: 22, fontWeight: FontWeight.bold, color: zinc900
      ),
      bodyLarge: GoogleFonts.manrope(
        fontSize: 16, fontWeight: FontWeight.w500, color: zinc900
      ),
      bodyMedium: GoogleFonts.manrope(
        fontSize: 14, fontWeight: FontWeight.w500, color: zinc900
      ),
      labelSmall: GoogleFonts.manrope(
        fontSize: 12, fontWeight: FontWeight.w500, color: zinc500
      ),
      labelMedium: GoogleFonts.manrope(
        fontSize: 14, fontWeight: FontWeight.w500, color: zinc500
      ),
    ),

    // App Bar
    appBarTheme: AppBarTheme(
      backgroundColor: white,
      foregroundColor: zinc900,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.manrope(
        fontSize: 17, fontWeight: FontWeight.w600, color: zinc900
      ),
      iconTheme: const IconThemeData(color: zinc900),
      scrolledUnderElevation: 0,
    ),

    // Card
    cardTheme: CardThemeData(
      color: white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: zinc200, width: 1),
      ),
    ),
    
    // Input
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: zinc200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: zinc200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: zinc300, width: 1),
      ),
      hintStyle: GoogleFonts.manrope(color: zinc500),
    ),

    // Text Selection
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: accentOrange, // Use Accent for interactions
      selectionColor: accentOrange.withValues(alpha: 0.2), // Fixed deprecation
    ),

    // Elevated Button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBrand, // Black
        foregroundColor: white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.manrope(fontWeight: FontWeight.bold),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    ),
    
    // Outlined Button
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: zinc900,
        side: const BorderSide(color: zinc200),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(vertical: 16),
      )
    ),

    // Floating Action Button
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: accentOrange, // Restored to Orange
      foregroundColor: white,
      elevation: 2,
      shape: CircleBorder(),
    ),
  );
}
