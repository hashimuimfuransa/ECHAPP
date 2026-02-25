import 'dart:math' show pi;
import 'package:flutter/foundation.dart';
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
const _kAccentDark = Color(0xFF047857);
const _kGold       = Color(0xFFFFBF00);
const _kSurface    = Color(0xFFF5F7FA);
const _kBorder     = Color(0xFFE4EAF2);
const _kText1      = Color(0xFF0D1B2A);
const _kText2      = Color(0xFF4A5568);
const _kText3      = Color(0xFF8A97AA);
const _kAmber      = Color(0xFFF59E0B);
const _kAmberBg    = Color(0xFFFFFBEB);
const _kAmberBorder= Color(0xFFFDE68A);

// ─── Glow circle ─────────────────────────────────────────────────────────────

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowCircle({required this.size, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}

// ─── Logo badge ───────────────────────────────────────────────────────────────

class _LogoBadge extends StatelessWidget {
  final double size;
  const _LogoBadge({this.size = 52});
  @override
  Widget build(BuildContext context) {
    final isLarge = size > 70;
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _kAccent.withOpacity(0.25),
            _kAccent.withOpacity(0.12),
          ],
        ),
        border: Border.all(
          color: _kAccent.withOpacity(isLarge ? 0.5 : 0.45),
          width: isLarge ? 2 : 1.5,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _kAccent.withOpacity(0.2),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/logo.webp',
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) =>
                Container(
                  color: _kAccent.withOpacity(0.1),
                  child: Icon(
                    Icons.school_rounded,
                    color: _kAccent,
                    size: size * 0.5,
                  ),
                ),
          ),
        ),
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

// ─── Brand panel ──────────────────────────────────────────────────────────────

