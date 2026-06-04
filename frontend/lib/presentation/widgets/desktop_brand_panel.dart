import 'package:flutter/material.dart';

/// Shared left-side branding panel used on all desktop auth/onboarding screens.
class DesktopBrandPanel extends StatelessWidget {
  final String? headline;
  final String title;
  final String tagline;

  const DesktopBrandPanel({
    super.key,
    required this.title,
    required this.tagline,
    this.headline,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Light mode: rich forest green gradient; Dark mode: deep near-opaque dark
    final overlayColors = isDark
        ? [
            const Color(0xFF060C14).withOpacity(0.97),
            const Color(0xFF0A1A10).withOpacity(0.95),
            const Color(0xFF050E0A).withOpacity(0.98),
          ]
        : [
            const Color(0xFF0D3D28).withOpacity(0.78),
            const Color(0xFF0A5233).withOpacity(0.68),
            const Color(0xFF062E1C).withOpacity(0.82),
          ];

    final headlineColor = isDark
        ? const Color(0xFF10B981)
        : const Color(0xFF6EE7B7);

    final titleColor = Colors.white;

    final taglineColor = isDark
        ? const Color(0xFF94A3B8)
        : Colors.white.withOpacity(0.80);

    final pillBg = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.white.withOpacity(0.12);

    final pillBorder = isDark
        ? const Color(0xFF10B981).withOpacity(0.25)
        : Colors.white.withOpacity(0.30);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background landscape image
        Image.asset(
          'assets/onboading desktop.png',
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
        // Gradient overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: overlayColors,
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
        // Foreground content
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 52, vertical: 60),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo
              Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(isDark ? 0.10 : 0.18),
                  border: Border.all(
                    color: const Color(0xFF10B981).withOpacity(0.65),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.35),
                      blurRadius: 48,
                      spreadRadius: 6,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.30),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Headline label
              if (headline != null) ...[
                Text(
                  headline!,
                  style: TextStyle(
                    color: headlineColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Main title — large & bold
              Text(
                title,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  letterSpacing: -1.0,
                ),
              ),

              const SizedBox(height: 22),

              // Gradient accent bar
              Container(
                width: 56,
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF34D399)],
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // Tagline
              Text(
                tagline,
                style: TextStyle(
                  color: taglineColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 40),

              // Feature pills
              _FeaturePill(
                icon: Icons.school_rounded,
                label: 'Expert-led courses',
                pillBg: pillBg,
                pillBorder: pillBorder,
              ),
              const SizedBox(height: 12),
              _FeaturePill(
                icon: Icons.trending_up_rounded,
                label: 'Personalised learning path',
                pillBg: pillBg,
                pillBorder: pillBorder,
              ),
              const SizedBox(height: 12),
              _FeaturePill(
                icon: Icons.verified_rounded,
                label: 'Recognised certificates',
                pillBg: pillBg,
                pillBorder: pillBorder,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color pillBg;
  final Color pillBorder;

  const _FeaturePill({
    required this.icon,
    required this.label,
    required this.pillBg,
    required this.pillBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: pillBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: pillBorder, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF34D399), size: 18),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
