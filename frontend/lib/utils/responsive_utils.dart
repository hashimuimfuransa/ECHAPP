import 'package:flutter/material.dart';

/// Responsive breakpoints for different device sizes
class ResponsiveBreakpoints {
  static const double mobileMax = 768;
  static const double tabletMax = 1024;
  static const double desktopMin = 1025;
  
  /// Check if current screen is mobile size
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width <= mobileMax;
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
  
  /// Get responsive padding based on screen size
  static EdgeInsets getPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(16);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(24);
    } else {
      return const EdgeInsets.all(32);
    }
  }
  
  /// Get responsive spacing based on screen size
  static double getSpacing(BuildContext context, {double base = 16}) {
    if (isMobile(context)) {
      return base;
    } else if (isTablet(context)) {
      return base * 1.5;
    } else {
      return base * 2;
    }
  }
  
  /// Get responsive font scale factor
  static double getTextScale(BuildContext context) {
    if (isMobile(context)) {
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
    if (ResponsiveBreakpoints.isDesktop(context)) {
      return 4;
    } else if (ResponsiveBreakpoints.isTablet(context)) {
      return 3;
    } else {
      return 2;
    }
  }
  
  double get childAspectRatio {
    if (ResponsiveBreakpoints.isDesktop(context)) {
      return 0.85;
    } else if (ResponsiveBreakpoints.isTablet(context)) {
      return 0.8;
    } else {
      return 0.75;
    }
  }
}

/// Responsive padding widget
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsets? mobilePadding;
  final EdgeInsets? tabletPadding;
  final EdgeInsets? desktopPadding;
  
  const ResponsivePadding({
    super.key,
    required this.child,
    this.mobilePadding,
    this.tabletPadding,
    this.desktopPadding,
  });
  
  @override
  Widget build(BuildContext context) {
    EdgeInsets padding;
    
    if (ResponsiveBreakpoints.isDesktop(context)) {
      padding = desktopPadding ?? const EdgeInsets.all(32);
    } else if (ResponsiveBreakpoints.isTablet(context)) {
      padding = tabletPadding ?? const EdgeInsets.all(24);
    } else {
      padding = mobilePadding ?? const EdgeInsets.all(16);
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
    if (ResponsiveBreakpoints.isDesktop(context)) {
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