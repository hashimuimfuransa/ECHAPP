import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';

class AuthSelectionScreen extends ConsumerStatefulWidget {
  const AuthSelectionScreen({super.key});

  @override
  _AuthSelectionScreenState createState() => _AuthSelectionScreenState();
}

// Feature item widget
class _FeatureItem extends StatelessWidget {
  final String icon;
  final String text;
  
  const _FeatureItem({required this.icon, required this.text});
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          icon,
          style: const TextStyle(fontSize: 20),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// Device binding policy widget
class _DeviceBindingPolicy extends StatelessWidget {
  const _DeviceBindingPolicy();
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0), // Light orange background for warning
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFFFB74D), // Orange border
          width: 1,
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.security,
            color: Color(0xFFF57C00), // Orange icon
            size: 16,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Account binds to first device - contact support to change devices',
              style: TextStyle(
                color: Color(0xFF333333), // Dark text for visibility
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// Terms text widget with clickable links
class _TermsText extends StatelessWidget {
  const _TermsText();
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Show dialog with both options
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Legal Documents'),
              content: const Text(
                'What would you like to view?',
                style: TextStyle(fontSize: 16),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/privacy');
                  },
                  child: const Text('Privacy Policy'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/terms');
                  },
                  child: const Text('Terms of Service'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
      child: const Text.rich(
        TextSpan(
          style: TextStyle(
            color: Color(0xFF6B7280), // More visible dark gray instead of light gray
            fontSize: 14,
            height: 1.5,
          ),
          children: [
            TextSpan(text: 'By continuing, you agree to our '),
            TextSpan(
              text: 'Terms of Service',
              style: TextStyle(
                color: Color(0xFF10B981), // Brand green for emphasis
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
            TextSpan(text: ' and ' ),
            TextSpan(
              text: 'Privacy Policy',
              style: TextStyle(
                color: Color(0xFF10B981), // Brand green for emphasis
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// Auth button widget
class _AuthButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;
  final Color? borderColor;
  final bool isLoading;
  final VoidCallback? onPressed;
  
  const _AuthButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.textColor,
    this.borderColor,
    this.isLoading = false,
    this.onPressed,
  });
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          side: borderColor != null 
              ? BorderSide(color: borderColor!, width: 2)
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: color == Colors.white ? 0 : 2,
        ),
        icon: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              )
            : Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
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
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final padding = ResponsiveBreakpoints.getPadding(context);
    final spacing = ResponsiveBreakpoints.getSpacing(context, base: 24);
    
    // Listen for auth state changes to trigger navigation
    ref.listen(authProvider, (previous, current) {
      if (previous?.user?.id != current.user?.id && current.user != null && !current.isLoading && !_hasNavigated) {
        debugPrint('AuthSelection: Auth state changed - triggering navigation for user: ${current.user?.email}, role: ${current.user?.role}');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _checkAndNavigate();
        });
      }
    });

    if (isDesktop) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF10B981),
                const Color(0xFF047857),
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1200),
                margin: const EdgeInsets.all(24),
                child: Card(
                  elevation: 20,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      // Left side - Branding
                      Expanded(
                        flex: 2,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF059669),
                                Color(0xFF047857),
                              ],
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(24),
                              bottomLeft: Radius.circular(24),
                            ),
                          ),
                          padding: const EdgeInsets.all(48),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Logo
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    'assets/logo.webp',
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.school,
                                        size: 60,
                                        color: Colors.white,
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              
                              // App Name
                              const Text(
                                'Excellence Coaching Hub',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Tagline
                              const Text(
                                'Transform your learning journey with world-class education',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 32),
                              
                              // Feature highlights
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _FeatureItem(
                                    icon: '📚',
                                    text: '1000+ Courses',
                                  ),
                                  const SizedBox(height: 12),
                                  const _FeatureItem(
                                    icon: '🎓',
                                    text: 'Expert Instructors',
                                  ),
                                  const SizedBox(height: 12),
                                  const _FeatureItem(
                                    icon: '🏆',
                                    text: 'Certified Learning',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Right side - Auth Options
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(48),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Welcome header
                              const Text(
                                'Welcome Back',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1f2937),
                                  height: 1.2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Sign in to continue your learning journey',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xFF6b7280),
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 48),
                              
                              // Google Sign In
                              _AuthButton(
                                icon: Icons.account_circle_outlined,
                                label: authState.isLoading ? 'Signing in...' : 'Continue with Google',
                                color: const Color(0xFF6366F1), // Vibrant indigo for better attention
                                textColor: Colors.white,
                                isLoading: authState.isLoading,
                                onPressed: authState.isLoading 
                                    ? null 
                                    : () => _signInWithGoogle(context),
                              ),
                              
                              const SizedBox(height: 20),
                              
                              // Divider
                              const Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: Color(0xFFe5e7eb),
                                      thickness: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      'or',
                                      style: TextStyle(
                                        color: Color(0xFF9ca3af),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: Color(0xFFe5e7eb),
                                      thickness: 1,
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 20),
                              
                              // Email Sign In
                              _AuthButton(
                                icon: Icons.email_outlined,
                                label: 'Continue with Email',
                                color: const Color(0xFFF97316), // Vibrant orange for attention
                                textColor: Colors.white,
                                onPressed: () => context.push('/email-auth-option'),
                              ),
                              
                              const SizedBox(height: 48),
                              
                              // Terms with clickable links
                              const _TermsText(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      // Mobile layout - Modern design
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF10B981),
                Color(0xFF047857),
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    
                    // Logo and Branding
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/logo.webp',
                          width: 100,
                          height: 100,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.school,
                              size: 60,
                              color: Colors.white,
                            );
                          },
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    const Text(
                      'Excellence Coaching Hub',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    const Text(
                      'Transform your learning journey with world-class education',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Welcome Card
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            const Text(
                              'Welcome Back',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1f2937),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            const SizedBox(height: 12),
                            
                            const Text(
                              'Sign in to continue your learning journey',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF6b7280),
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Google Sign In
                            _AuthButton(
                              icon: Icons.account_circle_outlined,
                              label: authState.isLoading ? 'Signing in...' : 'Continue with Google',
                              color: const Color(0xFF6366F1), // Vibrant indigo for better attention
                              textColor: Colors.white,
                              isLoading: authState.isLoading,
                              onPressed: authState.isLoading 
                                  ? null 
                                  : () => _signInWithGoogle(context),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Divider
                            const Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: Color(0xFFe5e7eb),
                                    thickness: 1,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'or',
                                    style: TextStyle(
                                      color: Color(0xFF9ca3af),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: Color(0xFFe5e7eb),
                                    thickness: 1,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Email Sign In
                            _AuthButton(
                              icon: Icons.email_outlined,
                              label: 'Continue with Email',
                              color: const Color(0xFFF97316), // Vibrant orange for attention
                              textColor: Colors.white,
                              onPressed: () => context.push('/email-auth-option'),
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Device binding policy
                            const _DeviceBindingPolicy(),
                            
                            const SizedBox(height: 20),
                            
                            // Terms with clickable links
                            const _TermsText(),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
  }
}
