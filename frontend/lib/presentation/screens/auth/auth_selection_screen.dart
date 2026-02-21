import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';

// ─── Palette ─────────────────────────────────────────────────────────────────
const _kDeep       = Color(0xFF0A1628);
const _kMid        = Color(0xFF112240);
const _kAccent     = Color(0xFF00C896);
const _kAccentDark = Color(0xFF009E76);
const _kGold       = Color(0xFFFFD166);
const _kSurface    = Color(0xFFF7F9FC);
const _kBorder     = Color(0xFFE4EAF2);
const _kText1      = Color(0xFF0D1B2A);
const _kText2      = Color(0xFF4A5568);
const _kText3      = Color(0xFF8A97AA);

// ─── Small helpers ────────────────────────────────────────────────────────────

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

class _VertDivider extends StatelessWidget {
  const _VertDivider();
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 36, color: Colors.white.withOpacity(0.12));
}

class _LogoBadge extends StatelessWidget {
  final double size;
  const _LogoBadge({this.size = 52});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(size * 0.26),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.26),
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

// ─── Stat pill ────────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final String value;
  final String label;
  const _StatPill({required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: const TextStyle(
                  color: _kGold, fontSize: 20, fontWeight: FontWeight.w800,
                  letterSpacing: -0.4)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: Colors.white54, fontSize: 11.5,
                  fontWeight: FontWeight.w500)),
        ],
      );
}

