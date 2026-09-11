import 'package:flutter/widgets.dart';

/// Grid e breakpoints do GJDS, seção 2.7.
abstract final class GJBreakpoints {
  static const double tablet = 600;
  static const double desktop = 1024;
  static const double wide = 1440;
  static const double maxContentWidth = 1280;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < tablet;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= tablet && width < desktop;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktop;
}
