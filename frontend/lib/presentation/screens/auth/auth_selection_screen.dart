import 'dart:math' show pi, sin, cos, Random;
import 'dart:ui' show ImageFilter;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';

const _kDeep       = Color(0xFF041B2D);
const _kMid        = Color(0xFF072A3E);
const _kTeal       = Color(0xFF0A4A5A);
const _kAccent     = Color(0xFF10B981);
const _kAccentLight= Color(0xFF34D399);
const _kAccentDark = Color(0xFF059669);
const _kGold       = Color(0xFFFFBF00);
const _kSurface    = Color(0xFFF5F7FA);
const _kBorder     = Color(0xFFE4EAF2);
const _kText1      = Color(0xFF0D1B2A);
const _kText2      = Color(0xFF4A5568);
const _kText3      = Color(0xFF8A97AA);
const _kAmber      = Color(0xFFF59E0B);
const _kAmberBg    = Color(0xFFFFFBEB);
const _kAmberBorder= Color(0xFFFDE68A);

// ─── Floating shapes background ─────────────────────────────────────────────

class _FloatingBackground extends StatefulWidget {
  final bool compact;
  const _FloatingBackground({this.compact = false});
  @override
  State<_FloatingBackground> createState() => _FloatingBackgroundState();
}

class _FloatingBackgroundState extends State<_FloatingBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final List<Offset> _particles = List.generate(15, (i) => 
      Offset(Random().nextDouble(), Random().nextDouble()));
  final List<double> _particleSizes = List.generate(15, (i) => 
      Random().nextDouble() * 40 + 10);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 15))
      ..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;
        return Stack(
          children: [
            // Large blurred blobs
            Positioned(
              top: -100 + (30 * sin(t * 2 * pi)),
              right: -100 + (20 * cos(t * 2 * pi)),
              child: _GlowCircle(
                size: widget.compact ? 300 : 500,
                color: _kAccent.withOpacity(0.08),
                blur: 80,
              ),
            ),
            Positioned(
              bottom: 100 + (40 * cos(t * 2 * pi + 1)),
              left: -120 + (30 * sin(t * 2 * pi + 1)),
              child: _GlowCircle(
                size: widget.compact ? 250 : 400,
                color: _kAccentLight.withOpacity(0.06),
                blur: 60,
              ),
            ),
            // Bokeh particles
            ...List.generate(_particles.length, (i) {
              final p = _particles[i];
              final s = _particleSizes[i];
              final y = (p.dy + (t * 0.1 * (i % 3 + 1))) % 1.0;
              return Positioned(
                left: MediaQuery.of(context).size.width * p.dx,
                top: MediaQuery.of(context).size.height * y,
                child: Opacity(
                  opacity: 0.15 + (0.1 * sin(t * 2 * pi + i)),
                  child: Container(
                    width: s, height: s,
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
}

// ─── Glow circle ─────────────────────────────────────────────────────────────

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;
  final double blur;
  const _GlowCircle({required this.size, required this.color, this.blur = 0});
  @override
  Widget build(BuildContext context) => Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle, 
          color: blur > 0 ? null : color,
          boxShadow: blur > 0 ? [
            BoxShadow(
              color: color,
              blurRadius: blur,
              spreadRadius: blur / 2,
            )
          ] : null,
        ),
      );
}

// ─── Logo badge ───────────────────────────────────────────────────────────────

class _LogoBadge extends StatelessWidget {
  final double size;
  const _LogoBadge({this.size = 120});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _kAccentLight.withOpacity(0.6),
            blurRadius: 40,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          Container(
            width: size, height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: 2,
              ),
            ),
          ),
          // Inner logo circle
          ClipOval(
            child: Image.asset(
              'assets/logo.png',
              width: size * 0.85, height: size * 0.85,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) =>
                  Container(
                    color: _kDeep,
                    child: Icon(
                      Icons.school_rounded,
                      color: _kAccentLight,
                      size: size * 0.5,
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Feature row (icon chip + bold text matching image) ───────────────────────

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureRow({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: _kAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kAccent.withOpacity(0.30)),
            ),
            child: Icon(icon, color: _kAccent, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1)),
          ),
        ],
      ),
    );
  }
}

