class Breakpoints {
  const Breakpoints._();

  static const double compact = 700;
  static const double medium = 1100;

  static bool isCompact(double width) => width < compact;
  static bool isMedium(double width) => width >= compact && width < medium;
  static bool isExpanded(double width) => width >= medium;

  static double horizontalPadding(double width) {
    if (width < 480) return 16;
    if (width < medium) return 24;
    return 32;
  }

  static int gridColumns(double width, {double minItemWidth = 170}) {
    if (width < 480) return 2;
    if (width < compact) return 2;
    if (width < medium) return 3;
    final columns = (width / (minItemWidth + 16)).floor();
    return columns.clamp(3, 6);
  }

  static int listColumns(double width) => width >= 900 ? 2 : 1;

  static double contentMaxWidth(double width) => width >= 1400 ? 1200 : width;
}