// ─── Feature row ──────────────────────────────────────────────────────────────

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureRow({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: _kAccent.withOpacity(0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: _kAccent, size: 17),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 14,
                    fontWeight: FontWeight.w500, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

// ─── Mini stat chip (compact/mobile brand panel) ──────────────────────────────

class _MiniStat extends StatelessWidget {
  final String label;
  const _MiniStat({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white70, fontSize: 11,
              fontWeight: FontWeight.w500)),
    );
  }
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
          colors: [_kDeep, _kMid, Color(0xFF0E3460)],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(top: -70, right: -70,
              child: _GlowCircle(size: 230, color: _kAccent.withOpacity(0.07))),
          Positioned(bottom: -50, left: -50,
              child: _GlowCircle(size: 190, color: _kGold.withOpacity(0.05))),
          Positioned(top: 110, left: -35,
              child: _GlowCircle(size: 110, color: _kAccent.withOpacity(0.04))),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(compact ? 24 : 40),
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
        const SizedBox(height: 4),
        // Logo row
        Row(children: [
          const _LogoBadge(),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Excellence',
                  style: TextStyle(color: Colors.white, fontSize: 17,
                      fontWeight: FontWeight.w800, letterSpacing: -0.2)),
              Text('Coaching Hub',
                  style: TextStyle(color: Colors.white60, fontSize: 13,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ]),
        const Spacer(),
        // Headline
        const Text('Unlock your\nfull potential.',
            style: TextStyle(color: Colors.white, fontSize: 36,
                fontWeight: FontWeight.w800, height: 1.18,
                letterSpacing: -1.0)),
        const SizedBox(height: 10),
        Container(
            width: 44, height: 3,
            decoration: BoxDecoration(
                color: _kAccent,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 18),
        const Text(
          'Expert-led courses designed to transform how you learn, work, and grow.',
          style: TextStyle(color: Colors.white54, fontSize: 14.5, height: 1.65),
        ),
        const SizedBox(height: 32),
        const _FeatureRow(icon: Icons.play_circle_outline_rounded,
            text: '1,000+ on-demand video courses'),
        const _FeatureRow(icon: Icons.verified_outlined,
            text: 'Industry-recognised certifications'),
        const _FeatureRow(icon: Icons.people_outline_rounded,
            text: 'Live mentorship & coaching sessions'),
        const Spacer(),
        // Stats block
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.09)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatPill(value: '5,200+', label: 'Active learners'),
              _VertDivider(),
              _StatPill(value: '98%', label: 'Satisfaction'),
              _VertDivider(),
              _StatPill(value: '120+', label: 'Expert coaches'),
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
        const _LogoBadge(size: 58),
        const SizedBox(height: 12),
        const Text('Excellence Coaching Hub',
            style: TextStyle(color: Colors.white, fontSize: 18,
                fontWeight: FontWeight.w700, letterSpacing: -0.2)),
        const SizedBox(height: 4),
        const Text('Unlock your full potential.',
            style: TextStyle(color: Colors.white60, fontSize: 13)),
        const SizedBox(height: 16),
        const Wrap(
          spacing: 8, runSpacing: 8,
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

// ─── Animated auth button ─────────────────────────────────────────────────────

class _AuthButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final bool isLoading;
  final VoidCallback? onPressed;
  const _AuthButton({
    required this.icon,
    required this.label,
    this.isPrimary = false,
    this.isLoading = false,
    this.onPressed,
  });
  @override
  State<_AuthButton> createState() => _AuthButtonState();
}

class _AuthButtonState extends State<_AuthButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 110));
    _scale = Tween<double>(begin: 1, end: 0.965).animate(
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
          height: 54,
          decoration: BoxDecoration(
            gradient: widget.isPrimary
                ? const LinearGradient(
                    colors: [_kAccent, _kAccentDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight)
                : null,
            color: widget.isPrimary ? null : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: widget.isPrimary
                ? null
                : Border.all(color: _kBorder, width: 1.5),
            boxShadow: widget.isPrimary
                ? [BoxShadow(color: _kAccent.withOpacity(0.32),
                    blurRadius: 20, offset: const Offset(0, 7))]
                : [BoxShadow(color: Colors.black.withOpacity(0.04),
                    blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading)
                SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        widget.isPrimary ? Colors.white : _kText1),
                  ),
                )
              else
                Icon(widget.icon, size: 20,
                    color: widget.isPrimary ? Colors.white : _kText1),
              const SizedBox(width: 10),
              Text(widget.label,
                  style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                    color: widget.isPrimary ? Colors.white : _kText1,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Device warning badge ─────────────────────────────────────────────────────

class _DeviceWarningBadge extends StatelessWidget {
  const _DeviceWarningBadge();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFD166).withOpacity(0.55)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline_rounded,
              color: Color(0xFFF59E0B), size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Account binds to first device. Contact support to change devices.',
              style: TextStyle(
                color: _kText1.withOpacity(0.72), fontSize: 12,
                fontWeight: FontWeight.w500, height: 1.5,
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
              onPressed: () => Navigator.pop(context),
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
            TextSpan(text: 'Terms of Service',
                style: const TextStyle(
                    color: _kAccentDark, fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: _kAccentDark)),
            const TextSpan(text: ' & '),
            TextSpan(text: 'Privacy Policy',
                style: const TextStyle(
                    color: _kAccentDark, fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: _kAccentDark)),
          ],
        ),
        textAlign: TextAlign.center,
      ),
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
        const Text('Welcome back',
            style: TextStyle(
                color: _kText1, fontSize: 27, fontWeight: FontWeight.w800,
                letterSpacing: -0.6)),
        const SizedBox(height: 6),
        const Text('Sign in to continue your learning journey.',
            style: TextStyle(
                color: _kText2, fontSize: 14.5, height: 1.5)),
        const SizedBox(height: 28),

        _AuthButton(
          icon: Icons.account_circle_outlined,
          label: isLoading ? 'Signing in…' : 'Continue with Google',
          isLoading: isLoading,
          onPressed: isLoading ? null : onGoogle,
        ),
        const SizedBox(height: 14),

        Row(children: [
          const Expanded(child: Divider(color: _kBorder, thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text('or', style: TextStyle(
                color: _kText3, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          const Expanded(child: Divider(color: _kBorder, thickness: 1)),
        ]),
        const SizedBox(height: 14),

        _AuthButton(
          icon: Icons.mail_outline_rounded,
          label: 'Continue with Email',
          isPrimary: true,
          onPressed: onEmail,
        ),

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
                        color: Colors.red.shade700, fontSize: 13,
                        fontWeight: FontWeight.w500)),
              ),
            ]),
          ),
        ],

        const SizedBox(height: 20),
        const _DeviceWarningBadge(),
        const SizedBox(height: 16),
        const _TermsFooter(),
        const SizedBox(height: 12),

        Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
          Icon(Icons.verified_user_outlined, size: 13, color: _kText3),
          SizedBox(width: 5),
          Text('Secure login  ·  Trusted by 5,200+ learners',
              style: TextStyle(
                  color: _kText3, fontSize: 11.5, fontWeight: FontWeight.w500)),
        ]),
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
        vsync: this, duration: const Duration(milliseconds: 480));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fadeCtrl.forward());
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
        child: isDesktop ? _desktopLayout(authState) : _mobileLayout(authState),
      ),
    );
  }

  // ── Desktop layout ────────────────────────────────────────────────────────

  Widget _desktopLayout(dynamic authState) {
    return Row(
      children: [
        // Left brand panel — 42 % width
        const Expanded(flex: 42, child: _BrandPanel()),

        // Right auth panel — 58 % width
        Expanded(
          flex: 58,
          child: Container(
            color: _kSurface,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
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
          height: MediaQuery.of(context).size.height * 0.28,
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
                    color: Color(0x14000000),
                    blurRadius: 24, offset: Offset(0, -4)),
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