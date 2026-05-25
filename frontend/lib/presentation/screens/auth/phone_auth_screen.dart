import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';

class PhoneAuthScreen extends ConsumerStatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  _PhoneAuthScreenState createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends ConsumerState<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isCodeSent = false;
  int _resendTimer = 60;
  bool _canResend = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _resendTimer = 60;
      _canResend = false;
    });
    
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted && _resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
        return true;
      } else if (mounted) {
        setState(() {
          _canResend = true;
        });
        return false;
      }
      return false;
    });
  }

  void _sendOTP() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      String phoneNumber = _phoneController.text.trim();
      
      // Format phone number with country code if not present
      if (!phoneNumber.startsWith('+')) {
        phoneNumber = '+$phoneNumber';
      }
      
      ref.read(authProvider.notifier).sendPhoneOTP(phoneNumber);
    }
  }

  void _verifyOTP() {
    FocusScope.of(context).unfocus();
    if (_otpController.text.length == 6) {
      ref.read(authProvider.notifier).verifyPhoneOTP(_otpController.text.trim());
    }
  }

  void _resendOTP() {
    if (_canResend) {
      _sendOTP();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    // Listen for code sent state
    ref.listen(authProvider, (previous, current) {
      if (current.isCodeSent && !_isCodeSent) {
        setState(() {
          _isCodeSent = true;
        });
        _startResendTimer();
      }
      
      // Navigate on successful login
      if (current.user != null && !current.isLoading && current.error?.contains('successful') == true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            if (current.user?.role == 'admin') {
              context.go('/admin');
            } else if (current.user?.hasCompletedOnboarding ?? false) {
              context.go('/dashboard');
            } else {
              context.go('/interest-selection');
            }
          }
        });
      }
    });

    if (isDesktop) {
      return _buildDesktopLayout(authState);
    }
    return _buildMobileLayout(authState);
  }

  Widget _buildDesktopLayout(dynamic authState) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F172A),
                  Color(0xFF1E293B),
                  Color(0xFF0F4C75),
                  Color(0xFF041B2D),
                ],
                stops: [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00C896).withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFBF00).withOpacity(0.05),
              ),
            ),
          ),
          SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: _buildLeftPanel(),
                ),
                Expanded(
                  child: _buildRightPanel(authState),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF00C896).withOpacity(0.15),
            const Color(0xFF0A4A5A).withOpacity(0.1),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF00C896), Color(0xFF009E76)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00C896).withOpacity(0.3),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: ClipOval(
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Image.asset(
                  'assets/logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(height: 60),
          const Text(
            'Phone Sign In',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF00C896),
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Quick & Secure Access',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w900,
              height: 1.2,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 50,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF00C896),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            'Sign in with your phone number for a fast and secure experience. No password required.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel(dynamic authState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 40),
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Phone Authentication',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _isCodeSent ? 'Enter the verification code' : 'Enter your phone number',
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_isCodeSent) _buildPhoneField(),
                if (_isCodeSent) _buildOTPField(),
                const SizedBox(height: 24),
                if (!_isCodeSent) _buildSendOTPButton(authState),
                if (_isCodeSent) _buildVerifyOTPButton(authState),
                const SizedBox(height: 20),
                if (authState.error != null && authState.error!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            authState.error!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                if (_isCodeSent) _buildResendSection(),
                const SizedBox(height: 24),
                _buildAlternativeOptions(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(dynamic authState) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F172A),
                  Color(0xFF1E293B),
                  Color(0xFF0F4C75),
                ],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00C896), Color(0xFF009E76)],
                      ),
                    ),
                    child: ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Phone Authentication',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isCodeSent ? 'Enter the verification code' : 'Enter your phone number',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!_isCodeSent) _buildPhoneField(),
                        if (_isCodeSent) _buildOTPField(),
                        const SizedBox(height: 20),
                        if (!_isCodeSent) _buildSendOTPButton(authState),
                        if (_isCodeSent) _buildVerifyOTPButton(authState),
                        const SizedBox(height: 16),
                        if (authState.error != null && authState.error!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    authState.error!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 20),
                        if (_isCodeSent) _buildResendSection(),
                        const SizedBox(height: 20),
                        _buildAlternativeOptions(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        hintText: 'Enter phone number (e.g., +1234567890)',
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        prefixIcon: const Icon(Icons.phone_outlined, color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF00C896), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _sendOTP(),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your phone number';
        }
        // Basic phone validation
        final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
        if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[\s-]'), ''))) {
          return 'Please enter a valid phone number';
        }
        return null;
      },
    );
  }

  Widget _buildOTPField() {
    return TextFormField(
      controller: _otpController,
      style: const TextStyle(color: Colors.white, fontSize: 15, letterSpacing: 8),
      keyboardType: TextInputType.number,
      maxLength: 6,
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        hintText: '123456',
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5), letterSpacing: 4),
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF00C896), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        counterText: '',
      ),
      textInputAction: TextInputAction.done,
      onChanged: (value) {
        if (value.length == 6) {
          _verifyOTP();
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter the verification code';
        }
        if (value.length != 6) {
          return 'Please enter a 6-digit code';
        }
        return null;
      },
    );
  }

  Widget _buildSendOTPButton(dynamic authState) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00C896), Color(0xFF009E76)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00C896).withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: InkWell(
          onTap: authState.isPhoneLoading ? null : _sendOTP,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: authState.isPhoneLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Text(
                    'Send Verification Code',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerifyOTPButton(dynamic authState) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00C896), Color(0xFF009E76)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00C896).withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: InkWell(
          onTap: authState.isPhoneLoading ? null : _verifyOTP,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: authState.isPhoneLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Text(
                    'Verify Code',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildResendSection() {
    return Column(
      children: [
        if (!_canResend)
          Text(
            'Resend code in $_resendTimer seconds',
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 14,
            ),
          )
        else
          TextButton(
            onPressed: _resendOTP,
            child: const Text(
              'Resend Code',
              style: TextStyle(
                color: Color(0xFF00C896),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            setState(() {
              _isCodeSent = false;
              _otpController.clear();
            });
            ref.read(authProvider.notifier).resetPhoneAuth();
          },
          child: const Text(
            'Change phone number',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlternativeOptions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Divider(
                color: Colors.white.withOpacity(0.2),
                thickness: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Or continue with',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: Colors.white.withOpacity(0.2),
                thickness: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildGoogleButton(),
        const SizedBox(height: 12),
        _buildEmailButton(),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => ref.read(authProvider.notifier).signInWithGoogle(),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.g_mobiledata,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Continue with Google',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/login'),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.email_outlined,
                color: Colors.white70,
                size: 20,
              ),
              SizedBox(width: 12),
              Text(
                'Continue with Email',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
