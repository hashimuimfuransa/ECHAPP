import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';

// ─── Palette (matches image exactly) ─────────────────────────────────────────
const _kDeep       = Color(0xFF041B2D);   // very dark navy
const _kMid        = Color(0xFF072A3E);   // deep teal-navy
const _kTeal       = Color(0xFF0A4A5A);   // mid teal
const _kAccent     = Color(0xFF00C896);   // bright mint green
const _kAccentDark = Color(0xFF009E76);
const _kGold       = Color(0xFFFFBF00);   // vivid gold/amber
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
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: _kAccent.withOpacity(0.18),
        borderRadius: BorderRadius.circular(size * 0.24),
        border: Border.all(color: _kAccent.withOpacity(0.45), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.24),
        child: Image.asset(
          'assets/logo.webp',
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) =>
              Icon(Icons.school_outlined, color: _kAccent, size: size * 0.55),
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
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          // Matches the dark teal-to-navy gradient in the image
          colors: [Color(0xFF041420), Color(0xFF062838), Color(0xFF041B2D)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Subtle teal glow top-right (matches image)
          Positioned(top: -40, right: -40,
              child: _GlowCircle(size: 200,
                  color: _kAccent.withOpacity(0.08))),
          Positioned(bottom: 80, left: -30,
              child: _GlowCircle(size: 160,
                  color: _kGold.withOpacity(0.04))),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(compact ? 24 : 36),
              child: compact ? _compactContent() : _fullContent(),
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

        // ── Stats bar (matches image: gold numbers, stars, white labels) ──
        Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: const [
              _StatPill(
                  value: '5,200+',
                  label: 'Active Learners'),
              _VertDivider(),
              _StatPill(
                  value: '98%',
                  label: 'Satisfaction',
                  extra: _StarRating()),
              _VertDivider(),
              _StatPill(
                  value: '120+',
                  label: 'Expert Coaches'),
            ],
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _compactContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _LogoBadge(size: 60),
        const SizedBox(height: 10),
        const Text('Excellence Coaching Hub',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 13),
            children: [
              const TextSpan(
                  text: 'Unlock your full ',
                  style: TextStyle(color: Colors.white60)),
              TextSpan(
                  text: 'potential.',
                  style: TextStyle(
                      color: _kAccent, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _MiniStat(label: '5,200+ Learners'),
            _MiniStat(label: '98% Satisfaction'),
            _MiniStat(label: '120+ Coaches'),
          ],
        ),
      ],
    );
  }
}

// ─── Google sign-in button (matches image: white bg, coloured G icon) ─────────

