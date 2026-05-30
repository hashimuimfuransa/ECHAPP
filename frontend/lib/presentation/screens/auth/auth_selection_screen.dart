import 'dart:math' show pi, sin, cos, Random;
import 'dart:ui' show ImageFilter;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/config/storage_manager.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';
import 'package:excellencecoachinghub/l10n/app_localizations.dart';
import 'package:excellencecoachinghub/presentation/widgets/desktop_brand_panel.dart';

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
  final bool isDark;
  const _LogoBadge({this.size = 120, this.isDark = false});
  @override
  Widget build(BuildContext context) {
    final ringColor = isDark ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.4);
    final bgColor = isDark ? const Color(0xFF1E293B) : _kDeep;
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
                color: ringColor,
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
                    color: bgColor,
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
  final bool isDesktop;
  const _BrandBackground({this.compact = false, this.child, this.isDesktop = false});

  @override
  Widget build(BuildContext context) {
    final useDesktop = isDesktop || ResponsiveBreakpoints.isDesktop(context);
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
            useDesktop ? 'assets/onboading desktop.png' : 'assets/onboardign mobile.png',
          ),
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0F172A).withOpacity(0.5),
              const Color(0xFF1E293B).withOpacity(0.7),
              const Color(0xFF0F172A).withOpacity(0.85),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            _FloatingBackground(compact: compact),
            if (child != null) SafeArea(child: child!),
          ],
        ),
      ),
    );
  }
}

// ─── Branding section (compact, matches image) ────────────────────────────────────────────────────────

class _BrandingSection extends StatelessWidget {
  final bool isMobile;
  final bool isDark;
  const _BrandingSection({this.isMobile = true, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    debugPrint('AuthSelectionScreen _BrandingSection: l10n is ${l10n == null ? "NULL" : "available"}');
    final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(context);
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final secondaryTextColor = isDark ? Colors.white70 : const Color(0xFF6B7280);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Logo
        _LogoBadge(size: isSmallMobile ? 90 : 110, isDark: isDark),
        const SizedBox(height: 12),

        // Excellence Coaching Hub
        Text('Excellence',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: textColor,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                height: 1.0)),
        const SizedBox(height: 2),
        const Text('Coaching Hub',
            style: TextStyle(
                color: Color(0xFF10B981),
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2)),

        const SizedBox(height: 6),
        Text(l10n?.authLearnGrowSucceed ?? 'Kwiga • Kukura • Kunesha',
            style: TextStyle(
                color: secondaryTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w500)),

        const SizedBox(height: 14),
        _ExpertBadgeCompact(isDark: isDark),
        const SizedBox(height: 16),
        _SkillChipsRow(isDark: isDark),
      ],
    );
  }
}

class _ExpertBadgeCompact extends StatelessWidget {
  final bool isDark;
  const _ExpertBadgeCompact({this.isDark = false});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF10B981).withOpacity(0.15) : const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(isDark ? 0.4 : 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded,
              color: Color(0xFF10B981), size: 16),
          const SizedBox(width: 8),
          Text(l10n?.authExpertLed ?? 'Kwiga n\'Abanyamwuga',
              style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1)),
        ],
      ),
    );
  }
}

class _SkillChipsRow extends StatelessWidget {
  final bool isDark;
  const _SkillChipsRow({this.isDark = false});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SkillChip(icon: Icons.school_outlined, label: 'AI Courses', sublabel: 'Smart learning', isDark: isDark),
        const SizedBox(width: 12),
        _SkillChip(icon: Icons.code_rounded, label: 'Programming', sublabel: 'Build the future', isDark: isDark),
        const SizedBox(width: 12),
        _SkillChip(icon: Icons.trending_up_rounded, label: 'Business Skills', sublabel: 'Grow your career', isDark: isDark),
      ],
    );
  }
}

