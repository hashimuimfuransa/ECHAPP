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
  
  @override
  void initState() {
    super.initState();
    
    // Start initialization check
    _checkInitializationStatus();
    
    // Start listening for auth changes (delayed to avoid build conflicts)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndNavigate();
    });
    
    // Simple navigation after reasonable delay as fallback
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _loadingMessage = 'Almost ready...';
        });
        // Delay navigation to ensure build is complete
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigateBasedOnAuth();
        });
      }
    });
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
    final authState = ref.read(authProvider);
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    
    if (authState.user != null && !authState.isLoading) {
      context.go('/dashboard');
    } else {
      if (isDesktop) {
        context.go('/email-auth-option');
      } else {
        context.go('/auth-selection');
      }
    }
  }

  void _checkAuthAndNavigate() {
    // Check initial auth state
    final authState = ref.read(authProvider);
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    debugPrint('Splash: Initial auth check - User: ${authState.user != null}, Loading: ${authState.isLoading}');
    
    // Navigate based on current state (delayed to avoid build conflicts)
    if (!authState.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (authState.user != null) {
          debugPrint('Splash: Navigating to dashboard');
          context.go('/dashboard');
        } else {
          if (isDesktop) {
            debugPrint('Splash: Navigating to email auth option (desktop)');
            context.go('/email-auth-option');
          } else {
            debugPrint('Splash: Navigating to auth selection (mobile)');
            context.go('/auth-selection');
          }
        }
      });
    }
    
    // Also check initial state after delay
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return; // Check if widget is still mounted
      final authState = ref.read(authProvider);
      debugPrint('Splash: Initial check - User: ${authState.user != null}, Loading: ${authState.isLoading}');
      
      if (!authState.isLoading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return; // Check again before navigation
          if (authState.user != null) {
            context.go('/dashboard');
          } else {
            if (isDesktop) {
              context.go('/email-auth-option');
            } else {
              context.go('/auth-selection');
            }
          }
        });
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
                                  style: TextStyle(
                                    color: AppTheme.getTextColor(context),
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
                                Text(
                                  'Ready to go!',
                                  style: TextStyle(
                                    color: AppTheme.getTextColor(context),
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
      return Scaffold(
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
                
                if (_isInitializing) ...[
                  // Loading indicator
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Loading message
                  Text(
                    _loadingMessage,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  // Success indicator
                  Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 48,
                  ),
                  
                  SizedBox(height: 20),
                  
                  Text(
                    'Ready to go!',
                    style: TextStyle(
                      color: Colors.white,
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
