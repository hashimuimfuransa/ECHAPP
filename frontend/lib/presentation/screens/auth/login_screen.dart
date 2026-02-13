import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellence_coaching_hub/presentation/providers/auth_provider.dart';
import 'package:excellence_coaching_hub/config/app_theme.dart';
import 'package:excellence_coaching_hub/utils/responsive_utils.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _hasNavigated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAndNavigate();
  }

  @override
  void didUpdateWidget(covariant LoginScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkAndNavigate();
  }

  void _checkAndNavigate() {
    if (!_hasNavigated) {
      final authState = ref.watch(authProvider);
      debugPrint('LoginScreen: Checking navigation - User: ${authState.user != null}, Loading: ${authState.isLoading}, Error: ${authState.error}');
      if (authState.user != null && !authState.isLoading) {
        _hasNavigated = true;
        debugPrint('LoginScreen: Navigating to dashboard for role: ${authState.user?.role}');
        // Navigate to appropriate dashboard based on user role
        if (authState.user?.role == 'admin') {
          debugPrint('LoginScreen: Navigating to admin dashboard');
          context.go('/admin');
        } else {
          debugPrint('LoginScreen: Navigating to student dashboard');
          context.go('/dashboard');
        }
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      ref.read(authProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final padding = ResponsiveBreakpoints.getPadding(context);
    final spacing = ResponsiveBreakpoints.getSpacing(context, base: 24);

    if (isDesktop) {
      return Scaffold(
        body: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: SafeArea(
            child: Row(
              children: [
                // Left side - Branding/Image area
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.primaryGreen,
                          Color(0xFF047857),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(30),
                            decoration: BoxDecoration(
                              color: AppTheme.whiteColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Image.asset(
                              'assets/logo.webp',
                              width: 100,
                              height: 100,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 30),
                          const Text(
                            'Excellence\nCoaching Hub',
                            style: TextStyle(
                              color: AppTheme.whiteColor,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Transform your learning journey\nwith our comprehensive platform',
                            style: TextStyle(
                              color: AppTheme.whiteColor,
                              fontSize: 18,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Right side - Login form
                Expanded(
                  flex: 1,
                  child: SingleChildScrollView(
                    padding: padding,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: spacing),
                          
                          // Welcome text
                          Text(
                            'Welcome Back!',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: AppTheme.getTextColor(context),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 32,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 15),
                          Text(
                            'Sign in to continue your learning journey',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: AppTheme.getSecondaryTextColor(context),
                                  fontSize: 18,
                                  height: 1.4,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: spacing * 1.5),

                          // Login Form Card
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardTheme.color,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).shadowColor.withOpacity(0.15),
                                  blurRadius: 25,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                              border: Border.all(
                                color: Theme.of(context).dividerColor.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(spacing),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Email Field
                                  TextFormField(
                                    controller: _emailController,
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
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: AppTheme.getTextColor(context),
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Email Address',
                                      labelStyle: TextStyle(
                                        color: AppTheme.getSecondaryTextColor(context),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.email_outlined, 
                                        color: AppTheme.getSecondaryTextColor(context),
                                        size: 24,
                                      ),
                                      filled: true,
                                      fillColor: AppTheme.lightGreen.withOpacity(0.1),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(18),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(18),
                                        borderSide: BorderSide(
                                          color: AppTheme.greyColor.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(18),
                                        borderSide: const BorderSide(
                                          color: AppTheme.primaryGreen,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: spacing * 0.8),

                                  // Password Field
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your password';
                                      }
                                      if (value.length < 6) {
                                        return 'Password must be at least 6 characters';
                                      }
                                      return null;
                                    },
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: AppTheme.getTextColor(context),
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      labelStyle: TextStyle(
                                        color: AppTheme.getSecondaryTextColor(context),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.lock_outline, 
                                        color: AppTheme.getSecondaryTextColor(context),
                                        size: 24,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                          color: AppTheme.getSecondaryTextColor(context),
                                          size: 24,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword = !_obscurePassword;
                                          });
                                        },
                                      ),
                                      filled: true,
                                      fillColor: AppTheme.lightGreen.withOpacity(0.1),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(18),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(18),
                                        borderSide: BorderSide(
                                          color: AppTheme.greyColor.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(18),
                                        borderSide: const BorderSide(
                                          color: AppTheme.primaryGreen,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: spacing),

                                  // Login Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 55,
                                    child: ElevatedButton(
                                      onPressed: authState.isLoading ? null : _login,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryGreen,
                                        foregroundColor: AppTheme.whiteColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                        elevation: 3,
                                      ),
                                      child: authState.isLoading
                                          ? const SizedBox(
                                              width: 28,
                                              height: 28,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 3,
                                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.whiteColor),
                                              ),
                                            )
                                          : const Text(
                                              'Sign In',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                  ),

                                  SizedBox(height: spacing * 0.8),

                                  // Success or Error message
                                  if (authState.error != null)
                                    Container(
                                      padding: const EdgeInsets.all(18),
                                      margin: const EdgeInsets.only(bottom: 20),
                                      decoration: BoxDecoration(
                                        color: authState.error!.contains('successfully') || authState.error!.contains('Welcome') || authState.error!.contains('back')
                                            ? AppTheme.primaryGreen.withOpacity(0.1)
                                            : Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(15),
                                        border: Border.all(
                                          color: authState.error!.contains('successfully') || authState.error!.contains('Welcome') || authState.error!.contains('back')
                                              ? AppTheme.primaryGreen.withOpacity(0.3)
                                              : Colors.red.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        authState.error!,
                                        style: TextStyle(
                                          color: authState.error!.contains('successfully') || authState.error!.contains('Welcome') || authState.error!.contains('back')
                                              ? AppTheme.primaryGreen
                                              : Colors.red,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 16,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),

                                  SizedBox(height: spacing),

                                  // Or divider
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Divider(
                                          color: AppTheme.getSecondaryTextColor(context).withOpacity(0.5),
                                          thickness: 1,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                        child: Text(
                                          'Or continue with',
                                          style: TextStyle(
                                            color: AppTheme.greyColor,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Divider(
                                          color: AppTheme.getSecondaryTextColor(context).withOpacity(0.5),
                                          thickness: 1,
                                        ),
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: spacing),

                                  // Google Sign-In Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 55,
                                    child: OutlinedButton.icon(
                                      onPressed: authState.isLoading 
                                          ? null 
                                          : () {
                                              debugPrint('LoginScreen: Google Sign-In button pressed');
                                              ref.read(authProvider.notifier).signInWithGoogle();
                                            },
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                          color: AppTheme.primaryGreen,
                                          width: 2,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                        backgroundColor: AppTheme.whiteColor,
                                      ),
                                      icon: const Icon(
                                        Icons.account_circle_outlined,
                                        color: AppTheme.primaryGreen,
                                        size: 28,
                                      ),
                                      label: Text(
                                        authState.isLoading ? 'Signing in...' : 'Continue with Google',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.primaryGreen,
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: spacing),

                                  // Links row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          context.go('/forgot-password');
                                        },
                                        child: const Text(
                                          'Forgot Password?',
                                          style: TextStyle(
                                            color: AppTheme.primaryGreen,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          context.go('/register');
                                        },
                                        child: const Text(
                                          'Create Account',
                                          style: TextStyle(
                                            color: AppTheme.primaryGreen,
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

                          SizedBox(height: spacing),
                          
                          // Footer text
                          Text(
                            '© 2026 ExcellenceCoachingHub',
                            style: TextStyle(
                              color: AppTheme.getSecondaryTextColor(context),
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          SizedBox(height: spacing * 0.5),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // Mobile layout (existing code with minor adjustments)
      return Scaffold(
        body: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    
                    // Header with logo
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(25),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Image.asset(
                            'assets/logo.webp',
                            width: 70,
                            height: 70,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 25),
                        Text(
                          'Welcome Back!',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: AppTheme.getTextColor(context),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Sign in to continue your learning journey',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppTheme.getSecondaryTextColor(context),
                                height: 1.4,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 50),
                      ],
                    ),

                    // Login Form Card
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).shadowColor.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        border: Border.all(
                          color: Theme.of(context).dividerColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(28.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Email Field
                            TextFormField(
                              controller: _emailController,
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
                              style: TextStyle(
                                fontSize: 16,
                                color: AppTheme.getTextColor(context),
                              ),
                              decoration: InputDecoration(
                                labelText: 'Email Address',
                                labelStyle: TextStyle(
                                  color: AppTheme.getSecondaryTextColor(context),
                                  fontWeight: FontWeight.w500,
                                ),
                                prefixIcon: Icon(
                                  Icons.email_outlined, 
                                  color: AppTheme.getSecondaryTextColor(context)
                                ),
                                filled: true,
                                fillColor: AppTheme.lightGreen.withOpacity(0.1),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(
                                    color: AppTheme.greyColor.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: const BorderSide(
                                    color: AppTheme.primaryGreen,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Password Field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                              style: TextStyle(
                                fontSize: 16,
                                color: AppTheme.getTextColor(context),
                              ),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: TextStyle(
                                  color: AppTheme.getSecondaryTextColor(context),
                                  fontWeight: FontWeight.w500,
                                ),
                                prefixIcon: Icon(
                                  Icons.lock_outline, 
                                  color: AppTheme.getSecondaryTextColor(context)
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                    color: AppTheme.getSecondaryTextColor(context),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                filled: true,
                                fillColor: AppTheme.lightGreen.withOpacity(0.1),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(
                                    color: AppTheme.greyColor.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: const BorderSide(
                                    color: AppTheme.primaryGreen,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 25),

                            // Login Button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: authState.isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryGreen,
                                  foregroundColor: AppTheme.whiteColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: 2,
                                ),
                                child: authState.isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.whiteColor),
                                        ),
                                      )
                                    : const Text(
                                        'Sign In',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Success or Error message
                            if (authState.error != null)
                              Container(
                                padding: const EdgeInsets.all(16),
                                margin: const EdgeInsets.only(bottom: 15),
                                decoration: BoxDecoration(
                                  color: authState.error!.contains('successfully') || authState.error!.contains('Welcome') || authState.error!.contains('back')
                                      ? AppTheme.primaryGreen.withOpacity(0.1)
                                      : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: authState.error!.contains('successfully') || authState.error!.contains('Welcome') || authState.error!.contains('back')
                                        ? AppTheme.primaryGreen.withOpacity(0.3)
                                        : Colors.red.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  authState.error!,
                                  style: TextStyle(
                                    color: authState.error!.contains('successfully') || authState.error!.contains('Welcome') || authState.error!.contains('back')
                                        ? AppTheme.primaryGreen
                                        : AppTheme.getErrorColor(context),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                            const SizedBox(height: 25),

                            // Or divider
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: AppTheme.getSecondaryTextColor(context).withOpacity(0.5),
                                    thickness: 1,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Text(
                                    'Or continue with',
                                    style: TextStyle(
                                      color: AppTheme.greyColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: AppTheme.getSecondaryTextColor(context).withOpacity(0.5),
                                    thickness: 1,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 25),

                            // Google Sign-In Button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: OutlinedButton.icon(
                                onPressed: authState.isLoading 
                                    ? null 
                                    : () {
                                        debugPrint('LoginScreen: Google Sign-In button pressed');
                                        ref.read(authProvider.notifier).signInWithGoogle();
                                      },
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
                                  Icons.account_circle_outlined,
                                  color: AppTheme.primaryGreen,
                                  size: 24,
                                ),
                                label: Text(
                                  authState.isLoading ? 'Signing in...' : 'Continue with Google',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 25),

                            // Links row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    context.go('/forgot-password');
                                  },
                                  child: const Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      color: AppTheme.primaryGreen,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    context.go('/register');
                                  },
                                  child: const Text(
                                    'Create Account',
                                    style: TextStyle(
                                      color: AppTheme.primaryGreen,
                                      fontWeight: FontWeight.bold,
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
                    
                    // Footer text
                    const Text(
                      '© 2026 ExcellenceCoachingHub',
                      style: TextStyle(
                        color: AppTheme.greyColor,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 20),
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