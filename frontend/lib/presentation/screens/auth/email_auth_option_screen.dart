import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:excellence_coaching_hub/presentation/widgets/beautiful_widgets.dart';
import 'package:excellence_coaching_hub/config/app_theme.dart';
import 'package:excellence_coaching_hub/utils/responsive_utils.dart';

class EmailAuthOptionScreen extends StatelessWidget {
  const EmailAuthOptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final padding = ResponsiveBreakpoints.getPadding(context);
    final spacing = ResponsiveBreakpoints.getSpacing(context, base: 24);

    if (isDesktop) {
      return Scaffold(
        body: GradientBackground(
          colors: AppTheme.oceanGradient,
          child: SafeArea(
            child: Row(
              children: [
                // Left side - Branding area
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF4facfe),
                          Color(0xFF00f2fe),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(40),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(35),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.mail_outline,
                              size: 80,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 40),
                          const Text(
                            'Email Authentication',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Choose how you want to\nuse your email',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 20,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
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
                                    _EmailFeatureItem(
                                      icon: Icons.login,
                                      label: 'Sign In',
                                      description: 'Existing users',
                                    ),
                                    _EmailFeatureItem(
                                      icon: Icons.app_registration,
                                      label: 'Register',
                                      description: 'New users',
                                    ),
                                  ],
                                ),
                                SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _EmailFeatureItem(
                                      icon: Icons.lock_reset,
                                      label: 'Reset Password',
                                      description: 'Forgot password',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Right side - Options
                Expanded(
                  flex: 1,
                  child: SingleChildScrollView(
                    padding: padding,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: spacing),
                        
                        // Header with back button
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => context.pop(),
                              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                            ),
                            const Spacer(),
                          ],
                        ),
                        
                        SizedBox(height: spacing * 0.5),
                        
                        // Options Card
                        GlassContainer(
                          child: Padding(
                            padding: EdgeInsets.all(spacing),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Login Option
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(15),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF4CAF50),
                                        borderRadius: BorderRadius.all(Radius.circular(15)),
                                      ),
                                      child: const Icon(
                                        Icons.login,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                    title: const Text(
                                      'Sign In',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: const Text(
                                      'Already have an account? Sign in with your email and password.',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 15,
                                        height: 1.4,
                                      ),
                                    ),
                                    trailing: const Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.white,
                                    ),
                                    onTap: () => context.push('/login'),
                                  ),
                                ),
                                
                                SizedBox(height: spacing * 0.8),
                                
                                // Register Option
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(15),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF2196F3),
                                        borderRadius: BorderRadius.all(Radius.circular(15)),
                                      ),
                                      child: const Icon(
                                        Icons.app_registration,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                    title: const Text(
                                      'Create Account',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: const Text(
                                      'New to Excellence Coaching Hub? Create a new account.',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 15,
                                        height: 1.4,
                                      ),
                                    ),
                                    trailing: const Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.white,
                                    ),
                                    onTap: () => context.push('/register'),
                                  ),
                                ),
                                
                                SizedBox(height: spacing * 0.8),
                                
                                // Forgot Password Option
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(15),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFF9800),
                                        borderRadius: BorderRadius.all(Radius.circular(15)),
                                      ),
                                      child: const Icon(
                                        Icons.lock_reset,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                    title: const Text(
                                      'Forgot Password',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: const Text(
                                      'Reset your password if you forgot it.',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 15,
                                        height: 1.4,
                                      ),
                                    ),
                                    trailing: const Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.white,
                                    ),
                                    onTap: () => context.push('/forgot-password'),
                                  ),
                                ),
                                
                                SizedBox(height: spacing),
                                
                                // Additional info
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Column(
                                    children: [
                                      Icon(
                                        Icons.security,
                                        color: Colors.white70,
                                        size: 24,
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        'Secure Authentication',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Your credentials are securely encrypted and protected. We never share your personal information with third parties.',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                          height: 1.4,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        SizedBox(height: spacing),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // Mobile layout (existing code)
      return Scaffold(
        body: GradientBackground(
          colors: AppTheme.oceanGradient,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 50),
                  
                  // Header with back button
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const Spacer(),
                    ],
                  ),
                  
                  // Email Option Selection
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.mail_outline,
                          size: 65,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 25),
                      Text(
                        'Email Authentication',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Choose how you want to use your email',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white70,
                              height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 45),
                    ],
                  ),

                  // Options Card
                  GlassContainer(
                    child: Padding(
                      padding: const EdgeInsets.all(28.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Login Option
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF4CAF50),
                                  borderRadius: BorderRadius.all(Radius.circular(12)),
                                ),
                                child: const Icon(
                                  Icons.login,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              title: const Text(
                                'Sign In',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              subtitle: const Text(
                                'Already have an account? Sign in with your email and password',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white70,
                              ),
                              onTap: () {
                                context.push('/login');
                              },
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Register Option
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2196F3),
                                  borderRadius: BorderRadius.all(Radius.circular(12)),
                                ),
                                child: const Icon(
                                  Icons.person_add,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              title: const Text(
                                'Create Account',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              subtitle: const Text(
                                'New to Excellence Coaching Hub? Create a new account',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white70,
                              ),
                              onTap: () {
                                context.push('/register');
                              },
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Forgot Password Option
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF9800),
                                  borderRadius: BorderRadius.all(Radius.circular(12)),
                                ),
                                child: const Icon(
                                  Icons.lock_reset,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              title: const Text(
                                'Forgot Password',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              subtitle: const Text(
                                'Reset your password if you forgot it',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white70,
                              ),
                              onTap: () {
                                context.push('/forgot-password');
                              },
                            ),
                          ),
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
      );
    }
  }
}

// Helper widget for email feature items (desktop only)
class _EmailFeatureItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  
  const _EmailFeatureItem({
    required this.icon,
    required this.label,
    required this.description,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            icon,
            size: 32,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}