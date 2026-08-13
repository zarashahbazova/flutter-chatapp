import 'package:flutter/material.dart';

class AppTheme {
  // --- Yeni Ana Renk Tanımı ---
  // Renginiz: #C0BBC8 (Soft Lila/Gri Nötr)
  static const Color brandColor = Color.fromARGB(255, 178, 181, 255);

  // Değişken isimleri ve imzaları birebir korundu
  static const Color primaryNavy = Color.fromARGB(255, 96, 106, 171); // Ana Vurgu / Butonlar - Koyu Antrasit/Kömür
  static const Color darkNavy = Color(0xFF19181B); // Başlık/İkon - Siyah
  static const Color secondaryNavy = Color.fromARGB(255, 104, 102, 179); // İkincil Ton - #C0BBC8

  static const Color backgroundColor = Color(0xFFF7F6F8); // Sayfa Zemin Rengi - Çok Hafif Soft Gri
  static const Color surfaceColor = Color(0xFFFFFFFF); // Kart ve Input Dolgu Rengi - Beyaz

  static const Color textColor = Color(0xFF19181B); // Ana Metin - Siyah/Koyu Antrasit
  static const Color subtitleColor = Color.fromARGB(255, 127, 136, 194); // İkincil Metin - Nötr Gri
  static const Color hintColor = Color(0xFFA29EA8); // İpucu Metni - Açık Gri

  // Dark Mode Renkleri
  static const Color darkBackgroundColor = Color(0xFF121114); // Derin Koyu Zemin
  static const Color darkSurfaceColor = Color(0xFF1D1C21); // Koyu Kart / Input Rengi
  static const Color darkTextColor = Color(0xFFF2F1F4); // Ana Metin - Açık Krem/Beyaz
  static const Color darkSubtitleColor = Color(0xFFA29EA8); // İkincil Metin - Açık Gri
  static const Color darkAccentBlue = brandColor; // Koyu Mod Vurgu - #C0BBC8 (Eski Accent yerine)
  static const Color darkpurple2 = Color(0xFF2C2A31); // Ayırıcı / Kenarlık Rengi

  // Efekt Rengi
  static const Color shadow = Color(0x0D000000);

  // Ortak Uyarı ve Hata Renkleri
  static const Color errorColor = Color(0xFFEF4444); // Kırmızımsı Hata Rengi
  static const Color successColor = Color(0xFF10B981); // Başarı Rengi
  static const Color infoColor = primaryNavy; // Yönlendirme ve Normal Bildirimler

  // Tipografi Boyutları
  static const double headlineFont1 = 34;
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: isError ? Colors.white : (isDark ? darkBackgroundColor : Colors.white),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isError
            ? errorColor
            : (isDark ? darkAccentBlue : primaryNavy),
        behavior: SnackBarBehavior.floating,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        secondary: secondaryNavy,
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
          fontWeight: FontWeight.w700,
        ),
      ),

      iconTheme: const IconThemeData(color: primaryNavy, size: 24),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryNavy,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryNavy,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          elevation: 0,
          shadowColor: shadow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        prefixIconColor: subtitleColor,
        suffixIconColor: subtitleColor,
        filled: true,
        fillColor: const Color(0xFFF0EFF2), // Hafif #C0BBC8 esintili açık input dolgusu
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2DFE7)),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2DFE7)),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryNavy, width: 1.6),
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
          color: textColor,
        ),
        headlineMedium: TextStyle(
          fontSize: mediumFont,
          fontWeight: FontWeight.bold,
          color: textColor,
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
      scaffoldBackgroundColor: darkBackgroundColor,

      colorScheme: ColorScheme.fromSeed(
        seedColor: darkAccentBlue,
        primary: const Color.fromARGB(225, 96, 106, 171),
        secondary: secondaryNavy,
        surface: const Color.fromARGB(255, 16, 15, 18),
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
          fontWeight: FontWeight.w700,
        ),
      ),

      iconTheme: const IconThemeData(color: darkAccentBlue, size: 24),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkAccentBlue,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryNavy, // Koyu modda #C0BBC8 öne çıkan buton
          foregroundColor: darkBackgroundColor, // Yazı rengi koyu
          minimumSize: const Size(double.infinity, 52),
          elevation: 0,
          shadowColor: Colors.black45,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        prefixIconColor: darkSubtitleColor,
        suffixIconColor: darkSubtitleColor,
        filled: true,
        fillColor: darkSurfaceColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkpurple2),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkpurple2),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkAccentBlue, width: 1.6),
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
        bodyMedium: TextStyle(fontSize: inputFont, color: darkSubtitleColor),
      ),
    );
  }
}