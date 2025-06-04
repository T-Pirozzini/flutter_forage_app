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
);
