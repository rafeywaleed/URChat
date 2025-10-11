import 'dart:ui';

import 'package:flutter/src/painting/text_style.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dart:ui';

import 'package:flutter/src/painting/text_style.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatFonts {
  static const Map<String, String> availableFonts = {
    'pixelify': 'Pixelify Sans',
    'pressStart': 'Press Start 2P',
    'poppins': 'Poppins',
    'inter': 'Inter',
    'roboto': 'Roboto',
  };

  static String get defaultFont => 'pixelify';

  static TextStyle getTextStyle(String fontKey, {TextStyle? baseStyle}) {
    TextStyle adjustedStyle = baseStyle ?? const TextStyle();

    if (fontKey == 'pressStart') {
      adjustedStyle = adjustedStyle.copyWith(
        fontSize: (adjustedStyle.fontSize ?? 14) - 4,
      );
    }

    switch (fontKey) {
      case 'pixelify':
        return GoogleFonts.pixelifySans(textStyle: adjustedStyle);
      case 'pressStart':
        return GoogleFonts.pressStart2p(textStyle: adjustedStyle);
      case 'poppins':
        return GoogleFonts.poppins(textStyle: adjustedStyle);
      case 'inter':
        return GoogleFonts.inter(textStyle: adjustedStyle);
      case 'roboto':
        return GoogleFonts.roboto(textStyle: adjustedStyle);
      default:
        return GoogleFonts.pixelifySans(textStyle: adjustedStyle);
    }
  }
}
