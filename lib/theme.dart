import 'package:flutter/material.dart';

class AppColors {
  static Color primaryColor = Colors.blueGrey;
  static Color primaryAccent = Colors.grey.shade900;
  static Color secondaryColor = Colors.deepOrange.shade300;
  static Color secondaryAccent = Colors.deepOrange.shade200;
  static Color titleBarColor = Colors.grey.shade600;
  static Color titleColor = Colors.grey.shade200;
  static Color textColor = Colors.grey.shade100;
  static Color successColor = Color.fromRGBO(9, 149, 110, 1);
  static Color highlightColor = Color.fromRGBO(212, 172, 13, 1);
  static Gradient primaryGradient = LinearGradient(
    colors: [
      Colors.blueGrey, // Dark blue
      Colors.blueGrey.shade300, // Lighter blue
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

ThemeData primaryTheme = ThemeData(
    // app bar theme colors
    appBarTheme: AppBarTheme().copyWith(
      backgroundColor: AppColors.secondaryColor,
      foregroundColor: AppColors.textColor,
      // surfaceTintColor: Colors.transparent,
      centerTitle: true,
      toolbarHeight: 100,
      elevation: 2,
      iconTheme: IconThemeData(color: AppColors.textColor, size: 32.0),
    ),

    // scaffold color
    scaffoldBackgroundColor: AppColors.primaryColor,

    // drawer styles
    drawerTheme: DrawerThemeData(),

    // text theme
    textTheme: TextTheme().copyWith(
      bodySmall: TextStyle(
        color: AppColors.titleColor,
        fontSize: 12,
        letterSpacing: 1,
      ),
      bodyMedium: TextStyle(
        color: AppColors.textColor,
        fontSize: 16,
        letterSpacing: 1,
      ),
      bodyLarge: TextStyle(
        color: AppColors.primaryAccent,
        fontSize: 18,
        letterSpacing: 1,
      ),
      headlineMedium: TextStyle(
        color: AppColors.titleColor,
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
      headlineSmall: TextStyle(
        color: AppColors.primaryAccent,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 1,
      ),
      headlineLarge: TextStyle(
        color: AppColors.primaryAccent,
        fontSize: 32,
        fontWeight: FontWeight.w400,
        letterSpacing: 1,
      ),
      titleMedium: TextStyle(
        color: AppColors.titleColor,
        fontSize: 18,
        fontWeight: FontWeight.normal,
        letterSpacing: 2,
      ),
      titleSmall: TextStyle(
        color: AppColors.textColor,
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
      ),
    ),

    // dialog theme
    dialogTheme: DialogThemeData().copyWith(
      backgroundColor: AppColors.primaryAccent,
      titleTextStyle: TextStyle(
        color: AppColors.titleColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: TextStyle(
        color: AppColors.textColor,
        fontSize: 16,
      ),
    ),

    // text
    inputDecorationTheme: InputDecorationTheme().copyWith(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: AppColors.secondaryAccent, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: AppColors.secondaryColor, width: 2.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: AppColors.secondaryAccent, width: 1.0),
      ),
    ));
