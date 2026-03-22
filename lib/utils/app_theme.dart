import 'package:flutter/material.dart';

class AppTheme {

  static ThemeData lightTheme = ThemeData(

    brightness: Brightness.light,

    primaryColor: Colors.teal,

    scaffoldBackgroundColor: Colors.grey[100],

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.teal,
      foregroundColor: Colors.white,
    ),

    cardColor: Colors.white,

  );


  static ThemeData darkTheme = ThemeData(

    brightness: Brightness.dark,

    primaryColor: const Color.fromRGBO(0, 150, 136, 1),

    scaffoldBackgroundColor: const Color(0xff121212),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
    ),

    cardColor: const Color(0xff1E1E1E),

  );

}