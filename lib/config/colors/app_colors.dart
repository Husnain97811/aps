import 'package:flutter/material.dart';

class AppColors {
  static const LinearGradient rmncolor = LinearGradient(
    begin: Alignment.topRight,
    tileMode: TileMode.repeated,
    end: Alignment.bottomLeft,
    colors: [darkbrown, lightgolden, darkbrown],
  );
  static const LinearGradient rmncolorlight = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomRight,
    tileMode: TileMode.clamp,
    colors: [Color.fromARGB(174, 0, 0, 0), darkbrown, darkbrown],
  );
  static const Color darkbrown = Color.fromRGBO(208, 148, 59, 1);
  static const Color lightgolden = Color.fromRGBO(234, 206, 280, 1);

  static const Color buttoncolor = Color.fromARGB(255, 144, 121, 184);

  static const Color whitecolor = Colors.white;
  static Color? textcolor = Colors.brown[700];
  static const Color blackcolor = Colors.black;

  static Color circularcolor = Colors.blueGrey.shade800;
}
