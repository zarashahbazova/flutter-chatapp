import 'package:flutter/material.dart';

class AppTheme {
  // --- LACİVERT PALETİ (NAVY PALETTE) ---
  
  // Ana Renkler
  static const Color primaryNavy = Color(0xFF0A192F);       // Derin Gece Laciverti
  static const Color secondaryNavy = Color(0xFF102A43);     // Orta Ton Lacivert
  static const Color accentBlue = Color.fromARGB(255, 8, 36, 82);        // Canlı Canlandırıcı Mavi (Vurgu)
  static const Color lightAccent = Color(0xFF60A5FA);       // Açık Mavi Detaylar

  // Zemin ve Metin Renkleri
  static const Color backgroundColor = Color(0xFFF8FAFC);   // Ferah, Çok Hafif Mavi-Gri Zemin
  static const Color surfaceColor = Color(0xFFFFFFFF);       // Kart ve Input Dolgu Rengi
  static const Color textColor = Color(0xFF0F172A);          // Koyu Kömür / Lacivert Metin
  static const Color subtitleColor = Color(0xFF475569);      // İkincil Metin Rengi

  // Buton ve Etkileşim Renkleri
  static const Color buttonNavy = Color.fromARGB(255, 6, 25, 79);        // Klasik Şık Lacivert Buton
  static const Color buttonHover = Color.fromARGB(255, 9, 27, 86);

  // Efektler & Cam (Glassmorphism) Detayları
  static const Color glass = Color(0x1F1E3A8A);             // %12 Opaklık Lacivert Yansıma
  static const Color glassBorder = Color(0x333B82F6);       // %20 Opaklık Mavi Çerçeve
  static const Color shadow = Color(0x1A0A192F);            // Yumuşak Lacivert Gölge

  // Ortak Uyarı ve Hata Renkleri
  static const Color errorColor = Color(0xFFEF4444);
  static const Color successColor = Color(0xFF10B981);

  // Tipografi Boyutları
  static const double headlineFont1 = 36;
  static const double headlineFont2 = 30;
  static const double largeFont = 26;
  static const double mediumFont = 22;
  static const double smallFont = 16;
  static const double inputFont = 14;

  // SnackBar Yardımcısı
  static void showSnackBar(
    BuildContext context, {
    required String message,
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isError ? errorColor : successColor,
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // --- LIGHT THEMA CONFIGURATION ---
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundColor,

      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryNavy,
        primary: buttonNavy,
        secondary: accentBlue,
        surface: surfaceColor,
        brightness: Brightness.light,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: primaryNavy,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: primaryNavy,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      iconTheme: const IconThemeData(
        color: secondaryNavy,
        size: 24,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(235, 11, 22, 54),
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
        prefixIconColor: secondaryNavy,
        suffixIconColor: secondaryNavy,
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        
        // Varsayılan kenarlık
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        
        // Etkin kenarlık
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),

        // Odaklanılmış (Focused) kenarlık
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color.fromARGB(55, 8, 36, 82), width: 2),
        ),

        // Hata kenarlığı
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: errorColor),
        ),
      ),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: headlineFont1,
          fontWeight: FontWeight.bold,
          color: primaryNavy,
        ),
        headlineMedium: TextStyle(
          fontSize: mediumFont,
          fontWeight: FontWeight.bold,
          color: primaryNavy,
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
}