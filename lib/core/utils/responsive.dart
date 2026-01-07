import 'package:flutter/material.dart';

/// Responsive utilities for handling different screen sizes
class Responsive {
  Responsive._();

  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  /// Check if current screen is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// Check if current screen is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// Check if current screen is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  /// Check if current screen is large desktop
  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  /// Get screen width
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Get responsive value based on screen size
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    if (isDesktop(context)) {
      return desktop;
    } else if (isTablet(context)) {
      return tablet ?? desktop;
    } else {
      return mobile;
    }
  }

  /// Get responsive padding
  static EdgeInsets padding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: value<double>(
        context,
        mobile: 16,
        tablet: 24,
        desktop: 32,
      ),
      vertical: value<double>(
        context,
        mobile: 16,
        tablet: 20,
        desktop: 24,
      ),
    );
  }

  /// Get responsive horizontal padding value
  static double horizontalPadding(BuildContext context) {
    return value<double>(
      context,
      mobile: 16,
      tablet: 24,
      desktop: 32,
    );
  }

  /// Get content max width for centered layouts
  static double contentMaxWidth(BuildContext context) {
    return value<double>(
      context,
      mobile: double.infinity,
      tablet: 800,
      desktop: 1200,
    );
  }

  /// Get number of grid columns
  static int gridColumns(BuildContext context) {
    return value<int>(
      context,
      mobile: 1,
      tablet: 2,
      desktop: 3,
    );
  }

  /// Get table columns to show (for responsive tables)
  static int tableColumnsToShow(BuildContext context, int totalColumns) {
    if (isMobile(context)) {
      return (totalColumns * 0.4).ceil().clamp(2, 4);
    } else if (isTablet(context)) {
      return (totalColumns * 0.7).ceil().clamp(4, 6);
    } else {
      return totalColumns;
    }
  }
}

/// Responsive builder widget for conditional layouts
class ResponsiveBuilder extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (Responsive.isDesktop(context)) {
      return desktop;
    } else if (Responsive.isTablet(context)) {
      return tablet ?? desktop;
    } else {
      return mobile;
    }
  }
}

/// Extension for responsive sizing directly on widgets
extension ResponsiveExtension on BuildContext {
  bool get isMobile => Responsive.isMobile(this);
  bool get isTablet => Responsive.isTablet(this);
  bool get isDesktop => Responsive.isDesktop(this);
  double get screenWidth => Responsive.screenWidth(this);
  double get screenHeight => Responsive.screenHeight(this);
}
