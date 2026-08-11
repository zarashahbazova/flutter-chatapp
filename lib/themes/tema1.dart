import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryNavy = Color.fromARGB(
    255,
    38,
    27,
    58,
  ); // Mesaj balonu & Buton Laciverti
  static const Color darkNavy = Color.fromARGB(255, 0, 0, 0); // Koyu Başlık Laciverti
  static const Color secondaryNavy = Color.fromARGB(
    255,
    61,
    47,
    84,
  ); // Gradient İkinci Tonu
  static const Color backgroundColor = Color.fromARGB(
    255,
    251,
    252,
    252,
  ); // Sayfa Zemin Rengi
  static const Color surfaceColor = Color(
    0xFFFFFFFF,
  ); // Kart ve Input Dolgu Rengi
  static const Color textColor = Color.fromARGB(
    255,
    0,
    0,
    0,
  ); // Koyu Metin Rengi
  static const Color subtitleColor = Color.fromARGB(
    255,
    49,
    38,
    68,
  ); // İkincil Metin Rengi
  static const Color hintColor = Color.fromARGB(
    255,
    151,
    140,
    179,
  ); // İpucu Metin Rengi

  // Dark Mode Renkleri
  static const Color darkBackgroundColor = Color.fromARGB(
    255,
    1,
    6,
    12,
  ); // Derin Gece Mavisi Zemin
  static const Color darkSurfaceColor = Color.fromARGB(
    255,
    30,
    27,
    41,
  ); // Koyu Kart ve Input Rengi
  static const Color darkTextColor = Color(0xFFF8FAFC); // Açık Renk Metin
  static const Color darkSubtitleColor = Color.fromARGB(
    255,
    52,
    43,
    61,
  ); // İkincil Metin Rengi
  static const Color darkAccentBlue = Color.fromARGB(
    255,
    49,
    38,
    68,
  ); // Canlı Açık Mavi Vurgu
  static const Color darkpurple2 = Color.fromARGB(255, 53, 43, 71); 
  // Efektler & Cam (Glassmorphism) Detayları
  static const Color shadow = Color.fromARGB(255, 67, 50, 96);

  // Ortak Uyarı ve Hata Renkleri
  static const Color errorColor = Color(0xFFEF4444); // Kırmızımsı Hata Rengi
  static const Color successColor = Color(0xFF10B981); // Başarı Rengi
  static const Color infoColor =
      primaryNavy; // Yönlendirme ve Normal Bildirimler

  // Tipografi Boyutları
  static const double headlineFont1 = 34;
  static const double headlineFont2 = 30;
  static const double largeFont = 26;
  static const double mediumFont = 22;
  static const double smallFont = 16;
  static const double inputFont = 14;

  // SnackBar Yardımcısı (Hatalar Kırmızımsı, Yönlendirmeler Lacivert/Mavi)
  static void showSnackBar(
    BuildContext context, {
    required String message,
    bool isError = false,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isError
            ? errorColor
            : (isDark ? darkAccentBlue : infoColor),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // --- LIGHT THEME CONFIGURATION ---
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundColor,

      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryNavy,
        primary: primaryNavy,
        secondary: const Color.fromARGB(255, 53, 44, 69),
        surface: surfaceColor,
        onSurface: textColor,
        brightness: Brightness.light,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: darkNavy,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: darkNavy,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      iconTheme: const IconThemeData(color: primaryNavy, size: 24),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryNavy,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryNavy,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          elevation: 2,
          shadowColor: shadow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        prefixIconColor: subtitleColor,
        suffixIconColor: subtitleColor,
        filled: true,
        fillColor: const Color.fromARGB(255, 250, 249, 253),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color.fromARGB(159, 232, 226, 240),
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color.fromARGB(202, 213, 203, 225),
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color.fromARGB(208, 82, 79, 110),
            width: 2,
          ),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: errorColor),
        ),
      ),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: headlineFont1,
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 0, 0, 0),
        ),
        headlineMedium: TextStyle(
          fontSize: mediumFont,
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 0, 0, 0),
        ),
        bodyLarge: TextStyle(fontSize: smallFont, color: textColor),
        bodyMedium: TextStyle(fontSize: inputFont, color: subtitleColor),
      ),
    );
  }

  // --- DARK THEME CONFIGURATION ---
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color.fromARGB(255, 2, 1, 7),

      colorScheme: ColorScheme.fromSeed(
        seedColor: darkAccentBlue,
        primary: darkAccentBlue,
        secondary: secondaryNavy,
        surface: const Color.fromARGB(255, 20, 17, 26),
        onSurface: darkTextColor,
        brightness: Brightness.dark,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: darkTextColor,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: darkTextColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      iconTheme: const IconThemeData(color: darkAccentBlue, size: 24),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkAccentBlue,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 52, 40, 75),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          elevation: 4,
          shadowColor: Colors.black45,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        prefixIconColor: darkSubtitleColor,
        suffixIconColor: darkSubtitleColor,
        filled: true,
        fillColor: const Color.fromARGB(255, 7, 5, 12),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color.fromARGB(255, 39, 30, 59)),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color.fromARGB(255, 26, 19, 31)),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkAccentBlue, width: 2),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: errorColor),
        ),
      ),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: headlineFont1,
          fontWeight: FontWeight.bold,
          color: darkTextColor,
        ),
        headlineMedium: TextStyle(
          fontSize: mediumFont,
          fontWeight: FontWeight.bold,
          color: darkTextColor,
        ),
        bodyLarge: TextStyle(fontSize: smallFont, color: darkTextColor),
        bodyMedium: TextStyle(
          fontSize: inputFont,
          color: Color.fromARGB(255, 219, 218, 220),
        ),
      ),
    );
  }
}
