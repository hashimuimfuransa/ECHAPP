import 'dart:math' show pi, sin, cos, Random;
import 'package:flutter/material.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';

/// A shared background widget that can be used across splash, auth, and onboarding screens
/// It displays the onboarding background image with optional overlay and animations
class SharedBackground extends StatefulWidget {
  final Widget child;
  final bool showImage;
  final bool showGradientOverlay;
  final bool showFloatingAnimation;
  final bool blurBackground;
  final double overlayOpacity;
  final EdgeInsets padding;
  final bool centerContent;

  const SharedBackground({
    super.key,
    required this.child,
    this.showImage = true,
    this.showGradientOverlay = true,
    this.showFloatingAnimation = false,
    this.blurBackground = false,
    this.overlayOpacity = 0.6,
    this.padding = EdgeInsets.zero,
    this.centerContent = true,
  });

  @override
  State<SharedBackground> createState() => _SharedBackgroundState();
}

class _SharedBackgroundState extends State<SharedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );
    if (widget.showFloatingAnimation) {
      _animController.repeat();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    return Scaffold(
      body: Stack(
        children: [
          // Base background image
          if (widget.showImage) _buildBackgroundImage(isDesktop),
          // Gradient overlay
          if (widget.showGradientOverlay) _buildGradientOverlay(),
          // Floating animation (optional)
          if (widget.showFloatingAnimation) _buildFloatingAnimation(),
          // Main content
          SafeArea(
            child: widget.centerContent
                ? Center(
                    child: Padding(
                      padding: widget.padding,
                      child: widget.child,
                    ),
                  )
                : Padding(
                    padding: widget.padding,
                    child: widget.child,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundImage(bool isDesktop) {
    // Use different images for desktop and mobile if available
    // For now, use the same image with different fit
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/onboardign mobile.png'),
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0F172A).withOpacity(widget.overlayOpacity * 0.5),
            const Color(0xFF1E293B).withOpacity(widget.overlayOpacity * 0.7),
            const Color(0xFF0F172A).withOpacity(widget.overlayOpacity),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }

  Widget _buildFloatingAnimation() {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final t = _animController.value;
        return Stack(
          children: [
            // Glowing circles
            Positioned(
              top: -100 + 30 * sin(t * 2 * pi),
              right: -100 + 20 * cos(t * 2 * pi),
              child: _glowCircle(400, const Color(0xFF00C896).withOpacity(0.1), 70),
            ),
            Positioned(
              bottom: 80 + 40 * cos(t * 2 * pi + 1),
              left: -120 + 30 * sin(t * 2 * pi + 1),
              child: _glowCircle(300, const Color(0xFF34D399).withOpacity(0.08), 55),
            ),
            // Floating particles
            ...List.generate(12, (i) {
              final random = Random(i);
              final p = Offset(random.nextDouble(), random.nextDouble());
              final size = random.nextDouble() * 36 + 8;
              final y = (p.dy + t * 0.08 * (i % 3 + 1)) % 1.0;
              return Positioned(
                left: MediaQuery.of(context).size.width * p.dx,
                top: MediaQuery.of(context).size.height * y,
                child: Opacity(
                  opacity: 0.1 + 0.08 * sin(t * 2 * pi + i),
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.4),
                          Colors.white.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _glowCircle(double size, Color color, double blur) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: blur,
            spreadRadius: blur / 2,
          ),
        ],
      ),
    );
  }
}

/// A desktop-optimized container that provides consistent styling
class DesktopAuthContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double maxWidth;
  final EdgeInsets padding;
  final bool showGlassEffect;

  const DesktopAuthContainer({
    super.key,
    required this.child,
    this.width,
    this.maxWidth = 500,
    this.padding = const EdgeInsets.all(40),
    this.showGlassEffect = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? maxWidth,
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: padding,
      decoration: showGlassEffect
          ? BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 40,
                  spreadRadius: 0,
                ),
              ],
            )
          : null,
      child: child,
    );
  }
}

/// A mobile-optimized container that slides up from bottom
class MobileBottomSheet extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;

  const MobileBottomSheet({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.borderRadius = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top spacer (for logo/brand area)
        const Expanded(flex: 2, child: SizedBox()),
        // Bottom sheet
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(borderRadius),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(borderRadius),
              ),
              child: SingleChildScrollView(
                padding: padding,
                child: child,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Reusable logo widget for auth screens
class AuthLogo extends StatelessWidget {
  final double size;
  final bool showGlow;
  final bool darkBackground;

  const AuthLogo({
    super.key,
    this.size = 100,
    this.showGlow = true,
    this.darkBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: showGlow
          ? BoxDecoration(
              shape: BoxShape.circle,
              color: darkBackground ? Colors.white.withOpacity(0.9) : const Color(0xFF00C896).withOpacity(0.1),
              boxShadow: darkBackground
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ]
                  : null,
            )
          : null,
      child: ClipOval(
        child: Padding(
          padding: EdgeInsets.all(size * 0.16),
          child: Image.asset(
            'assets/logo.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

/// Reusable brand text widget
class BrandText extends StatelessWidget {
  final double titleSize;
  final double subtitleSize;
  final bool darkMode;

  const BrandText({
    super.key,
    this.titleSize = 28,
    this.subtitleSize = 14,
    this.darkMode = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Excellence Coaching Hub',
          style: TextStyle(
            color: darkMode ? Colors.white : const Color(0xFF1A2433),
            fontSize: titleSize,
            fontWeight: FontWeight.bold,
            shadows: darkMode
                ? [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Transforming Education Through Technology',
          style: TextStyle(
            color: darkMode ? Colors.white.withOpacity(0.8) : const Color(0xFF4A5568),
            fontSize: subtitleSize,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
