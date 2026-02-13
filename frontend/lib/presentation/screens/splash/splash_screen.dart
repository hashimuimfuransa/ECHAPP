import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:excellence_coaching_hub/presentation/providers/auth_provider.dart';
import 'package:excellence_coaching_hub/utils/responsive_utils.dart';
import 'package:excellence_coaching_hub/config/app_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    
    // Simple navigation after minimal delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      _navigateBasedOnAuth();
    });
  }
  
  void _navigateBasedOnAuth() {
    final authState = ref.read(authProvider);
    
    if (authState.user != null && !authState.isLoading) {
      context.go('/dashboard');
    } else {
      context.go('/auth-selection');
    }
  }

  void _checkAuthAndNavigate() {
    // Listen for auth state changes
    ref.listen(authProvider, (previous, current) {
      debugPrint('Splash: Auth state changed - User: ${current.user != null}, Loading: ${current.isLoading}');
      
      // Only navigate after the splash animation completes and we have a definitive auth state
      if (!current.isLoading) {
        if (current.user != null) {
          debugPrint('Splash: Navigating to dashboard');
          context.go('/dashboard');
        } else {
          debugPrint('Splash: Navigating to auth selection');
          context.go('/auth-selection');
        }
      }
    });
    
    // Also check initial state after delay
    Future.delayed(const Duration(milliseconds: 2500), () {
      final authState = ref.read(authProvider);
      debugPrint('Splash: Initial check - User: ${authState.user != null}, Loading: ${authState.isLoading}');
      
      if (!authState.isLoading) {
        if (authState.user != null) {
          context.go('/dashboard');
        } else {
          context.go('/auth-selection');
        }
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
                Color(0xFF6A11CB),
                Color(0xFF2575FC),
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
                            color: AppTheme.whiteColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Icon(
                            Icons.school,
                            size: 100,
                            color: Colors.white,
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
                            color: AppTheme.whiteColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Column(
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 4,
                              ),
                              SizedBox(height: 20),
                              Text(
                                'Preparing your learning experience...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 50),
                        
                        // Feature highlights
                        Container(
                          padding: const EdgeInsets.all(25),
                          decoration: BoxDecoration(
                            color: AppTheme.whiteColor.withOpacity(0.05),
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
      // Mobile layout (enhanced original design)
      return const Scaffold(
        backgroundColor: Color(0xFF6A11CB),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo or icon
                Icon(
                  Icons.school,
                  size: 80,
                  color: Colors.white,
                ),
                
                SizedBox(height: 20),
                
                // App name
                Text(
                  'Excellence Coaching Hub',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: 30),
                
                // Loading indicator
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ],
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