// ─── Stat pill ────────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final String value;
  final String label;
  final Widget? extra;  // e.g. stars
  const _StatPill({required this.value, required this.label, this.extra});
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(value,
              style: const TextStyle(
                  color: _kGold,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5)),
          const SizedBox(height: 3),
          Text(label,
              style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
          if (extra != null) ...[const SizedBox(height: 4), extra!],
        ],
      );
}

// ─── Star rating row ─────────────────────────────────────────────────────────

class _StarRating extends StatelessWidget {
  final int count;
  const _StarRating({this.count = 5});
  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(count, (i) =>
            Icon(Icons.star_rounded, color: _kGold, size: 14)),
      );
}

// ─── Vertical divider ─────────────────────────────────────────────────────────

class _VertDivider extends StatelessWidget {
  const _VertDivider();
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 44, color: Colors.white.withOpacity(0.10));
}

// ─── Mini stat chip (compact/mobile) ─────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final String label;
  const _MiniStat({required this.label});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kAccent.withOpacity(0.25)),
        ),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white70, fontSize: 11.5,
                fontWeight: FontWeight.w600)),
      );
}

// ─── Brand background ────────────────────────────────────────────────────────

class _BrandBackground extends StatelessWidget {
  final bool compact;
  final Widget? child;
  const _BrandBackground({this.compact = false, this.child});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isMobile 
            ? [const Color(0xFF031422), const Color(0xFF072A3E), const Color(0xFF0C5A6A)]
            : [const Color(0xFF010A12), const Color(0xFF031422), const Color(0xFF072A3E)],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
      child: Stack(
        children: [
          _FloatingBackground(compact: compact),
          if (child != null) SafeArea(child: child!),
        ],
      ),
    );
  }
}

// ─── Branding section ────────────────────────────────────────────────────────

class _BrandingSection extends StatelessWidget {
  final bool isMobile;
  const _BrandingSection({this.isMobile = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _LogoBadge(size: isMobile ? 140 : 180),
        SizedBox(height: isMobile ? 32 : 40),
        Text('Excellence',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 36 : 44,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                height: 1.0)),
        SizedBox(height: isMobile ? 6 : 8),
        Text('Coaching Hub',
            style: TextStyle(
                color: _kAccentLight,
                fontSize: isMobile ? 18 : 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0)),
        SizedBox(height: isMobile ? 12 : 16),
        Text('Learn • Grow • Succeed',
            style: TextStyle(
                color: Colors.white70,
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.w500)),
        SizedBox(height: isMobile ? 32 : 40),
        _ExpertBadge(isMobile: isMobile),
        SizedBox(height: isMobile ? 24 : 32),
        const _SkillChipsRow(),
      ],
    );
  }
}

class _ExpertBadge extends StatelessWidget {
  final bool isMobile;
  const _ExpertBadge({required this.isMobile});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 24,
        vertical: isMobile ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: _kAccent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _kAccentLight.withOpacity(0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _kAccentLight.withOpacity(0.1),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded,
              color: _kAccentLight, size: isMobile ? 18 : 22),
          SizedBox(width: isMobile ? 10 : 12),
          Text('Expert-Led Learning',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.95),
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2)),
        ],
      ),
    );
  }
}

class _SkillChipsRow extends StatelessWidget {
  const _SkillChipsRow();
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          _SkillChip(icon: Icons.lightbulb_outline, label: 'AI Courses'),
          SizedBox(width: 16),
          _SkillChip(icon: Icons.laptop_rounded, label: 'Programming'),
          SizedBox(width: 16),
          _SkillChip(icon: Icons.trending_up_rounded, label: 'Business Skills'),
        ],
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SkillChip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: _kAccentLight, size: 14),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ─── Google sign-in button (matches image: white bg, coloured G icon) ─────────

class _GoogleButton extends StatefulWidget {
  final bool isLoading;
  final Function()? onPressed;
  const _GoogleButton({this.isLoading = false, this.onPressed});
  @override
  State<_GoogleButton> createState() => _GoogleButtonState();
}

