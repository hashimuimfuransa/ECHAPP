import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellence_coaching_hub/presentation/providers/auth_provider.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFF6A11CB), // Simple solid color
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Simple logo or icon
              const Icon(
                Icons.school,
                size: 80,
                color: Colors.white,
              ),
              
              const SizedBox(height: 20),
              
              // Simple app name
              const Text(
                'Excellence Coaching Hub',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 30),
              
              // Simple loading indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

}