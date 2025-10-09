import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final _retroPixelTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFFF8F8E8), // soft retro beige
  fontFamily: GoogleFonts.pressStart2p().fontFamily,
  textTheme: TextTheme(
    titleLarge: GoogleFonts.pressStart2p(
      fontSize: 14,
      color: const Color(0xFF1A1A1A),
      letterSpacing: 1.5,
    ),
    bodyMedium: GoogleFonts.shareTechMono(
      fontSize: 13,
      color: const Color(0xFF222222),
    ),
  ),
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF7AA22E), // soft green pixel tone
    secondary: Color(0xFF556B2F),
    background: Color(0xFFF8F8E8),
    surface: Color(0xFFE8E8D8),
    onSurface: Color(0xFF222222),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: const Color(0xFFE0E0C0),
    elevation: 0,
    centerTitle: true,
    titleTextStyle: GoogleFonts.pressStart2p(
      fontSize: 12,
      color: const Color(0xFF1A1A1A),
    ),
    iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
  ),
  cardTheme: CardThemeData(
    color: const Color(0xFFE8E8D8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(2),
      side: const BorderSide(color: Color(0xFF1A1A1A), width: 1),
    ),
    elevation: 0,
  ),
  buttonTheme: const ButtonThemeData(
    shape: RoundedRectangleBorder(),
    buttonColor: Color(0xFF7AA22E),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFF7AA22E),
    foregroundColor: Color(0xFF000000),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(2)),
      side: BorderSide(color: Color(0xFF1A1A1A), width: 1),
    ),
  ),
);
