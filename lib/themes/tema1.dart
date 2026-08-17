import 'package:flutter/material.dart';

class AppTheme {
  // --- Ana Marka Renkleri ---
  static const Color brandColor = Color.fromARGB(255, 130, 128, 187);
  static const Color darkGrey = Color.fromARGB(255, 0, 0, 0);
  static const Color primaryNavy = Color.fromARGB(255, 152, 156, 203);
  static const Color darkNavy = Color.fromARGB(255, 27, 26, 30);
  static const Color secondaryNavy = Color.fromARGB(255, 151, 149, 202);
  static const Color lightBrandColor = Color.fromARGB(155, 130, 128, 187);

  static const Color backgroundColor = Color(0xFFF7F6F8);
  static const Color surfaceColor = Color(0xFFFFFFFF);

  static const Color textColor = Color(0xFF19181B);
  static const Color subtitleColor = Color.fromARGB(255, 127, 136, 194);
  static const Color hintColor = Color(0xFFA29EA8);

  // Dark Mode Renkleri
  static const Color darkBackgroundColor = Color(0xFF121114);
  static const Color darkSurfaceColor = Color(0xFF1D1C21);
  static const Color darkTextColor = Color(0xFFF2F1F4);
  static const Color darkSubtitleColor = Color(0xFFA29EA8);
  static const Color darkAccentBlue = brandColor;
  static const Color darkpurple2 = Color(0xFF2C2A31);

  // Profil & Kart Tasarımına Özel Renkler
  static const Color sectionHeaderLight = Color(0xFF827E8C);
  static const Color sectionHeaderDark = Color(0xFF8E8B94);

  static const Color iconBgLight = Color(0xFFF3F2F5);
  static const Color iconBgDark = Color(0xFF141316);
  static const Color iconBgDarkAlt = Color.fromARGB(255, 87, 84, 92);

  static const Color iconFgLight = Color(0xFF2C2A31);
  static const Color iconFgDark = Colors.white70;

  static const Color avatarBorderLight = Color(0xFFE2E0E7);
  static const Color avatarBorderDark = Color(0xFF2C2A31);

  static const Color cardBorderLight = Color(0xFFFFFFFF);
  static const Color cardBorderDark = Color(0xFF000000);

  // Efekt Rengi
  static const Color shadow = Color(0x0D000000);

  // Ortak Uyarı ve Hata Renkleri (Tek Tip & Nötr)
  static const Color errorColor = Color(0xFFEF4444);
  static const Color successColor = Color(0xFF10B981);
  static const Color infoColor = Color.fromARGB(95, 147, 151, 195);

  // Tipografi Boyutları
  static const double headlineFont1 = 34;
  static const double headlineFont2 = 30;
  static const double largeFont = 26;
  static const double mediumFont = 22;
  static const double smallFont = 16;
  static const double inputFont = 14;

  // --- Ortak Stil ve Renk Yardımcıları ---
  static Color getSurfaceColor(bool isDark) =>
      isDark ? darkSurfaceColor : surfaceColor;

  static Color getSectionHeaderColor(bool isDark) =>
      isDark ? sectionHeaderDark : sectionHeaderLight;

  static Color getIconBg(bool isDark) =>
      isDark ? iconBgDark : iconBgLight;

  static Color getIconFg(bool isDark) =>
      isDark ? iconFgDark : iconFgLight;

  static Color getCardBorder(bool isDark) =>
      isDark ? cardBorderDark : cardBorderLight;

  static Color getAvatarBorder(bool isDark) =>
      isDark ? avatarBorderDark : avatarBorderLight;

  // 🟣 Sadece Login Sayfası İçin Renkli Mor Buton
  static ButtonStyle loginButtonStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: brandColor,
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 50),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // ⚫ Diğer Tüm Sayfalar İçin Koyu/Açık Kontrast Buton
  static ButtonStyle standardButtonStyle(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return ElevatedButton.styleFrom(
      backgroundColor: lightBrandColor,
      foregroundColor: isDark ? const Color(0xFF121114) : Colors.white,
      minimumSize: const Size(double.infinity, 50),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      textStyle: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  static BoxDecoration profileCardDecoration(bool isDark) {
    return BoxDecoration(
      color: getSurfaceColor(isDark),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: getCardBorder(isDark),
        width: 1.1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha(isDark ? 50 : 6),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // Tek Tip SnackBar Yardımcısı: Hatalar kırmızı, normal bildirimler nötr gri
  static void showSnackBar(
    BuildContext context, {
    required String message,
    bool isError = false,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
        backgroundColor: isError
            ? const Color.fromARGB(155, 164, 26, 26)
            : (isDark ? const Color.fromARGB(155, 50, 48, 56) : const Color.fromARGB(125, 80, 77, 89)),
        behavior: SnackBarBehavior.floating,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // --- LIGHT THEME ---
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color.fromARGB(255, 253, 253, 255),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryNavy,
        primary: primaryNavy,
        secondary: secondaryNavy,
        surface: surfaceColor,
        onSurface: const Color.fromARGB(255, 0, 0, 0),
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
          fontSize: 19,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      iconTheme: const IconThemeData(color: primaryNavy, size: 24),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color.fromARGB(255, 99, 107, 159),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        prefixIconColor: const Color(0xFF827E8C),
        suffixIconColor: const Color(0xFF827E8C),
        filled: true,
        fillColor: const Color.fromARGB(255, 246, 246, 251),
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
          borderSide: const BorderSide(color: Color.fromARGB(255, 245, 243, 249)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryNavy, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color.fromARGB(255, 129, 13, 13)),
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
        bodyLarge: TextStyle(fontSize: smallFont, color: Color.fromARGB(255, 0, 0, 0)),
        bodyMedium: TextStyle(fontSize: inputFont, color: Color.fromARGB(255, 0, 0, 0)),
      ),
    );
  }

  // --- DARK THEME ---
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
          fontSize: 19,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      iconTheme: const IconThemeData(color: darkAccentBlue, size: 24),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color.fromARGB(255, 142, 145, 213),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        prefixIconColor: const Color(0xFF8E8B94),
        suffixIconColor: const Color(0xFF8E8B94),
        filled: true,
        fillColor: const Color.fromARGB(255, 25, 25, 29),
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
          borderSide: const BorderSide(color: Color.fromARGB(255, 12, 11, 13)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkAccentBlue, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color.fromARGB(255, 121, 22, 22)),
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