class _SkillChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final bool isDark;
  const _SkillChip({required this.icon, required this.label, required this.sublabel, this.isDark = false});
  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final sublabelColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF9CA3AF);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF10B981), size: 20),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  color: textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
          Text(sublabel,
              style: TextStyle(
                  color: sublabelColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─── Google sign-in button (matches image: white bg, coloured G icon) ─────────

class _GoogleButton extends StatefulWidget {
  final bool isLoading;
  final Function()? onPressed;
  final bool isDark;
  const _GoogleButton({this.isLoading = false, this.onPressed, this.isDark = false});
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
    final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(context);
    final bgColor = widget.isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = widget.isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
    final textColor = widget.isDark ? Colors.white : const Color(0xFF374151);

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) => _handleTap(),
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: isSmallMobile ? 52 : 56,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: widget.isDark ? [] : [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading)
                SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(_kAccent),
                  ),
                )
              else
                _GoogleGIcon(size: 20),
              const SizedBox(width: 12),
              Text(
                widget.isLoading
                    ? (AppLocalizations.of(context)?.loading ?? 'Biratunganywa...')
                    : (AppLocalizations.of(context)?.continueWithGoogle ?? 'Komeza na Google'),
                style: TextStyle(
                    color: textColor,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1),
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

// ─── Phone Auth Button (image style: white bg, green icon, arrow right) ─────────────────────────────────

class _PhoneAuthButton extends StatefulWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;
  final bool isDark;

  const _PhoneAuthButton({
    required this.label,
    this.isLoading = false,
    this.onPressed,
    this.isDark = false,
  });

  @override
  State<_PhoneAuthButton> createState() => _PhoneAuthButtonState();
}

class _PhoneAuthButtonState extends State<_PhoneAuthButton>
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
    final bgColor = widget.isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = widget.isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
    final textColor = widget.isDark ? Colors.white : const Color(0xFF1F2937);
    final iconBgColor = widget.isDark ? const Color(0xFF10B981).withOpacity(0.2) : const Color(0xFFD1FAE5);

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onPressed?.call(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: widget.isDark ? [] : [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                if (widget.isLoading)
                  const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(Color(0xFF10B981)),
                  ),
                  )
                else
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.phone_rounded, color: Color(0xFF10B981), size: 20),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(widget.label,
                      style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1)),
                ),
                const Icon(Icons.arrow_forward_rounded, color: Color(0xFF10B981), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Email button (image style: white bg, blue icon, arrow right) ───────────────────────────────────────────────────

class _EmailButton extends StatefulWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;
  final bool isDark;
  const _EmailButton({
    required this.label,
    this.isLoading = false,
    this.onPressed,
    this.isDark = false,
  });
  @override
  State<_EmailButton> createState() => _EmailButtonState();
}

class _EmailButtonState extends State<_EmailButton> with SingleTickerProviderStateMixin {
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
    final bgColor = widget.isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = widget.isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
    final textColor = widget.isDark ? Colors.white : const Color(0xFF1F2937);
    final iconBgColor = widget.isDark ? const Color(0xFF3B82F6).withOpacity(0.2) : const Color(0xFFDBEAFE);

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onPressed?.call(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: widget.isDark ? [] : [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                if (widget.isLoading)
                  const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(Color(0xFF3B82F6)),
                  ),
                  )
                else
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.mail_outline_rounded, color: Color(0xFF3B82F6), size: 20),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(widget.label,
                      style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1)),
                ),
                const Icon(Icons.arrow_forward_rounded, color: Color(0xFF3B82F6), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Privacy notice (green badge, matches image bottom) ─────────────────────────────

class _PrivacyNoticeBadge extends StatelessWidget {
  final bool isDark;
  const _PrivacyNoticeBadge({this.isDark = false});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bgColor = isDark ? const Color(0xFF10B981).withOpacity(0.15) : const Color(0xFFF0FDF4);
    final borderColor = isDark ? const Color(0xFF10B981).withOpacity(0.3) : const Color(0xFFBBF7D0);
    final iconBgColor = isDark ? const Color(0xFF10B981).withOpacity(0.2) : const Color(0xFFD1FAE5);
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final secondaryTextColor = isDark ? Colors.white70 : const Color(0xFF6B7280);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.lock_outline_rounded,
                color: Color(0xFF059669), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.deviceWarningMessage.split('.').first ?? 'Konti yawe ihuza na telefone yawe ya mbere',
                  style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.3),
                ),
                Text(
                  'Ukoresha data yawe mu buryo bw\'umutekano.',
                  style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.3),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 22),
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
          TextSpan(text: '${AppLocalizations.of(context)?.byContinuing ?? "Ukomeza, wemeza"} '),
          TextSpan(
            text: AppLocalizations.of(context)?.termsOfService ?? 'Amategeko ya Serivisi',
            style: const TextStyle(
                color: _kAccentDark,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: _kAccentDark),
            recognizer: TapGestureRecognizer()
              ..onTap = () => context.push('/terms'),
          ),
          TextSpan(text: ' ${AppLocalizations.of(context)?.and ?? "na"} '),
          TextSpan(
            text: AppLocalizations.of(context)?.privacyPolicy ?? 'Ibihishwe Bwite',
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

class _FadeInSlide extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Offset offset;

  const _FadeInSlide({
    required this.child,
    this.delay = Duration.zero,
    this.offset = const Offset(0, 20),
  });

  @override
  State<_FadeInSlide> createState() => _FadeInSlideState();
}