class _GoogleButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onPressed?.call(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: 56,
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
                  width: 22, height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                // Google "G" logo using coloured segments
                _GoogleGIcon(size: 22),
              const SizedBox(width: 12),
              Text(
                widget.isLoading ? 'Signing in…' : 'Continue with Google',
                style: const TextStyle(
                    color: _kText1,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1),
              ),
              const Spacer(),
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(Icons.chevron_right_rounded,
                    color: _kText3, size: 22),
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

// Need dart:math for pi
import 'dart:math' show pi;

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
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onPressed?.call(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00C896), Color(0xFF009E76)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: _kAccent.withOpacity(0.38),
                  blurRadius: 22,
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
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white)),
                )
              else
                Icon(widget.icon, color: Colors.white, size: 21),
              const SizedBox(width: 10),
              Text(widget.label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2)),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _kAmberBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kAmberBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline_rounded,
              color: _kAmber, size: 17),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                    color: _kText1.withOpacity(0.75),
                    fontSize: 12.5,
                    height: 1.55,
                    fontWeight: FontWeight.w500),
                children: [
                  const TextSpan(text: 'Account binds to first device. '),
                  TextSpan(
                    text: 'Contact support',
                    style: const TextStyle(
                        color: _kAmber,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                        decorationColor: _kAmber),
                  ),
                  const TextSpan(text: ' to change devices.'),
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
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18)),
          title: const Text('Legal Documents',
              style: TextStyle(fontWeight: FontWeight.w700)),
          content: const Text('What would you like to view?'),
          actions: [
            TextButton(
              onPressed: () { Navigator.pop(context); context.push('/privacy'); },
              child: const Text('Privacy Policy'),
            ),
            TextButton(
              onPressed: () { Navigator.pop(context); context.push('/terms'); },
              child: const Text('Terms of Service'),
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
          style: const TextStyle(
              color: _kText3, fontSize: 12.5, height: 1.6),
          children: [
            const TextSpan(text: 'By continuing you agree to our '),
            TextSpan(
              text: 'Terms of Service',
              style: const TextStyle(
                  color: _kAccentDark,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                  decorationColor: _kAccentDark),
            ),
            const TextSpan(text: '\n& '),
            TextSpan(
              text: 'Privacy Policy',
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Overlapping avatar circles
        SizedBox(
          width: 80,
          height: 28,
          child: Stack(
            children: List.generate(4, (i) => Positioned(
              left: i * 18.0,
              child: Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _avatarColors[i],
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    ['A', 'B', 'C', 'D'][i],
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
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
            style: const TextStyle(
                color: _kText3, fontSize: 12, fontWeight: FontWeight.w500),
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
        Icon(Icons.verified_user_outlined, size: 15, color: _kAccentDark),
        const SizedBox(width: 5),
        Text('Secure Login',
            style: const TextStyle(
                color: _kText2, fontSize: 12.5,
                fontWeight: FontWeight.w600)),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 4, height: 4,
          decoration: const BoxDecoration(
              shape: BoxShape.circle, color: _kText3),
        ),
        const _AvatarRow(),
      ],
    );
  }
}

// ─── Auth card ────────────────────────────────────────────────────────────────

class _AuthCard extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final VoidCallback onGoogle;
  final VoidCallback onEmail;

  const _AuthCard({
    required this.isLoading,
    required this.error,
    required this.onGoogle,
    required this.onEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Headline ────────────────────────────────────────────────
        const Text('Welcome back!',
            style: TextStyle(
                color: _kText1,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.7)),
        const SizedBox(height: 6),
        // Subtitle with teal underline accent (matches image)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sign in to continue your learning journey.',
                style: TextStyle(
                    color: _kText2, fontSize: 15, height: 1.4)),
            const SizedBox(height: 5),
            Container(
                width: 60, height: 2.5,
                decoration: BoxDecoration(
                    color: _kAccent,
                    borderRadius: BorderRadius.circular(2))),
          ],
        ),

        const SizedBox(height: 28),

        // ── Google button ────────────────────────────────────────────
        _GoogleButton(
          isLoading: isLoading,
          onPressed: isLoading ? null : onGoogle,
        ),

        const SizedBox(height: 16),

        // ── OR divider ───────────────────────────────────────────────
        Row(children: [
          const Expanded(child: Divider(color: _kBorder, thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('or',
                style: TextStyle(
                    color: _kText3,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500)),
          ),
          const Expanded(child: Divider(color: _kBorder, thickness: 1)),
        ]),

        const SizedBox(height: 16),

        // ── Email button ─────────────────────────────────────────────
        _PrimaryButton(
          icon: Icons.mail_outline_rounded,
          label: 'Continue with Email',
          onPressed: onEmail,
        ),

        // ── Error message ────────────────────────────────────────────
        if (error != null && error!.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
              ),
            ]),
          ),
        ],

        const SizedBox(height: 20),

        // ── Device warning ───────────────────────────────────────────
        const _DeviceWarningBadge(),

        const SizedBox(height: 18),

        // ── Terms footer ─────────────────────────────────────────────
        const _TermsFooter(),

        const SizedBox(height: 20),

        // ── Trust bar ────────────────────────────────────────────────
        const _TrustBar(),

        const SizedBox(height: 8),
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

  void _signInWithGoogle() {
    _hasNavigated = false;
    ref.read(authProvider.notifier).signInWithGoogle();
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
                    onGoogle: _signInWithGoogle,
                    onEmail: () => context.push('/email-auth-option'),
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
    return Column(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.30,
          child: const SafeArea(
            bottom: false,
            child: _BrandPanel(compact: true),
          ),
        ),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                    color: Color(0x16000000),
                    blurRadius: 28,
                    offset: Offset(0, -6)),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
              child: _AuthCard(
                isLoading: authState.isLoading,
                error: authState.error,
                onGoogle: _signInWithGoogle,
                onEmail: () => context.push('/email-auth-option'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}