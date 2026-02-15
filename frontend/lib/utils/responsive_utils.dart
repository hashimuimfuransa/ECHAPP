import 'package:flutter/material.dart';

/// Responsive breakpoints for different device sizes
class ResponsiveBreakpoints {
  // Enhanced breakpoints for better mobile support
  static const double smallMobileMax = 360; // Very small phones (iPhone SE, older Android)
  static const double mobileMax = 768;      // Standard mobile phones
  static const double tabletMax = 1024;     // Tablets
  static const double desktopMin = 1025;    // Desktops
  
  /// Check if current screen is small mobile size (≤ 360px)
  static bool isSmallMobile(BuildContext context) {
    return MediaQuery.of(context).size.width <= smallMobileMax;
  }
  
  /// Check if current screen is mobile size (≤ 768px)
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width <= mobileMax;
  }
  
  /// Check if current screen is standard mobile (361px - 768px)
  static bool isStandardMobile(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width > smallMobileMax && width <= mobileMax;
  }
  
  /// Check if current screen is tablet size
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width > mobileMax && width <= tabletMax;
  }
  
  /// Check if current screen is desktop size
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width > tabletMax;
  }
  
  /// Get device type as string for debugging
  static String getDeviceType(BuildContext context) {
    if (isSmallMobile(context)) return 'Small Mobile';
    if (isStandardMobile(context)) return 'Standard Mobile';
    if (isTablet(context)) return 'Tablet';
    return 'Desktop';
  }
  
  /// Get responsive padding based on screen size
  static EdgeInsets getPadding(BuildContext context) {
    if (isSmallMobile(context)) {
      return const EdgeInsets.all(12);
    } else if (isStandardMobile(context)) {
      return const EdgeInsets.all(16);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(24);
    } else {
      return const EdgeInsets.all(32);
    }
  }
  
  /// Get responsive spacing based on screen size
  static double getSpacing(BuildContext context, {double base = 16}) {
    if (isSmallMobile(context)) {
      return base * 0.75;
    } else if (isStandardMobile(context)) {
      return base;
    } else if (isTablet(context)) {
      return base * 1.5;
    } else {
      return base * 2;
    }
  }
  
  /// Get responsive font scale factor
  static double getTextScale(BuildContext context) {
    if (isSmallMobile(context)) {
      return 0.85;
    } else if (isStandardMobile(context)) {
      return 1.0;
    } else if (isTablet(context)) {
      return 1.1;
    } else {
      return 1.2;
    }
  }
}

/// Responsive layout widgets
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });
  
  @override
  Widget build(BuildContext context) {
    if (ResponsiveBreakpoints.isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    } else if (ResponsiveBreakpoints.isTablet(context)) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }
}

/// Responsive grid count for different screen sizes
class ResponsiveGridCount {
  final BuildContext context;
  
  const ResponsiveGridCount(this.context);
  
  int get crossAxisCount {
    if (ResponsiveBreakpoints.isSmallMobile(context)) {
      return 1; // Single column for very small screens
    } else if (ResponsiveBreakpoints.isStandardMobile(context)) {
      return 2; // Two columns for standard mobile
    } else if (ResponsiveBreakpoints.isTablet(context)) {
      return 3;
    } else {
      return 4;
    }
  }
  
  double get childAspectRatio {
    if (ResponsiveBreakpoints.isSmallMobile(context)) {
      return 0.7; // More compact for small screens
    } else if (ResponsiveBreakpoints.isStandardMobile(context)) {
      return 0.75;
    } else if (ResponsiveBreakpoints.isTablet(context)) {
      return 0.8;
    } else {
      return 0.85;
    }
  }
}

/// Responsive padding widget
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsets? smallMobilePadding;
  final EdgeInsets? mobilePadding;
  final EdgeInsets? tabletPadding;
  final EdgeInsets? desktopPadding;
  
  const ResponsivePadding({
    super.key,
    required this.child,
    this.smallMobilePadding,
    this.mobilePadding,
    this.tabletPadding,
    this.desktopPadding,
  });
  
  @override
  Widget build(BuildContext context) {
    EdgeInsets padding;
    
    if (ResponsiveBreakpoints.isSmallMobile(context)) {
      padding = smallMobilePadding ?? const EdgeInsets.all(12);
    } else if (ResponsiveBreakpoints.isStandardMobile(context)) {
      padding = mobilePadding ?? const EdgeInsets.all(16);
    } else if (ResponsiveBreakpoints.isTablet(context)) {
      padding = tabletPadding ?? const EdgeInsets.all(24);
    } else {
      padding = desktopPadding ?? const EdgeInsets.all(32);
    }
    
    return Padding(padding: padding, child: child);
  }
}

/// Responsive column/row switcher
class ResponsiveFlex extends StatelessWidget {
  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;
  final double spacing;
  
  const ResponsiveFlex({
    super.key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.spacing = 16,
  });
  
  @override
  Widget build(BuildContext context) {
    // For small mobile devices, always use column layout
    if (ResponsiveBreakpoints.isSmallMobile(context)) {
      return Column(
        crossAxisAlignment: crossAxisAlignment,
        mainAxisAlignment: mainAxisAlignment,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) SizedBox(height: spacing * 0.75),
          ],
        ],
      );
    }
    // For standard mobile, use column for many items, row for few
    else if (ResponsiveBreakpoints.isStandardMobile(context)) {
      if (children.length <= 2) {
        return Row(
          crossAxisAlignment: crossAxisAlignment,
          mainAxisAlignment: mainAxisAlignment,
          children: [
            for (int i = 0; i < children.length; i++) ...[
              Expanded(child: children[i]),
              if (i < children.length - 1) SizedBox(width: spacing),
            ],
          ],
        );
      } else {
        return Column(
          crossAxisAlignment: crossAxisAlignment,
          mainAxisAlignment: mainAxisAlignment,
          children: [
            for (int i = 0; i < children.length; i++) ...[
              children[i],
              if (i < children.length - 1) SizedBox(height: spacing),
            ],
          ],
        );
      }
    }
    // For larger screens, use row layout
    else if (ResponsiveBreakpoints.isDesktop(context)) {
      return Row(
        crossAxisAlignment: crossAxisAlignment,
        mainAxisAlignment: mainAxisAlignment,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            Expanded(child: children[i]),
            if (i < children.length - 1) SizedBox(width: spacing),
          ],
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: crossAxisAlignment,
        mainAxisAlignment: mainAxisAlignment,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) SizedBox(height: spacing),
          ],
        ],
      );
    }
  }
}
