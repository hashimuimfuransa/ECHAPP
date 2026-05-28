import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _isInitializing = true;
  String _loadingMessage = 'Initializing app...';
  bool _didNavigate = false;
  
  @override
  void initState() {
    super.initState();
    
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
  
  void _navigateBasedOnAuth() {
    if (_didNavigate) return;

    final authState = ref.read(authProvider);
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    // Only route when auth restoration is done.
    if (authState.isLoading) return;

    _didNavigate = true;

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
    Future.microtask(() {
      if (!mounted) return;
      _navigateBasedOnAuth();
    });

    // Listen to provider changes so navigation happens immediately
    // when auth restoration completes.
    ref.listenManual<AuthState>(authProvider, (previous, current) {
      if (!mounted) return;
      _isInitializing = current.isLoading;
      if (!current.isLoading) {
        _navigateBasedOnAuth();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    
    if (isDesktop) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF00C896),
                Color(0xFF059669),
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
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
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Transforming Education Through Technology',
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
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              if (_isInitializing) ...[
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  strokeWidth: 4,
                                ),
                                SizedBox(height: 20),
                                Text(
                                  _loadingMessage,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                              ] else ...[
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 48,
                                ),
                                SizedBox(height: 20),
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
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
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
            ),
          ),
        ),
      );
    } else {
      // Mobile layout with modern design matching auth screens
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF00C896),
                Color(0xFF059669),
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Image.asset(
                      'assets/logo.png',
                      width: 100,
                      height: 100,
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // App name
                  const Text(
                    'Excellence Coaching Hub',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  const Text(
                    'Transforming Education Through Technology',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 50),
                  
                  if (_isInitializing) ...[
                    // Loading indicator
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Loading message
                    Text(
                      _loadingMessage,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ] else ...[
                    // Success indicator
                    const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 56,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    const Text(
                      'Ready to go!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }
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
