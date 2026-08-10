import 'package:flutter/material.dart';

class AppTheme {
  // --- MESAJ KARTLARI VE EKRANIYLA BİREBİR UYUMLU LACİVERT PALETİ ---
  
  // Light Mode Renkleri
  // static const Color primaryNavy = Color(0xFF08314D);       // Mesaj balonu & Buton Laciverti
  // static const Color darkNavy = Color(0xFF041B2A);          // Koyu Başlık Laciverti
  // static const Color secondaryNavy = Color(0xFF1E5276);     // Gradient İkinci Tonu
  // static const Color backgroundColor = Color(0xFFF4F6F9);   // Sayfa Zemin Rengi
  // static const Color surfaceColor = Color(0xFFFFFFFF);       // Kart ve Input Dolgu Rengi
  // static const Color textColor = Color(0xFF0F172A);          // Koyu Metin Rengi
  // static const Color subtitleColor = Color(0xFF64748B);      // İkincil Metin Rengi
  // static const Color hintColor = Color(0xFF94A3B8);          // İpucu Metin Rengi

  // // Dark Mode Renkleri
  // static const Color darkBackgroundColor = Color(0xFF0A192F); // Derin Gece Mavisi Zemin
  // static const Color darkSurfaceColor = Color(0xFF102A43);     // Koyu Kart ve Input Rengi
  // static const Color darkTextColor = Color(0xFFF8FAFC);        // Açık Renk Metin
  // static const Color darkSubtitleColor = Color(0xFF94A3B8);    // İkincil Metin Rengi
  // static const Color darkAccentBlue = Color(0xFF38BDF8);       // Canlı Açık Mavi Vurgu

  // // Efektler & Cam (Glassmorphism) Detayları
  // static const Color shadow = Color(0x1A08314D);

  // static const Color primaryNavy = Color.fromARGB(255, 38, 56, 68);       // Mesaj balonu & Buton Laciverti
  // static const Color darkNavy = Color.fromARGB(255, 31, 47, 57);          // Koyu Başlık Laciverti
  // static const Color secondaryNavy = Color.fromARGB(255, 56, 82, 97);     // Gradient İkinci Tonu
  // static const Color backgroundColor = Color.fromARGB(255, 251, 252, 252);   // Sayfa Zemin Rengi
  // static const Color surfaceColor = Color(0xFFFFFFFF);       // Kart ve Input Dolgu Rengi
  // static const Color textColor = Color.fromARGB(255, 0, 0, 0);          // Koyu Metin Rengi
  // static const Color subtitleColor = Color.fromARGB(255, 101, 117, 139);      // İkincil Metin Rengi
  // static const Color hintColor = Color(0xFF94A3B8);          // İpucu Metin Rengi

  // // Dark Mode Renkleri
  // static const Color darkBackgroundColor = Color.fromARGB(255, 1, 6, 12); // Derin Gece Mavisi Zemin
  // static const Color darkSurfaceColor = Color.fromARGB(255, 27, 34, 41);     // Koyu Kart ve Input Rengi
  // static const Color darkTextColor = Color(0xFFF8FAFC);        // Açık Renk Metin
  // static const Color darkSubtitleColor = Color(0xFF94A3B8);    // İkincil Metin Rengi
  // static const Color darkAccentBlue = Color.fromARGB(116, 54, 82, 139);       // Canlı Açık Mavi Vurgu



  static const Color primaryNavy = Color.fromARGB(255, 38, 27, 58);       // Mesaj balonu & Buton Laciverti
  static const Color darkNavy = Color.fromARGB(255, 126, 105, 162);      // Koyu Başlık Laciverti
  static const Color secondaryNavy = Color.fromARGB(255, 61, 47, 84);   // Gradient İkinci Tonu
  static const Color backgroundColor = Color.fromARGB(255, 251, 252, 252);   // Sayfa Zemin Rengi
  static const Color surfaceColor = Color(0xFFFFFFFF);       // Kart ve Input Dolgu Rengi
  static const Color textColor = Color.fromARGB(255, 0, 0, 0);          // Koyu Metin Rengi
  static const Color subtitleColor = Color.fromARGB(255, 49, 38, 68);    // İkincil Metin Rengi
  static const Color hintColor = Color.fromARGB(255, 151, 140, 179);          // İpucu Metin Rengi

  // Dark Mode Renkleri
  static const Color darkBackgroundColor = Color.fromARGB(255, 1, 6, 12); // Derin Gece Mavisi Zemin
  static const Color darkSurfaceColor = Color.fromARGB(255, 27, 34, 41);     // Koyu Kart ve Input Rengi
  static const Color darkTextColor = Color(0xFFF8FAFC);        // Açık Renk Metin
  static const Color darkSubtitleColor = Color.fromARGB(255, 157, 137, 179);    // İkincil Metin Rengi
  static const Color darkAccentBlue = Color.fromARGB(255, 49, 38, 68);      // Canlı Açık Mavi Vurgu


  // Efektler & Cam (Glassmorphism) Detayları
  static const Color shadow = Color.fromARGB(255, 67, 50, 96);

  // Ortak Uyarı ve Hata Renkleri
  static const Color errorColor = Color(0xFFEF4444);        // Kırmızımsı Hata Rengi
  static const Color successColor = Color(0xFF10B981);      // Başarı Rengi
  static const Color infoColor = primaryNavy;              // Yönlendirme ve Normal Bildirimler

  // Tipografi Boyutları
  static const double headlineFont1 = 36;
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

      iconTheme: const IconThemeData(
        color: primaryNavy,
        size: 24,
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryNavy,
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
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
        fillColor: const Color.fromARGB(255, 255, 255, 255),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color.fromARGB(159, 232, 226, 240)),
        ),
        
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color.fromARGB(174, 213, 203, 225)),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color.fromARGB(255, 27, 22, 63), width: 2),
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
          color: darkNavy,
        ),
        headlineMedium: TextStyle(
          fontSize: mediumFont,
          fontWeight: FontWeight.bold,
          color: darkNavy,
        ),
        bodyLarge: TextStyle(
          fontSize: smallFont,
          color: textColor,
        ),
        bodyMedium: TextStyle(
          fontSize: inputFont,
          color: subtitleColor,
        ),
      ),
    );
  }

  // --- DARK THEME CONFIGURATION ---
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: darkBackgroundColor,

      colorScheme: ColorScheme.fromSeed(
        seedColor: darkAccentBlue,
        primary: darkAccentBlue,
        secondary: secondaryNavy,
        surface: const Color.fromARGB(162, 20, 17, 26),
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

      iconTheme: const IconThemeData(
        color: darkAccentBlue,
        size: 24,
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkAccentBlue,
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryNavy,
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
        fillColor: const Color.fromARGB(255, 33, 27, 41),
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
          borderSide: const BorderSide(color: Color.fromARGB(255, 72, 51, 85)),
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
        bodyLarge: TextStyle(
          fontSize: smallFont,
          color: darkTextColor,
        ),
        bodyMedium: TextStyle(
          fontSize: inputFont,
          color: darkSubtitleColor,
        ),
      ),
    );
  }
}