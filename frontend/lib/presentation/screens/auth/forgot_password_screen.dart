import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/presentation/widgets/beautiful_widgets.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'dart:async';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _showResendButton = false;
  int _resendCountdown = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    _emailController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      try {
        await ref.read(authProvider.notifier).sendPasswordResetEmail(_emailController.text.trim());
      } catch (_) {
        // Error handled by provider state; continue to show messages
      }
      if (!mounted) return;
      // Start resend countdown
      _startResendCountdown();
    }
  }

  void _startResendCountdown() {
    setState(() {
      _showResendButton = false;
      _resendCountdown = 60; // 60 seconds
    });
    
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _resendCountdown--;
      });
      
      if (_resendCountdown <= 0) {
        timer.cancel();
        setState(() {
          _showResendButton = true;
        });
      }
    });
  }

  Future<void> _resendEmail() async {
    if (_formKey.currentState!.validate()) {
      try {
        await ref.read(authProvider.notifier).sendPasswordResetEmail(_emailController.text.trim());
      } catch (_) {
        // Error handled by provider state
      }
      if (!mounted) return;
      _startResendCountdown();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    
    return Scaffold(
      body: GradientBackground(
        colors: AppTheme.oceanGradient,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 50),
                  
                  // Header with icon and title
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
                          Icons.lock_reset_outlined,
                          size: 65,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 25),
                      Text(
                        'Forgot Password?',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Enter your email and we\'ll send you a reset code to reset your password',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white70,
                              height: 1.5,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 45),
                    ],
                  ),

                  // Reset Form Card
                  GlassContainer(
                    child: Padding(
                      padding: const EdgeInsets.all(28.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Email Field
                          CustomTextField(
                            controller: _emailController,
                            labelText: 'Email Address',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 25),

                          // Reset Button
                          AnimatedButton(
                            text: authState.error != null && authState.error!.contains('sent') 
                                ? 'Resend Code' 
                                : 'Send Reset Code',
                            onPressed: authState.isLoading || (!_showResendButton && authState.error != null && authState.error!.contains('sent')) 
                                ? () {} 
                                : (authState.error != null && authState.error!.contains('sent') ? _resendEmail : _resetPassword),
                            isLoading: authState.isLoading,
                            color: const Color(0xFF4facfe),
                          ),

                          const SizedBox(height: 25),

                          // Success or Error message
                          if (authState.error != null)
                            Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(top: 15),
                              decoration: BoxDecoration(
                                color: authState.error!.contains('sent')
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.redAccent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: authState.error!.contains('sent')
                                      ? Colors.green.withOpacity(0.5)
                                      : Colors.redAccent.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      if (authState.error!.contains('sent'))
                                        const Icon(
                                          Icons.check_circle_outline,
                                          color: Colors.green,
                                          size: 24,
                                        ),
                                      if (authState.error!.contains('sent'))
                                        const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          authState.error!,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Show countdown timer when email is sent
                                  if (authState.error!.contains('sent') && !_showResendButton && _resendCountdown > 0)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: Text(
                                        'Resend available in $_resendCountdown seconds',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                ],
                              ),
                            ),

                          // Show a button to navigate to enter reset code screen after success
                          if (authState.error != null && (authState.error!.contains('sent') || authState.error!.contains('Successfully')))
                            Column(
                              children: [
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: () {
                                      debugPrint('Navigating to enter reset code screen');
                                      context.push('/enter-reset-code');
                                    },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4facfe),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: const Text(
                                    'Enter Reset Code',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Didn\'t receive the email? Check your spam folder',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white70,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                // Debug information
                                if (kDebugMode) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.black26,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Debug: Error message = "${authState.error}"',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),

                          const SizedBox(height: 30),

                          // Back to login
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Remember your password? ",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  context.go('/login');
                                },
                                child: const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
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
      ),
    );
  }
}
