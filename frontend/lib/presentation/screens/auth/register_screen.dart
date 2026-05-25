import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _hasNavigated = false;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    _animController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _register() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      ref.read(authProvider.notifier).register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
        _phoneController.text.isEmpty ? null : _phoneController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    ref.listen(authProvider, (previous, current) {
      if (current.user != null && !current.isLoading && !_hasNavigated) {
        _hasNavigated = true;
        if (current.user?.role == 'admin') {
          context.go('/admin');
        } else {
          context.go('/dashboard');
        }
      }
    });

    if (isDesktop) {
      return _buildDesktopLayout(authState);
    }
    return _buildMobileLayout(authState);
  }

  Widget _buildDesktopLayout(dynamic authState) {
    return Scaffold(
      body: Container(
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
        child: Stack(
          children: [
            Positioned(
              top: -150,
              right: -150,
              child: Container(
                width: 500,
                height: 500,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF00C896).withOpacity(0.1),
                      const Color(0xFF00C896).withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF00C896).withOpacity(0.08),
                      const Color(0xFF00C896).withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: Container(
                width: ResponsiveBreakpoints.isDesktop(context) ? 600 : 500,
                constraints: const BoxConstraints(maxWidth: 600),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 30,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: _buildRightPanel(authState),
              ),
            ),
          ],
        ),
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
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const SizedBox(width: 40),
            IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 28)),
          ]),
          const SizedBox(height: 20),
          const SizedBox(height: 20),
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Create Account', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                const SizedBox(height: 12),
                const Text('Fill in your details to get started', style: TextStyle(color: Colors.white60, fontSize: 16, fontWeight: FontWeight.w400, height: 1.5)),
                const SizedBox(height: 30),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTextField(_nameController, 'Full Name', Icons.person_outline),
                      const SizedBox(height: 16),
                      _buildTextField(_emailController, 'Email Address', Icons.email_outlined, TextInputType.emailAddress),
                      const SizedBox(height: 16),
                      _buildTextField(_phoneController, 'Phone Number (Optional)', Icons.phone_outlined, TextInputType.phone, false),
                      const SizedBox(height: 16),
                      _buildPasswordField(_passwordController, 'Password', (value) {
                        if (value == null || value.isEmpty) return 'Password required';
                        if (value.length < 6) return 'Min 6 characters';
                        return null;
                      }),
                      const SizedBox(height: 16),
                      _buildPasswordField(_confirmController, 'Confirm Password', (value) {
                        if (value == null || value.isEmpty) return 'Confirm password';
                        if (value != _passwordController.text) return 'Passwords don\'t match';
                        return null;
                      }, TextInputAction.done, _register),
                      const SizedBox(height: 28),
                      _buildSignUpButton(authState),
                      const SizedBox(height: 16),
                      if (authState.error != null) Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.withOpacity(0.3))), child: Text(authState.error, style: TextStyle(color: Colors.red.shade400, fontSize: 12))),
                      const SizedBox(height: 16),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Text('Already have an account? ', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        TextButton(onPressed: () => context.push('/login'), child: const Text('Sign in', style: TextStyle(color: Color(0xFF00C896), fontSize: 14, fontWeight: FontWeight.w700))),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(dynamic authState) {
    return Scaffold(
      backgroundColor: const Color(0xFF00C896),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      
                      // Logo
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00C896), Color(0xFF009E76)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00C896).withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Image.asset(
                                'assets/logo.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      const Text(
                        'Create Account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF1A2433),
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      const Text(
                        'Join our community',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF4A5568),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildTextField(_nameController, 'Full Name', Icons.person_outline),
                            const SizedBox(height: 14),
                            _buildTextField(_emailController, 'Email', Icons.email_outlined, TextInputType.emailAddress),
                            const SizedBox(height: 14),
                        _buildTextField(_phoneController, 'Phone (Optional)', Icons.phone_outlined, TextInputType.phone, false),
                        const SizedBox(height: 14),
                        _buildPasswordField(_passwordController, 'Password', (value) { if (value == null || value.isEmpty) return 'Required'; if (value.length < 6) return 'Min 6 chars'; return null; }),
                        const SizedBox(height: 14),
                        _buildPasswordField(_confirmController, 'Confirm', (value) { if (value == null || value.isEmpty) return 'Required'; if (value != _passwordController.text) return 'Mismatch'; return null; }, TextInputAction.done, _register),
                        const SizedBox(height: 20),
                        _buildSignUpButton(authState),
                        const SizedBox(height: 12),
                        if (authState.error != null) Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.withOpacity(0.3))), child: Text(authState.error, style: TextStyle(color: Colors.red.shade400, fontSize: 11))),
                        const SizedBox(height: 12),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('Have an account? ', style: TextStyle(color: Color(0xFF4A5568), fontSize: 12)), TextButton(onPressed: () => context.push('/login'), child: const Text('Sign in', style: TextStyle(color: Color(0xFF00C896), fontSize: 12, fontWeight: FontWeight.w700)))]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, [TextInputType? keyboardType, bool required = true, TextInputAction textInputAction = TextInputAction.next]) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Color(0xFF1A2433), fontSize: 15),
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(color: Color(0xFF8899AA)),
          prefixIcon: Icon(icon, color: const Color(0xFF8899AA)),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        validator: (value) {
          if (!required) return null;
          if (value == null || value.isEmpty) return '$label required';
          if (keyboardType == TextInputType.emailAddress && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
            return 'Invalid email';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String label, String? Function(String?) validator, [TextInputAction textInputAction = TextInputAction.next, VoidCallback? onSubmitted]) {
    bool obscure = label.contains('Confirm') ? _obscureConfirm : _obscurePassword;
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Color(0xFF1A2433), fontSize: 15),
        obscureText: obscure,
        textInputAction: textInputAction,
        onFieldSubmitted: onSubmitted != null ? (_) => onSubmitted() : null,
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(color: Color(0xFF8899AA)),
          prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF8899AA)),
          suffixIcon: IconButton(
            icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFF8899AA)),
            onPressed: () => setState(() {
              if (label.contains('Confirm')) _obscureConfirm = !_obscureConfirm;
              else _obscurePassword = !_obscurePassword;
            }),
          ),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildSignUpButton(dynamic authState) {
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
          onTap: authState.isLoading ? null : _register,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: authState.isLoading
                ? SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white.withOpacity(0.9))))
                : const Text('Create Account', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.5), textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
