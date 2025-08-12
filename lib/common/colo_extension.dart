import 'package:flutter/material.dart';

class TColor {
  static Color get primaryColor1 => const Color.fromARGB(255, 40, 112, 70);
  static Color get primaryColor2 => const Color.fromARGB(255, 57, 187, 159);

  static Color get secondaryColor1 => const Color.fromARGB(255, 226, 71, 10);
  static Color get secondaryColor2 => const Color.fromARGB(255, 235, 102, 13);


  static List<Color> get primaryG => [ primaryColor2, primaryColor1 ];
  static List<Color> get secondaryG => [secondaryColor2, secondaryColor1];

  static Color get black => const Color(0xff1D1617);
  static Color get gray => const Color(0xff786F72);
  static Color get white => Colors.white;
  static Color get lightGray => const Color(0xffF7F8F8);



}

extension ColorExtension on Color {
  Color withAlpha(double alpha) {
    return Color.fromRGBO(
      (r * 255.0).round() & 0xff,
      (g * 255.0).round() & 0xff,
      (b * 255.0).round() & 0xff,
      alpha,
    );
  }
}
