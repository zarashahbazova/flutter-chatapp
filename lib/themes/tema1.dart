import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color.fromARGB(255, 4, 47, 82);
  static const Color backgroundColor = Color(0xFFF8F9FD);
  static const Color textColor = Color(0xFF222222);
  static const Color headlineColor1 = Color.fromARGB(0, 0, 0, 0);
  static const Color buttonColor1 = Color.fromARGB(0, 55, 70, 243);
  static const Color darkcolor1 = Color.fromARGB(255, 4, 28, 44);
  static const Color darkcolor2 = Color.fromARGB(155, 10, 57, 91);
  static const Color lightcolor1 = Color.fromARGB(55, 13, 86, 138);
  static const Color lightcolor2 = Color.fromARGB(15, 13, 86, 138);
  static const Color iconColor = Color.fromARGB(155, 5, 55, 91);
  static const Color butonRengi = Color.fromARGB(255, 8, 49, 77);

  static const double headlineFont1 = 36;
  static const double headlineFont2 = 30;
  static const double largeFont = 26;
  static const double mediumFont = 22;
  static const double smallFont = 16;
  static const double inputFont = 12;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      scaffoldBackgroundColor: backgroundColor,

      colorScheme: ColorScheme.fromSeed(
        seedColor: darkcolor2,
        brightness: Brightness.light,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: true,
      ),
      iconTheme: const IconThemeData(color:butonRengi),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: butonRengi,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        prefixIconColor: butonRengi,
        suffixIconColor: butonRengi,
        filled: true,
        fillColor: lightcolor2,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightcolor1),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkcolor2, width: 2),
        ),

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        
      ),

      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: textColor),
      ),
    );
  }
}