class _FadeInSlideState extends State<_FadeInSlide> {
  late final Future<void> _future;

  @override
  void initState() {
    super.initState();
    _future = Future.delayed(widget.delay);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Opacity(opacity: 0, child: widget.child);
        }
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(widget.offset.dx * (1 - value), widget.offset.dy * (1 - value)),
                child: child,
              ),
            );
          },
          child: widget.child,
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle_outline_rounded, 
          size: 16, 
          color: Color(0xFF10B981)),
        const SizedBox(width: 6),
        Text(AppLocalizations.of(context)?.authExpertLed ?? 'Kwiga n\'Abanyamwuga',
            style: const TextStyle(
                color: Color(0xFF6B7280), 
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ─── Auth card (matches image: Injira title, phone, google, OR, email, privacy) ────────────────────────────────────────────────────────────────

class _AuthCard extends StatelessWidget {
  final bool isLoading;
  final bool isEmailLoading;
  final bool isGoogleLoading;
  final bool isPhoneLoading;
  final String? error;
  final VoidCallback onEmail;
  final VoidCallback? onGoogle;
  final VoidCallback? onPhone;
  final bool isDark;

  const _AuthCard({
    required this.isLoading,
    required this.isEmailLoading,
    required this.isGoogleLoading,
    required this.isPhoneLoading,
    required this.error,
    required this.onEmail,
    this.onGoogle,
    this.onPhone,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final secondaryTextColor = isDark ? Colors.white70 : const Color(0xFF6B7280);
    final dividerColor = isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
    final orTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF9CA3AF);
    final errorBgColor = isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2);
    final errorBorderColor = isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA);
    final errorTextColor = isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header with key icon and Injira title
        _FadeInSlide(
          delay: const Duration(milliseconds: 100),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF10B981).withOpacity(0.2) : const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.vpn_key_rounded, color: Color(0xFF059669), size: 24),
              ),
              const SizedBox(width: 14),
              Text(l10n?.signIn ?? 'Injira',
                  style: TextStyle(
                      color: textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5)),
            ],
          ),
        ),

        const SizedBox(height: 8),
        _FadeInSlide(
          delay: const Duration(milliseconds: 200),
          child: Text(l10n?.authSelectionSubtitle ?? 'Hitamo uburyo ushaka gukoresha ukomeze',
              style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.w500)),
        ),

        const SizedBox(height: 20),

        if (error != null && error!.isNotEmpty) ...[
          _FadeInSlide(
            delay: const Duration(milliseconds: 300),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: errorBgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: errorBorderColor),
              ),
              child: Row(children: [
                const Icon(Icons.error_rounded, color: Color(0xFFEF4444), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(error!,
                      style: TextStyle(
                          color: errorTextColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.3)),
                ),
              ]),
            ),
          ),
        ],

        // Phone Auth - First Option
        _FadeInSlide(
          delay: const Duration(milliseconds: 400),
          child: _PhoneAuthButton(
            label: l10n?.continueWithPhone ?? 'Komeza na Telefone',
            isLoading: isPhoneLoading,
            onPressed: isLoading ? null : onPhone,
            isDark: isDark,
          ),
        ),

        const SizedBox(height: 12),

        // Google Auth
        if (onGoogle != null && !kIsWeb) ...[
          _FadeInSlide(
            delay: const Duration(milliseconds: 500),
            child: _GoogleButton(
              isLoading: isGoogleLoading,
              onPressed: !isLoading ? onGoogle : null,
              isDark: isDark,
            ),
          ),
          const SizedBox(height: 12),
        ],

        // OR Divider
        _FadeInSlide(
          delay: const Duration(milliseconds: 600),
          child: Row(
            children: [
              Expanded(child: Divider(color: dividerColor, thickness: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(l10n?.or ?? 'OR',
                    style: TextStyle(
                        color: orTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5)),
              ),
              Expanded(child: Divider(color: dividerColor, thickness: 1)),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Email Auth
        _FadeInSlide(
          delay: const Duration(milliseconds: 700),
          child: _EmailButton(
            label: l10n?.continueWithEmail ?? 'Komeza na Email',
            isLoading: isEmailLoading,
            onPressed: isLoading ? null : onEmail,
            isDark: isDark,
          ),
        ),

        const SizedBox(height: 20),

        // Privacy notice at bottom
        _FadeInSlide(
          delay: const Duration(milliseconds: 800),
          child: _PrivacyNoticeBadge(isDark: isDark),
        ),
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
  bool _listenerRegistered = false;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  // Theme-aware getters
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _backgroundColor => _isDark ? const Color(0xFF0F172A) : _kSurface;
  Color get _cardColor => _isDark ? const Color(0xFF1E293B) : Colors.white;
  Color get _textColor => _isDark ? Colors.white : _kText1;
  Color get _secondaryTextColor => _isDark ? Colors.white70 : _kText2;
  Color get _borderColor => _isDark ? const Color(0xFF334155) : _kBorder;

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
    if (!_listenerRegistered) {
      _listenerRegistered = true;
      ref.listenManual(authProvider, (_, current) {
        if (current.user != null && !current.isLoading && !_hasNavigated) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _checkAndNavigate());
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant AuthSelectionScreen old) {
    super.didUpdateWidget(old);
    if (!_hasNavigated) _checkAndNavigate();
  }

  void _checkAndNavigate() async {
    final authState = ref.read(authProvider);
    // Gate navigation behind full auth restoration.
    // Prevents onboarding/home routing from firing while user is still null/loading.
    if (authState.user != null && !authState.isLoading && !_hasNavigated) {
      _hasNavigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (authState.user?.role == 'admin') {
          context.go('/admin');
        } else if (authState.user?.role != 'admin' && 
                   (authState.user?.hasCompletedOnboarding ?? false)) {
          // Students who completed onboarding go to dashboard
          context.go('/dashboard');
        } else if (authState.user?.role != 'admin') {
          // Students who haven't completed onboarding go through onboarding flow
          // (onboarding flow will check for phone number)
          context.go('/interest-selection');
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

    return Scaffold(
      backgroundColor: _backgroundColor,
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
    return Scaffold(
      body: Row(
        children: [
          // Left branding panel (45%)
          const Expanded(
            flex: 45,
            child: DesktopBrandPanel(
              headline: 'Welcome to',
              title: 'Excellence\nCoaching Hub',
              tagline: 'Empowering Growth.\nInspiring Excellence.',
            ),
          ),
          // Right white auth panel (55%)
          Expanded(
            flex: 55,
            child: Container(
              color: Colors.white,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 48, vertical: 60),
                    child: _AuthCard(
                      isLoading: authState.isLoading,
                      isEmailLoading: authState.isEmailLoading,
                      isGoogleLoading: authState.isGoogleLoading,
                      isPhoneLoading: authState.isPhoneLoading,
                      error: authState.error,
                      onEmail: () => context.push('/email-auth-option'),
                      onGoogle: null,
                      onPhone: () => context.push('/phone-auth'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF00C896),
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // ── Mobile layout (theme-aware background, compact) ─────────────────────────────────────────────────────────

  Widget _mobileLayout(dynamic authState) {
    final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final isShort = screenHeight < 700;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Back button at top left
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  if (context.canPop())
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: Icon(Icons.arrow_back_ios_rounded, 
                          color: _textColor, size: 20),
                    )
                  else
                    const SizedBox(width: 48),
                  const Spacer(),
                ],
              ),
            ),

            // Branding hero (compact)
            Padding(
              padding: EdgeInsets.symmetric(vertical: isShort ? 6 : 12),
              child: _BrandingSection(isMobile: true, isDark: _isDark),
            ),

            // Auth card (theme-aware rounded card)
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: _isDark ? [] : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    isSmallMobile ? 28 : 32,
                    isSmallMobile ? 28 : 32,
                    isSmallMobile ? 28 : 32,
                    isSmallMobile ? 28 : 32,
                  ),
                  child: _AuthCard(
                    isLoading: authState.isLoading,
                    isEmailLoading: authState.isEmailLoading,
                    isGoogleLoading: authState.isGoogleLoading,
                    isPhoneLoading: authState.isPhoneLoading,
                    error: authState.error,
                    onEmail: () => context.push('/email-auth-option'),
                    onGoogle: _handleGoogleSignIn,
                    onPhone: () => context.push('/phone-auth'),
                    isDark: _isDark,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}