class _BrandPanel extends StatelessWidget {
  final bool compact;
  const _BrandPanel({this.compact = false});

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
            ? [const Color(0xFF0D1F2D), const Color(0xFF1a3a4a), const Color(0xFF0F2835)]
            : [const Color(0xFF041420), const Color(0xFF062838), const Color(0xFF041B2D)],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          if (!compact)
            Positioned(top: -40, right: -40,
                child: _GlowCircle(size: 200,
                    color: _kAccent.withOpacity(0.08))),
          if (!compact)
            Positioned(bottom: 80, left: -30,
                child: _GlowCircle(size: 160,
                    color: _kGold.withOpacity(0.04))),
          if (compact) ...[
            Positioned(top: -80, right: -80,
                child: _GlowCircle(size: 220,
                    color: _kAccent.withOpacity(0.14))),
            Positioned(bottom: -100, left: -60,
                child: _GlowCircle(size: 180,
                    color: _kAccent.withOpacity(0.08))),
          ],
          SafeArea(
            child: SizedBox.expand(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? (isMobile ? 20 : 32) : 36,
                  vertical: compact ? (isMobile ? 16 : 24) : 32,
                ),
                child: compact ? _compactContent(isMobile) : _fullContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fullContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Logo + name row ──────────────────────────────────────────
        Row(children: [
          const _LogoBadge(),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Excellence',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2)),
              Text('Coaching Hub',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ]),

        const SizedBox(height: 32),

        // ── Headline ─────────────────────────────────────────────────
        // Bold large white text like in image
        RichText(
          text: TextSpan(
            style: const TextStyle(
                color: Colors.white,
                fontSize: 38,
                fontWeight: FontWeight.w900,
                height: 1.12,
                letterSpacing: -1.2),
            children: [
              const TextSpan(text: 'Unlock your\nfull '),
              TextSpan(
                text: 'potential.',
                style: TextStyle(color: _kAccent),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── Subheading matching image italic/mixed weight ─────────────
        RichText(
          text: const TextSpan(
            style: TextStyle(
                color: Colors.white70, fontSize: 14.5, height: 1.6),
            children: [
              TextSpan(text: 'Expert-led courses designed to '),
              TextSpan(
                text: 'transform',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700),
              ),
              TextSpan(text: '\nhow you learn, work, and '),
              TextSpan(
                text: 'grow.',
                style: TextStyle(
                    color: _kAccent,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // ── Feature rows ─────────────────────────────────────────────
        const _FeatureRow(
            icon: Icons.play_circle_outline_rounded,
            text: '1,000+ On-Demand Video Courses'),
        const _FeatureRow(
            icon: Icons.verified_outlined,
            text: 'Industry-Recognised Certifications'),
        const _FeatureRow(
            icon: Icons.people_outline_rounded,
            text: 'Live Mentorship & Coaching Sessions'),

        const Spacer(),
      ],
    );
  }

  Widget _compactContent(bool isMobile) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: isMobile ? 76 : 90,
          height: isMobile ? 76 : 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _kAccent.withOpacity(0.35),
                blurRadius: 32,
                spreadRadius: 6,
              ),
            ],
          ),
          child: _LogoBadge(size: isMobile ? 76 : 90),
        ),
        SizedBox(height: isMobile ? 16 : 24),
        Column(
          children: [
            Text('Excellence',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 22 : 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    height: 1.0)),
            SizedBox(height: isMobile ? 2 : 4),
            Text('Coaching Hub',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.68),
                    fontSize: isMobile ? 13 : 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3)),
          ],
        ),
        SizedBox(height: isMobile ? 14 : 20),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 15 : 18,
            vertical: isMobile ? 9 : 12,
          ),
          decoration: BoxDecoration(
            color: _kAccent.withOpacity(0.16),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _kAccent.withOpacity(0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: _kAccent.withOpacity(0.15),
                blurRadius: 12,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded,
                  color: _kAccent, size: isMobile ? 16 : 20),
              SizedBox(width: isMobile ? 7 : 10),
              Text('Expert-Led Learning',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: isMobile ? 11.5 : 13.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3)),
            ],
          ),
        ),
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
          height: isMobile ? 52 : 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kBorder, width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading)
                const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(_kAccent),
                  ),
                )
              else
                _GoogleGIcon(size: 22),
              const SizedBox(width: 14),
              Text(
                widget.isLoading ? 'Connecting...' : 'Continue with Google',
                style: TextStyle(
                    color: _kText1,
                    fontSize: isMobile ? 15 : 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2),
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
    final r = size.width / 2;
    final cx = r;
    final cy = r;

    final colors = [
      const Color(0xFF4285F4), // blue - top-right arc
      const Color(0xFF34A853), // green - bottom-right
      const Color(0xFFFBBC05), // yellow - bottom-left
      const Color(0xFFEA4335), // red - top-left
    ];

    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = size.width * 0.17;
    final sweeps = [pi / 2, pi / 2, pi / 2, pi / 2];

    double startAngle = -pi / 4;
    for (int i = 0; i < 4; i++) {
      paint.color = colors[i];
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r - paint.strokeWidth / 2),
        startAngle,
        sweeps[i],
        false,
        paint,
      );
      startAngle += sweeps[i];
    }

    // White cutout bar for the "G" crossbar
    final barPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.17
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + r * 0.7, cy),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
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
              colors: [_kAccent, _kAccentDark],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: _kAccent.withOpacity(0.4),
                  blurRadius: 24,
                  spreadRadius: -4,
                  offset: const Offset(0, 8)),
            ],
          ),
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
              Text(widget.label,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 15 : 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2)),
            ],
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
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18)),
          title: const Text('Legal',
              style: TextStyle(fontWeight: FontWeight.w700)),
          content: const Text('What would you like to view?'),
          actions: [
            TextButton(
              onPressed: () { Navigator.pop(context); context.push('/privacy'); },
              child: const Text('Privacy'),
            ),
            TextButton(
              onPressed: () { Navigator.pop(context); context.push('/terms'); },
              child: const Text('Terms'),
            ),
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: const Text('Cancel',
                  style: TextStyle(color: _kText3)),
            ),
          ],
        ),
      ),
      child: Text.rich(
        TextSpan(
          style: TextStyle(
              color: _kText3, 
              fontSize: isMobile ? 11.5 : 12.5, 
              height: 1.5),
          children: [
            const TextSpan(text: 'By continuing, you agree to '),
            TextSpan(
              text: 'Terms',
              style: const TextStyle(
                  color: _kAccentDark,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                  decorationColor: _kAccentDark),
            ),
            const TextSpan(text: ' & '),
            TextSpan(
              text: 'Privacy',
              style: const TextStyle(
                  color: _kAccentDark,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                  decorationColor: _kAccentDark),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
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
        Icon(Icons.verified_user_outlined, 
          size: isMobile ? 13 : 15, 
          color: _kAccentDark),
        const SizedBox(width: 4),
        Text('Secure & Encrypted',
            style: TextStyle(
                color: _kText2, 
                fontSize: isMobile ? 11 : 12.5,
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
        Text('Sign In',
            style: TextStyle(
                color: _kText1,
                fontSize: isMobile ? 26 : 32,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6)),
        const SizedBox(height: 4),
        Text('Continue your learning',
            style: TextStyle(
                color: _kText2, 
                fontSize: isMobile ? 13.5 : 15,
                height: 1.4,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Container(
            width: 40, height: 2.5,
            decoration: BoxDecoration(
                color: _kAccent,
                borderRadius: BorderRadius.circular(2))),

        const SizedBox(height: 24),

        _PrimaryButton(
          icon: Icons.mail_outline_rounded,
          label: 'Continue with Email',
          isLoading: isLoading,
          onPressed: isLoading ? null : onEmail,
        ),

        if (error != null && error!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(children: [
              Icon(Icons.error_outline, color: Colors.red.shade400, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(error!,
                    style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        height: 1.3)),
              ),
            ]),
          ),
        ],

        const SizedBox(height: 16),

        if (!ResponsiveBreakpoints.isDesktop(context) && onGoogle != null && !kIsWeb) ...[
          _GoogleButton(
            isLoading: isLoading,
            onPressed: !isLoading ? onGoogle : null,
          ),
          const SizedBox(height: 18),
        ],

        const _DeviceWarningBadge(),

        const SizedBox(height: 16),

        const _TermsFooter(),

        const SizedBox(height: 14),

        const _TrustBar(),

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
        // Left brand panel — 45% width (image has roughly equal halves)
        const Expanded(flex: 45, child: _BrandPanel()),

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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
            width: screenWidth,
            height: screenHeight * 0.35,
            child: const SafeArea(
              bottom: false,
              child: _BrandPanel(compact: true),
            ),
          ),
          Container(
            width: screenWidth,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 28,
                    offset: Offset(0, -8)),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: _AuthCard(
                isLoading: authState.isLoading,
                error: authState.error,
                onEmail: () => context.push('/email-auth-option'),
                onGoogle: _handleGoogleSignIn,
              ),
            ),
          ),
        ],
      ),
    );
  }
}