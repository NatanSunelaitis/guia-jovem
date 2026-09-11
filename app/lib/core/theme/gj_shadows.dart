import 'package:flutter/material.dart';

import 'gj_colors.dart';

/// Elevação e bordas do GJDS, seção 2.5.
abstract final class GJShadows {
  static const List<BoxShadow> none = [];

  static const List<BoxShadow> sm = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 2, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> lg = [
    BoxShadow(color: Color(0x1F000000), blurRadius: 30, offset: Offset(0, 10)),
  ];

  static final borderSubtle = Border.all(color: GJColors.border.withOpacity(0.2));
  static final borderDefault = Border.all(color: GJColors.border);
}
