import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';
import 'package:excellencecoachinghub/l10n/app_localizations.dart';
import 'package:excellencecoachinghub/presentation/widgets/desktop_brand_panel.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _hasNavigated = false;
  bool _listenerRegistered = false;
  late AnimationController _animController;

  // Theme-aware getters
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _backgroundColor => _isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB);
  Color get _cardColor => _isDark ? const Color(0xFF1E293B) : Colors.white;
  Color get _textColor => _isDark ? Colors.white : const Color(0xFF1F2937);
  Color get _secondaryTextColor => _isDark ? Colors.white70 : const Color(0xFF6B7280);
  Color get _inputBorderColor => _isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
  Color get _inputFillColor => _isDark ? const Color(0xFF0F172A) : Colors.white;
  Color get _inputTextColor => _isDark ? Colors.white : const Color(0xFF1A2433);
  Color get _inputHintColor => _isDark ? const Color(0xFF94A3B8) : const Color(0xFF8899AA);
  Color get _iconColor => _isDark ? const Color(0xFF94A3B8) : const Color(0xFF8899AA);
  Color get _errorBgColor => _isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2);
  Color get _errorBorderColor => _isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA);
  Color get _errorTextColor => _isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C);
  Color get _warningBgColor => _isDark ? const Color(0xFF451A03) : const Color(0xFFFFFBEB);
  Color get _warningBorderColor => _isDark ? const Color(0xFF92400E) : const Color(0xFFFEF3C7);
  Color get _warningTextColor => _isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB45309);
  Color get _linkColor => const Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_listenerRegistered) {
      _listenerRegistered = true;
      ref.listenManual(authProvider, (previous, current) {
        if (mounted && current.user != null && !current.isLoading && !_hasNavigated) {
          _hasNavigated = true;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Welcome back, ${current.user!.fullName}!'),
                  backgroundColor: const Color(0xFF00C896),
                  duration: const Duration(seconds: 2),
                ),
              );
              if (current.user!.role == 'admin') {
                context.go('/admin');
              } else {
                final userHasCompletedOnboarding = current.user!.hasCompletedOnboarding ?? false;
                if (userHasCompletedOnboarding) {
                  context.go('/dashboard');
                } else {
                  context.go('/interest-selection');
                }
              }
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    _hasNavigated = false;
    super.dispose();
  }

  void _login() async {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      // Check connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      final isConnected = connectivityResult != ConnectivityResult.none;
      
      if (!isConnected) {
        // Try offline login
        ref.read(authProvider.notifier).loginOffline();
      } else {
        // Online login
        ref.read(authProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final l10n = AppLocalizations.of(context);
    
    // Guard against missing localizations
    if (l10n == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (isDesktop) {
      return _buildDesktopLayout(authState, l10n);
    }
    return _buildMobileLayout(authState, l10n);
  }

  Widget _buildDesktopLayout(dynamic authState, AppLocalizations l10n) {
    // Fallback strings
    final String welcomeText = l10n.loginTitle;
    final String subtitleText = l10n.loginSubtitle;
    final String forgotPasswordText = l10n.forgotPassword;
    final String noAccountText = l10n.dontHaveAccount;
    final String signUpText = l10n.registerNow;
    final String emailHint = l10n.email;
    final String passwordHint = l10n.password;
    final String loginText = l10n.loginTitle;

    return Scaffold(
      body: Row(
        children: [
          // Left branding panel (45%)
          const Expanded(
            flex: 45,
            child: DesktopBrandPanel(
              headline: 'Welcome to',
              title: 'Excellence\nCoaching Hub',
              tagline: 'Empowering Growth.\nInspiring Excellence.',
            ),
          ),
          // Right white form panel (55%)
          Expanded(
            flex: 55,
            child: Container(
              color: Colors.white,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 60),
                    child: _buildRightPanel(authState, l10n, welcomeText, subtitleText, forgotPasswordText, noAccountText, signUpText, emailHint, passwordHint, loginText),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel(dynamic authState, AppLocalizations l10n, String welcomeText, String subtitleText, String forgotPasswordText, String noAccountText, String signUpText, String emailHint, String passwordHint, String loginText) {
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
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                welcomeText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                subtitleText,
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
                    _buildEmailField(emailHint),
                    const SizedBox(height: 24),
                    _buildPasswordField(passwordHint),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push('/forgot-password'),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        child: Text(
                          forgotPasswordText,
                          style: const TextStyle(
                            color: Color(0xFF00C896),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildSignInButton(authState, loginText),
                    const SizedBox(height: 20),
                    if (authState.error != null && authState.error!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: authState.error!.contains('Forgot password?') 
                              ? Colors.orange.withOpacity(0.1) 
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: authState.error!.contains('Forgot password?')
                                ? Colors.orange.withOpacity(0.3)
                                : Colors.red.withOpacity(0.3)
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              authState.error!.contains('Forgot password?') 
                                  ? Icons.info_outline_rounded 
                                  : Icons.error_outline, 
                              color: authState.error!.contains('Forgot password?')
                                  ? Colors.orange.shade400
                                  : Colors.red.shade400, 
                              size: 20
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                authState.error,
                                style: TextStyle(
                                  color: authState.error!.contains('Forgot password?')
                                      ? Colors.orange.shade200
                                      : Colors.red.shade400,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          noAccountText,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/register'),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero),
                          child: Text(
                            signUpText,
                            style: const TextStyle(
                              color: Color(0xFF00C896),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                          ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(dynamic authState, AppLocalizations l10n) {
    final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final isShort = screenHeight < 700;

    // Fallback strings
    final String welcomeText = l10n.loginTitle;
    final String subtitleText = l10n.loginSubtitle;
    final String forgotPasswordText = l10n.forgotPassword;
    final String noAccountText = l10n.dontHaveAccount;
    final String signUpText = l10n.registerNow;
    final String emailHint = l10n.email;
    final String passwordHint = l10n.password;
    final String loginText = l10n.loginTitle;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Back button at top left
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: Icon(Icons.arrow_back_ios_rounded, 
                        color: _textColor, size: 20),
                  ),
                  const Spacer(),
                ],
              ),
            ),

            // Compact header section
            Padding(
              padding: EdgeInsets.symmetric(vertical: isShort ? 6 : 12),
              child: Column(
                children: [
                  // Small logo
                  Container(
                    width: 70, height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isDark ? const Color(0xFF10B981).withOpacity(0.2) : const Color(0xFFECFDF5),
                      border: Border.all(color: const Color(0xFF10B981).withOpacity(_isDark ? 0.5 : 0.3), width: 2),
                    ),
                    child: ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    welcomeText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitleText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _secondaryTextColor,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // Main card
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: _isDark ? [] : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    isSmallMobile ? 20 : 24,
                    isSmallMobile ? 20 : 24,
                    isSmallMobile ? 20 : 24,
                    isSmallMobile ? 20 : 24,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildEmailField(emailHint),
                        const SizedBox(height: 16),
                        _buildPasswordField(passwordHint),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.push('/forgot-password'),
                            style: TextButton.styleFrom(padding: EdgeInsets.zero),
                            child: Text(
                              forgotPasswordText,
                              style: TextStyle(
                                color: _linkColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildSignInButton(authState, loginText),
                        const SizedBox(height: 16),
                        if (authState.error != null && authState.error!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: authState.error!.contains('Forgot password?') 
                                  ? _warningBgColor
                                  : _errorBgColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: authState.error!.contains('Forgot password?')
                                    ? _warningBorderColor
                                    : _errorBorderColor,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  authState.error!.contains('Forgot password?') 
                                      ? Icons.info_outline_rounded 
                                      : Icons.error_outline, 
                                  color: authState.error!.contains('Forgot password?')
                                      ? const Color(0xFFF59E0B)
                                      : const Color(0xFFEF4444), 
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    authState.error!,
                                    style: TextStyle(
                                      color: authState.error!.contains('Forgot password?')
                                          ? _warningTextColor
                                          : _errorTextColor,
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 20),
                        _buildSecurityBadge(l10n),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              noAccountText,
                              style: TextStyle(
                                color: _secondaryTextColor,
                                fontSize: 13,
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.push('/register'),
                              style: TextButton.styleFrom(padding: EdgeInsets.zero),
                              child: Text(
                                signUpText,
                                style: TextStyle(
                                  color: _linkColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityBadge(AppLocalizations l10n) {
    final String secureText = l10n.secureProtected;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF10B981).withOpacity(0.15) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _isDark ? const Color(0xFF10B981).withOpacity(0.3) : const Color(0xFFBBF7D0), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: _isDark ? const Color(0xFF10B981).withOpacity(0.2) : const Color(0xFFD1FAE5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.verified_user, color: Color(0xFF059669), size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              secureText,
              style: TextStyle(
                  color: _textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.3),
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
        ],
      ),
    );
  }

  Widget _buildEmailField(String hintText) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: _inputFillColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _inputBorderColor,
          width: 1.5,
        ),
        boxShadow: _isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: _emailController,
        style: TextStyle(color: _inputTextColor, fontSize: 15),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: _inputHintColor),
          prefixIcon: Icon(Icons.email_outlined, color: _iconColor),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        textInputAction: TextInputAction.next,
        keyboardType: TextInputType.emailAddress,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your email';
          }
          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
            return 'Please enter a valid email';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPasswordField(String hintText) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: _inputFillColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _inputBorderColor,
          width: 1.5,
        ),
        boxShadow: _isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: _passwordController,
        style: TextStyle(color: _inputTextColor, fontSize: 15),
        obscureText: _obscurePassword,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: _inputHintColor),
          prefixIcon: Icon(Icons.lock_outline_rounded, color: _iconColor),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: _iconColor,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => _login(),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your password';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSignInButton(dynamic authState, String buttonText) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF00C896),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C896).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: authState.isLoading ? null : _login,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: authState.isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white.withOpacity(0.9)),
                    ),
                  )
                : Text(
                    buttonText,
                    style: const TextStyle(
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

  Widget _buildSocialLoginDivider() {
    return Row(
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
            'or continue with',
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
    );
  }

  Widget _buildSocialLoginButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSocialButton(
          icon: 'assets/google_logo.png',
          label: 'Google',
          onTap: () {
            // TODO: Implement Google sign-in
          },
        ),
        const SizedBox(width: 16),
        _buildSocialButton(
          icon: 'assets/apple_logo.png',
          label: 'Apple',
          onTap: () {
            // TODO: Implement Apple sign-in
          },
        ),
        const SizedBox(width: 16),
        _buildSocialButton(
          icon: 'assets/facebook_logo.png',
          label: 'Facebook',
          onTap: () {
            // TODO: Implement Facebook sign-in
          },
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Placeholder for social media icons
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                _getIconForLabel(label),
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForLabel(String label) {
    switch (label.toLowerCase()) {
      case 'google':
        return Icons.g_mobiledata;
      case 'apple':
        return Icons.apple;
      case 'facebook':
        return Icons.facebook;
      default:
        return Icons.person;
    }
  }

  Widget _buildPhoneAuthButton() {
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
          onTap: () => context.push('/phone-auth'),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.phone_outlined,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 12),
                Text(
                  'Continue with Phone',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleAuthButton(dynamic authState) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: authState.isGoogleLoading 
            ? null 
            : () => ref.read(authProvider.notifier).signInWithGoogle(),
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
              if (authState.isGoogleLoading)
                const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              else
                const Icon(
                  Icons.g_mobiledata,
                  color: Colors.white,
                  size: 20,
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
}
