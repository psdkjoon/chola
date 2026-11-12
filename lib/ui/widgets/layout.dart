import 'package:flutter/widgets.dart';

abstract class Layout {
  static bool landscape(Size size) =>
      size.width > size.height * 1.15 && size.width >= 560;

  static bool split(double width) => width >= 720;

  static double edge(double width) => width < 480 ? 14 : (width < 900 ? 20 : 26);
}