class _GoogleButtonState extends State<_GoogleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1, end: 0.97).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _handleTap() async {
    _ctrl.reverse();
    if (widget.onPressed != null) {
      try {
        await widget.onPressed?.call();
      } catch (e) {
        debugPrint('Google button tap error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) => _handleTap(),
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: isMobile ? 54 : 58,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4)),
              BoxShadow(
                color: const Color(0xFFF3F4F6),
                blurRadius: 0,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading)
                const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation(_kAccent),
                  ),
                )
              else
                _GoogleGIcon(size: 24),
              const SizedBox(width: 12),
              Text(
                widget.isLoading ? 'Connecting...' : 'Continue with Google',
                style: TextStyle(
                    color: const Color(0xFF3C4043),
                    fontSize: isMobile ? 16 : 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Minimal Google G icon built with CustomPainter ───────────────────────────

class _GoogleGIcon extends StatelessWidget {
  final double size;
  const _GoogleGIcon({this.size = 22});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: size, height: size,
        child: CustomPaint(painter: _GoogleGPainter()),
      );
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double sw = w * 0.22; // stroke width
    final Rect rect = Rect.fromLTWH(sw / 2, sw / 2, w - sw, h - sw);
    
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.butt;

    // Google Colors
    const red = Color(0xFFEA4335);
    const yellow = Color(0xFFFBBC05);
    const green = Color(0xFF34A853);
    const blue = Color(0xFF4285F4);

    // Blue section (Right arc + Bar)
    paint.color = blue;
    // Blue arc starts from around -0.7 rad to 0.8 rad
    canvas.drawArc(rect, -0.7, 1.5, false, paint); 
    
    // Blue Bar
    final barPaint = Paint()..color = blue..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(w/2, h/2 - sw/2, w/2, sw), barPaint);

    // Green section (Bottom)
    paint.color = green;
    canvas.drawArc(rect, 0.8, 1.6, false, paint);

    // Yellow section (Left)
    paint.color = yellow;
    canvas.drawArc(rect, 2.4, 1.3, false, paint);

    // Red section (Top)
    paint.color = red;
    canvas.drawArc(rect, 3.7, 1.8, false, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// ─── Email / primary button ───────────────────────────────────────────────────

class _PrimaryButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;
  const _PrimaryButton({
    required this.icon,
    required this.label,
    this.isLoading = false,
    this.onPressed,
  });
  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1, end: 0.97).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onPressed?.call(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: isMobile ? 54 : 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_kAccentLight, _kAccentDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: _kAccentDark.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: -4,
                  offset: const Offset(0, 8)),
              BoxShadow(
                  color: Colors.white.withOpacity(0.2),
                  blurRadius: 0,
                  spreadRadius: 0,
                  offset: const Offset(0, -2)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.isLoading)
                  const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(Colors.white)),
                  )
                else
                  Icon(widget.icon, color: Colors.white, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(widget.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 17 : 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2)),
                ),
                const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Device warning banner (amber, matches image) ─────────────────────────────

class _DeviceWarningBadge extends StatelessWidget {
  const _DeviceWarningBadge();
  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 14, 
        vertical: isMobile ? 10 : 12
      ),
      decoration: BoxDecoration(
        color: _kAmberBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kAmberBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline_rounded,
              color: _kAmber, size: 16),
          const SizedBox(width: 9),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                    color: _kText1.withOpacity(0.75),
                    fontSize: isMobile ? 11.5 : 12.5,
                    height: 1.4,
                    fontWeight: FontWeight.w500),
                children: [
                  const TextSpan(text: 'Binds to first device. '),
                  TextSpan(
                    text: 'Contact support',
                    style: const TextStyle(
                        color: _kAmber,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                        decorationColor: _kAmber),
                  ),
                  const TextSpan(text: ' to switch.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Terms footer ─────────────────────────────────────────────────────────────

class _TermsFooter extends StatelessWidget {
  const _TermsFooter();
  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    return Text.rich(
      TextSpan(
        style: TextStyle(
            color: _kText3, 
            fontSize: isMobile ? 11.5 : 12.5, 
            height: 1.5),
        children: [
          const TextSpan(text: 'By continuing, you agree to our '),
          TextSpan(
            text: 'Terms of Service',
            style: const TextStyle(
                color: _kAccentDark,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: _kAccentDark),
            recognizer: TapGestureRecognizer()
              ..onTap = () => context.push('/terms'),
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Policy',
            style: const TextStyle(
                color: _kAccentDark,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: _kAccentDark),
            recognizer: TapGestureRecognizer()
              ..onTap = () => context.push('/privacy'),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

// ─── Fade in slide animation ────────────────────────────────────────────────

class _FadeInSlide extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final Offset offset;

  const _FadeInSlide({
    required this.child,
    this.delay = Duration.zero,
    this.offset = const Offset(0, 20),
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.delayed(delay),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Opacity(opacity: 0, child: child);
        }
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(offset.dx * (1 - value), offset.dy * (1 - value)),
                child: child,
              ),
            );
          },
          child: child,
        );
      },
    );
  }
}

