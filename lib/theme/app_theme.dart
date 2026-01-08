import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  
  // Custom Brand Colors
  static const Color primaryBrand = Color(0xFFD6944E); // Highlight/Buttons
  static const Color bgBrand = Color(0xFFF4F4F5); // Main Background (Zinc-100)
  
  // Zinc Colors (for text/borders)
  static const Color zinc50 = Color(0xFFFAFAFA);
  static const Color zinc100 = Color(0xFFF4F4F5);
  static const Color zinc200 = Color(0xFFE4E4E7);
  static const Color zinc300 = Color(0xFFD4D4D8);
  static const Color zinc500 = Color(0xFF71717A);
  static const Color zinc900 = Color(0xFF18181B);

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryBrand,
    scaffoldBackgroundColor: bgBrand,
    colorScheme: const ColorScheme.light(
      primary: primaryBrand,
      onPrimary: white,
      surface: white,
      onSurface: black,
      error: Color(0xFFEF4444),
      outline: zinc200,
    ),
    
    // Typography
    textTheme: TextTheme(
      displayLarge: GoogleFonts.manrope(
        fontSize: 32, fontWeight: FontWeight.bold, color: black, height: 1.1
      ),
      titleLarge: GoogleFonts.manrope(
        fontSize: 22, fontWeight: FontWeight.bold, color: black
      ),
      bodyLarge: GoogleFonts.manrope(
        fontSize: 16, color: zinc900
      ),
      bodyMedium: GoogleFonts.manrope(
        fontSize: 14, color: zinc900
      ),
      labelSmall: GoogleFonts.manrope(
        fontSize: 12, fontWeight: FontWeight.w500, color: zinc500
      ),
    ),

    // App Bar
    appBarTheme: AppBarTheme(
      backgroundColor: bgBrand,
      foregroundColor: black,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.manrope(
        fontSize: 17, fontWeight: FontWeight.w600, color: black
      ),
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
      fillColor: zinc50,
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
        borderSide: const BorderSide(color: primaryBrand, width: 1.5),
      ),
      labelStyle: GoogleFonts.manrope(color: zinc500),
    ),

    // Text Selection
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: primaryBrand,
      selectionColor: primaryBrand.withValues(alpha: 0.3),
    ),

    // Elevated Button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBrand,
        foregroundColor: white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.manrope(fontWeight: FontWeight.bold),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    ),

    // Floating Action Button
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryBrand,
      foregroundColor: white,
      elevation: 4,
      shape: CircleBorder(),
    ),
  );
  
  // Status Colors
  static const Color statusSafe = Color(0xFF22C55E); // Green 500
  static const Color statusWarning = primaryBrand; // Use brand highlight
  static const Color statusExpired = Color(0xFFEF4444); // Red 500
}
