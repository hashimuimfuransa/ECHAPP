import 'dart:math' show pi, sin, cos, Random;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/localization_provider.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  bool _isInitializing = true;
  String _loadingMessage = 'Initializing app...';
  bool _didNavigate = false;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    // Start initialization check
    _checkInitializationStatus();

    // Start listening for auth changes (delayed to avoid build conflicts)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndNavigate();
    });

    // NOTE: no navigation fallback timer.
    // Routing must wait for auth restoration to finish to avoid racing
    // against the async session restore.
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _checkInitializationStatus() {
    // Check if background services are ready
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _loadingMessage = 'Preparing your learning experience...';
        });
      }
    });

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    });
  }
  
  Future<void> _navigateBasedOnAuth() async {
    if (_didNavigate) return;

    final authState = ref.read(authProvider);
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    // Only route when auth restoration is done.
    if (authState.isLoading) return;

    _didNavigate = true;

    // Check if user has selected language (for first-time users)
    final hasSelectedLanguage = await ref.read(localeProvider.notifier).hasSelectedLanguage();
    
    if (!hasSelectedLanguage && authState.user == null) {
      // First-time user - show language selection
      context.go('/language-selection');
      return;
    }

    if (authState.user != null) {
      final name = authState.user!.fullName;
      final needsName = name.isEmpty || name == 'Unknown User';
      if (needsName) {
        context.go('/name-collection');
      } else {
        context.go('/dashboard');
      }
    } else {
      if (isDesktop) {
        context.go('/email-auth-option');
      } else {
        context.go('/auth-selection');
      }
    }
  }

  void _checkAuthAndNavigate() {
    debugPrint('Splash: checkAuthAndNavigate');

    // Poll after first frame and then rely on authState.isLoading.
    // We also update the UI spinner independent of routing.
    Future.microtask(() async {
      if (!mounted) return;
      await _navigateBasedOnAuth();
    });

    // Listen to provider changes so navigation happens immediately
    // when auth restoration completes.
    ref.listenManual<AuthState>(authProvider, (previous, current) async {
      if (!mounted) return;
      _isInitializing = current.isLoading;
      if (!current.isLoading) {
        await _navigateBasedOnAuth();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background image
          _buildBackgroundImage(),
          // Gradient overlay
          _buildGradientOverlay(),
          // Floating animation
          _buildFloatingAnimation(),
          // Content
          SafeArea(
            child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundImage() {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
            isDesktop ? 'assets/onboading desktop.png' : 'assets/onboardign mobile.png',
          ),
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
            const Color(0xFF0F172A).withOpacity(0.4),
            const Color(0xFF1E293B).withOpacity(0.6),
            const Color(0xFF0F172A).withOpacity(0.8),
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
              child: _glowCircle(400, const Color(0xFF00C896).withOpacity(0.15), 70),
            ),
            Positioned(
              bottom: 80 + 40 * cos(t * 2 * pi + 1),
              left: -120 + 30 * sin(t * 2 * pi + 1),
              child: _glowCircle(300, const Color(0xFF34D399).withOpacity(0.1), 55),
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
                  opacity: 0.15 + 0.08 * sin(t * 2 * pi + i),
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

  Widget _buildDesktopLayout() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Left side - Logo and branding
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Image.asset(
                    'assets/logo.png',
                    width: 120,
                    height: 120,
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Excellence\nCoaching Hub',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Transforming Education\nThrough Technology',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 20,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          // Right side - Loading and features
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Loading indicator with enhanced styling
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      if (_isInitializing) ...[
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 4,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _loadingMessage,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ] else ...[
                        const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 48,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Ready to go!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 50),
                
                // Feature highlights
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                      width: 1,
                    ),
                  ),
                  child: const Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _FeatureItem(
                            icon: Icons.video_library,
                            label: 'Video Courses',
                          ),
                          _FeatureItem(
                            icon: Icons.quiz,
                            label: 'Interactive Quizzes',
                          ),
                          _FeatureItem(
                            icon: Icons.verified,
                            label: 'Certifications',
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _FeatureItem(
                            icon: Icons.groups,
                            label: 'Expert Instructors',
                          ),
                          _FeatureItem(
                            icon: Icons.mobile_friendly,
                            label: 'Learn Anywhere',
                          ),
                          _FeatureItem(
                            icon: Icons.track_changes,
                            label: 'Progress Tracking',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Top section with logo and brand
        Expanded(
          flex: 2,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Image.asset(
                    'assets/logo.png',
                    width: 80,
                    height: 80,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // App name
                const Text(
                  'Excellence Coaching Hub',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                const Text(
                  'Transforming Education Through Technology',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        
        // Bottom section with loading
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isInitializing) ...[
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C896)),
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _loadingMessage,
                      style: const TextStyle(
                        color: Color(0xFF4A5568),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ] else ...[
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF00C896),
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Ready to go!',
                      style: TextStyle(
                        color: Color(0xFF1A2433),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Helper widget for feature items
class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String label;
  
  const _FeatureItem({
    required this.icon,
    required this.label,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 28,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

}