// ─── Avatar row (matches image trust badge) ───────────────────────────────────

class _AvatarRow extends StatelessWidget {
  const _AvatarRow();

  static const _avatarColors = [
    Color(0xFF6366F1),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: isMobile ? 68 : 80,
          height: isMobile ? 24 : 28,
          child: Stack(
            children: List.generate(4, (i) => Positioned(
              left: i * (isMobile ? 15.0 : 18.0),
              child: Container(
                width: isMobile ? 24 : 28, 
                height: isMobile ? 24 : 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _avatarColors[i],
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    ['A', 'B', 'C', 'D'][i],
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 9 : 10,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            )),
          ),
        ),
        const SizedBox(width: 8),
        RichText(
          text: TextSpan(
            style: TextStyle(
                color: _kText3, 
                fontSize: isMobile ? 11 : 12, 
                fontWeight: FontWeight.w500),
            children: [
              const TextSpan(text: 'Trusted by '),
              const TextSpan(
                text: '5,200+',
                style: TextStyle(
                    color: _kText1,
                    fontWeight: FontWeight.w800),
              ),
              const TextSpan(text: ' learners'),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Trust bar (secure login + avatars, matching image bottom) ────────────────

class _TrustBar extends StatelessWidget {
  const _TrustBar();
  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.check_circle_outline_rounded, 
          size: isMobile ? 14 : 16, 
          color: _kAccentDark.withOpacity(0.8)),
        const SizedBox(width: 6),
        Text('Secure & Encrypted',
            style: TextStyle(
                color: _kText2.withOpacity(0.8), 
                fontSize: isMobile ? 12 : 13.5,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ─── Auth card ────────────────────────────────────────────────────────────────

class _AuthCard extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final VoidCallback onEmail;
  final VoidCallback? onGoogle;

  const _AuthCard({
    required this.isLoading,
    required this.error,
    required this.onEmail,
    this.onGoogle,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _FadeInSlide(
          delay: const Duration(milliseconds: 100),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _kAccentLight.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.vpn_key_rounded, color: _kAccentDark, size: isMobile ? 22 : 26),
              ),
              const SizedBox(width: 14),
              Text('Sign In',
                  style: TextStyle(
                      color: _kText1,
                      fontSize: isMobile ? 28 : 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _FadeInSlide(
          delay: const Duration(milliseconds: 200),
          child: Text('Access your dashboard & courses',
              style: TextStyle(
                  color: _kText2, 
                  fontSize: isMobile ? 15 : 17,
                  height: 1.4,
                  fontWeight: FontWeight.w500)),
        ),

        const SizedBox(height: 32),

        if (error != null && error!.isNotEmpty) ...[
          _FadeInSlide(
            delay: const Duration(milliseconds: 300),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(children: [
                Icon(Icons.error_rounded, color: Colors.red.shade600, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(error!,
                      style: TextStyle(
                          color: Colors.red.shade800,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.3)),
                ),
              ]),
            ),
          ),
        ],

        _FadeInSlide(
          delay: const Duration(milliseconds: 400),
          child: _PrimaryButton(
            icon: Icons.mail_outline_rounded,
            label: 'Continue with Email',
            isLoading: isLoading,
            onPressed: isLoading ? null : onEmail,
          ),
        ),

        if (!ResponsiveBreakpoints.isDesktop(context) && onGoogle != null && !kIsWeb) ...[
          const SizedBox(height: 24),
          _FadeInSlide(
            delay: const Duration(milliseconds: 500),
            child: Row(
              children: [
                Expanded(child: Divider(color: _kBorder, thickness: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('OR',
                      style: TextStyle(
                          color: _kText3,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2)),
                ),
                Expanded(child: Divider(color: _kBorder, thickness: 1)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _FadeInSlide(
            delay: const Duration(milliseconds: 600),
            child: _GoogleButton(
              isLoading: isLoading,
              onPressed: !isLoading ? onGoogle : null,
            ),
          ),
        ],

        const SizedBox(height: 32),
        _FadeInSlide(
          delay: const Duration(milliseconds: 700),
          child: const _DeviceWarningBadge(),
        ),

        const SizedBox(height: 16),

        _FadeInSlide(
          delay: const Duration(milliseconds: 800),
          child: const _TermsFooter(),
        ),

        const SizedBox(height: 14),

        _FadeInSlide(
          delay: const Duration(milliseconds: 900),
          child: const _TrustBar(),
        ),

        const SizedBox(height: 4),
      ],
    );
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class AuthSelectionScreen extends ConsumerStatefulWidget {
  const AuthSelectionScreen({super.key});

  @override
  _AuthSelectionScreenState createState() => _AuthSelectionScreenState();
}

class _AuthSelectionScreenState extends ConsumerState<AuthSelectionScreen>
    with SingleTickerProviderStateMixin {
  bool _hasNavigated = false;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 520));
    _fadeAnim =
        CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _fadeCtrl.forward());
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasNavigated) _checkAndNavigate();
  }

  @override
  void didUpdateWidget(covariant AuthSelectionScreen old) {
    super.didUpdateWidget(old);
    if (!_hasNavigated) _checkAndNavigate();
  }

  void _checkAndNavigate() {
    final authState = ref.watch(authProvider);
    if (authState.user != null && !authState.isLoading && !_hasNavigated) {
      _hasNavigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (authState.user?.role == 'admin') {
          context.go('/admin');
        } else {
          context.go('/dashboard');
        }
      });
    }
  }

  void _handleGoogleSignIn() async {
    try {
      debugPrint('Screen: Starting Google Sign-In');
      await ref.read(authProvider.notifier).signInWithGoogle();
      debugPrint('Screen: Google Sign-In completed');
    } catch (e) {
      debugPrint('Google Sign-In error in screen: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    ref.listen(authProvider, (_, current) {
      if (current.user != null && !current.isLoading && !_hasNavigated) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _checkAndNavigate());
      }
    });

    return Scaffold(
      backgroundColor: _kSurface,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: isDesktop
            ? _desktopLayout(authState)
            : _mobileLayout(authState),
      ),
    );
  }

  // ── Desktop layout ────────────────────────────────────────────────────────

  Widget _desktopLayout(dynamic authState) {
    return Row(
      children: [
        // Left brand panel — 45% width
        const Expanded(
          flex: 45,
          child: _BrandBackground(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 40),
              child: _BrandingSection(isMobile: false),
            ),
          ),
        ),

        // Right auth panel — 55% width
        Expanded(
          flex: 55,
          child: Container(
            color: Colors.white,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 44, vertical: 52),
                  child: _AuthCard(
                    isLoading: authState.isLoading,
                    error: authState.error,
                    onEmail: () => context.push('/email-auth-option'),
                    onGoogle: null,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Mobile layout ─────────────────────────────────────────────────────────

  Widget _mobileLayout(dynamic authState) {
    return Scaffold(
      body: Stack(
        children: [
          // Background layer
          const _BrandBackground(compact: true),
          
          // Scrollable content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Column(
                children: [
                  // Logo & Branding at top
                  const _BrandingSection(isMobile: true),
                  
                  const SizedBox(height: 40),
                  
                  // Glassmorphism Card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: _AuthCard(
                          isLoading: authState.isLoading,
                          error: authState.error,
                          onEmail: () => context.push('/email-auth-option'),
                          onGoogle: _handleGoogleSignIn,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          
          if (context.canPop())
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 10,
              child: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}