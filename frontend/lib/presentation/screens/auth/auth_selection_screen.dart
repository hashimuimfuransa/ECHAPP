import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellence_coaching_hub/presentation/providers/auth_provider.dart';
import 'package:excellence_coaching_hub/config/app_theme.dart';

class AuthSelectionScreen extends ConsumerStatefulWidget {
  const AuthSelectionScreen({super.key});

  @override
  _AuthSelectionScreenState createState() => _AuthSelectionScreenState();
}

class _AuthSelectionScreenState extends ConsumerState<AuthSelectionScreen> {
  bool _hasNavigated = false;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only check navigation if we haven't navigated yet
    if (!_hasNavigated) {
      _checkAndNavigate();
    }
  }

  @override
  void didUpdateWidget(covariant AuthSelectionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only check navigation if we haven't navigated yet
    if (!_hasNavigated) {
      _checkAndNavigate();
    }
  }

  void _checkAndNavigate() {
    final authState = ref.watch(authProvider);
    debugPrint('AuthSelection: Checking navigation - User: ${authState.user != null}, Loading: ${authState.isLoading}, Error: ${authState.error}');
    
    // Navigate to dashboard when user is authenticated and not loading
    if (authState.user != null && !authState.isLoading && !_hasNavigated) {
      _hasNavigated = true;
      debugPrint('AuthSelection: Navigating to dashboard for role: ${authState.user?.role}');
      
      // Show success message if available
      if (authState.error != null && authState.error!.isNotEmpty) {
        // Show snackbar with success message
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authState.error!),
              backgroundColor: AppTheme.primaryGreen,
              duration: const Duration(seconds: 3),
            ),
          );
        });
      }
      
      // Navigate to appropriate dashboard based on user role
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (authState.user?.role == 'admin') {
          debugPrint('AuthSelection: Navigating to admin dashboard');
          context.go('/admin');
        } else {
          debugPrint('AuthSelection: Navigating to student dashboard');
          context.go('/dashboard');
        }
      });
    }
  }

  void _signInWithGoogle(BuildContext context) {
    debugPrint('AuthSelection: Google Sign-In initiated');
    _resetNavigationFlag();
    ref.read(authProvider.notifier).signInWithGoogle();
  }
  
  void _resetNavigationFlag() {
    _hasNavigated = false;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    
    // Listen for auth state changes to trigger navigation
    ref.listen(authProvider, (previous, current) {
      if (previous?.user?.id != current.user?.id && current.user != null && !current.isLoading && !_hasNavigated) {
        debugPrint('AuthSelection: Auth state changed - triggering navigation for user: ${current.user?.email}, role: ${current.user?.role}');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _checkAndNavigate();
        });
      }
    });

    return Scaffold(
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                
                // Logo and Branding
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Image.asset(
                        'assets/logo.webp',
                        width: 100,
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      'Excellence Coaching Hub',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Theme.of(context).textTheme.headlineMedium?.color,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'Empowering learners through quality education',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
                            height: 1.5,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 60),
                  ],
                ),

                // Welcome Message
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.auto_graph_outlined,
                        color: AppTheme.primaryGreen,
                        size: 40,
                      ),
                      const SizedBox(height: 15),
                      Text(
                        'Welcome to Your Learning Journey',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppTheme.blackColor,
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Choose your preferred way to get started',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.greyColor,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Authentication Buttons
                Column(
                  children: [
                    // Continue with Google Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: authState.isLoading 
                            ? null 
                            : () => _signInWithGoogle(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: AppTheme.whiteColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 2,
                        ),
                        icon: authState.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.whiteColor),
                                ),
                              )
                            : const Icon(
                                Icons.account_circle_outlined,
                                color: AppTheme.whiteColor,
                                size: 24,
                              ),
                        label: Text(
                          authState.isLoading ? 'Signing in...' : 'Continue with Google',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Or divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: AppTheme.greyColor.withOpacity(0.5),
                            thickness: 1,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'or',
                            style: TextStyle(
                              color: AppTheme.greyColor,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: AppTheme.greyColor.withOpacity(0.5),
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Continue with Email Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: OutlinedButton.icon(
                        onPressed: authState.isLoading 
                            ? null 
                            : () => context.push('/email-auth-option'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: AppTheme.primaryGreen,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          backgroundColor: AppTheme.whiteColor,
                        ),
                        icon: const Icon(
                          Icons.email_outlined,
                          color: AppTheme.primaryGreen,
                          size: 24,
                        ),
                        label: const Text(
                          'Continue with Email',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Footer
                Column(
                  children: [
                    const Text(
                      'By continuing, you agree to our',
                      style: TextStyle(
                        color: AppTheme.greyColor,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            // TODO: Navigate to terms
                          },
                          child: const Text(
                            'Terms of Service',
                            style: TextStyle(
                              color: AppTheme.primaryGreen,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Text(
                          ' and ',
                          style: TextStyle(
                            color: AppTheme.greyColor,
                            fontSize: 13,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // TODO: Navigate to privacy
                          },
                          child: const Text(
                            'Privacy Policy',
                            style: TextStyle(
                              color: AppTheme.primaryGreen,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}