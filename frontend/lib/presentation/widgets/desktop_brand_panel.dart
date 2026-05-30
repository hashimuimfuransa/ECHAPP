import 'package:flutter/material.dart';

/// Shared left-side branding panel used on all desktop auth/onboarding screens.
/// Matches the design: nature background image + light green overlay + logo + title.
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
    
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background landscape image
        Image.asset(
          'assets/onboading desktop.png',
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
        // Soft green gradient overlay — mimics the image design
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      const Color(0xFF0F172A).withOpacity(0.85),
                      const Color(0xFF1E293B).withOpacity(0.75),
                      const Color(0xFF0D4A38).withOpacity(0.65),
                    ]
                  : [
                      const Color(0xFFE8F5F0).withOpacity(0.60),
                      const Color(0xFFB2DFCF).withOpacity(0.35),
                      const Color(0xFF0D4A38).withOpacity(0.45),
                    ],
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
              // Circular logo
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  border: Border.all(
                    color: const Color(0xFF00C896).withOpacity(0.20),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.30 : 0.10),
                      blurRadius: 24,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Image.asset(
                      'assets/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 44),
              if (headline != null) ...[
                Text(
                  headline!,
                  style: TextStyle(
                    color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1B3A2A),
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Text(
                title,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0C3A28),
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 20),
              // Green accent divider
              Container(
                width: 40,
                height: 3,
                decoration: BoxDecoration(
                  color: const Color(0xFF00C896),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                tagline,
                style: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF2D5A46),
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  height: 1.65,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
