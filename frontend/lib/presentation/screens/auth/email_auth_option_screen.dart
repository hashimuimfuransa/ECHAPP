import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:excellence_coaching_hub/presentation/widgets/beautiful_widgets.dart';
import 'package:excellence_coaching_hub/config/app_theme.dart';

class EmailAuthOptionScreen extends StatelessWidget {
  const EmailAuthOptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                        
                        const SizedBox(height: 30),
                        
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