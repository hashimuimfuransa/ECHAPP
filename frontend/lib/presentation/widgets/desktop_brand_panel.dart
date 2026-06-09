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
    return const _NewDesktopBrandPanel();
  }
}

class _NewDesktopBrandPanel extends StatelessWidget {
  const _NewDesktopBrandPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF071A0F),
            Color(0xFF0A2415),
            Color(0xFF071810),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Subtle dot-grid texture overlay
          Opacity(
            opacity: 0.06,
            child: Image.asset(
              'assets/onboading desktop.png',
              fit: BoxFit.cover,
            ),
          ),
          // Glow blob bottom-right
          Positioned(
            bottom: -60,
            right: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.18),
                    blurRadius: 120,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),
          // Main content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top logo row ──────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: const Color(0xFF10B981).withOpacity(0.55),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.35),
                            blurRadius: 20,
                            spreadRadius: 3,
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(0.25),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Padding(
                          padding: const EdgeInsets.all(7),
                          child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Excellence',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Coaching Hub',
                          style: TextStyle(
                            color: const Color(0xFF10B981),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Journey pill ──────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF10B981).withOpacity(0.35),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: Color(0xFF34D399),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Your Journey to Excellence Starts Here',
                        style: TextStyle(
                          color: const Color(0xFF34D399),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Main headline ─────────────────────────────────────────
                const Text(
                  'Learn. Grow.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                    letterSpacing: -0.5,
                  ),
                ),
                const Text(
                  'Succeed.',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 10),

                // ── Description ───────────────────────────────────────────
                Text(
                  'Empowering learners with world-class courses,\nexpert guidance, and a path to excellence.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 16),

                // ── Stat cards row ────────────────────────────────────────
                Row(
                  children: [
                    Expanded(child: _StatCard(value: '1,000+', label: 'Students', icon: Icons.school_rounded)),
                    const SizedBox(width: 10),
                    Expanded(child: _StatCard(value: '50+', label: 'Courses', icon: Icons.menu_book_rounded)),
                    const SizedBox(width: 10),
                    Expanded(child: _StatCard(value: '95%', label: 'Success Rate', icon: Icons.trending_up_rounded)),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Illustration image ────────────────────────────────────
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/Course app-bro.png',
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter,
                      errorBuilder: (c, e, s) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.18),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF34D399), size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
