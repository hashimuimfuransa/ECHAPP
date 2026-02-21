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
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F4C75), Color(0xFF041B2D)],
                stops: [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),
          Positioned(top: -100, right: -100, child: Container(width: 400, height: 400, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF00C896).withOpacity(0.08)))),
          Positioned(bottom: -50, left: -50, child: Container(width: 350, height: 350, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFFFBF00).withOpacity(0.05)))),
          SafeArea(
            child: Row(
              children: [
                Expanded(child: _buildLeftPanel()),
                Expanded(child: _buildRightPanel(authState)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPanel() {
    final fadeAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF00C896).withOpacity(0.15), const Color(0xFF0A4A5A).withOpacity(0.1)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeTransition(
            opacity: fadeAnimation,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(-0.3, 0), end: Offset.zero)
                  .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut)),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [Color(0xFF00C896), Color(0xFF009E76)]),
                      boxShadow: [BoxShadow(color: const Color(0xFF00C896).withOpacity(0.3), blurRadius: 30, spreadRadius: 5)],
                    ),
                    child: const Icon(Icons.person_add_rounded, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 50),
                  const Text('Join Us', style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w500, letterSpacing: 0.5)),
                  const SizedBox(height: 10),
                  const Text('Create Your Account', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900, height: 1.2, letterSpacing: -1)),
                  const SizedBox(height: 20),
                  Container(width: 50, height: 4, decoration: BoxDecoration(color: const Color(0xFF00C896), borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 30),
                  const Text('Start your learning journey today with Excellence Coaching Hub and unlock your full potential.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.6, fontWeight: FontWeight.w400)),
                ],
              ),
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
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const SizedBox(width: 40),
            IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 28)),
          ]),
          const SizedBox(height: 20),
          FadeTransition(
            opacity: Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut)),
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut)),
              child: SingleChildScrollView(
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
                          }),
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
          Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F4C75)]))),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_rounded, color: Colors.white)), const SizedBox(width: 8)]),
                  const SizedBox(height: 20),
                  Container(width: 70, height: 70, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [Color(0xFF00C896), Color(0xFF009E76)])), child: const Icon(Icons.person_add_rounded, size: 35, color: Colors.white)),
                  const SizedBox(height: 20),
                  const Text('Create Account', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  const Text('Join our community', style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.5)),
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
                        _buildPasswordField(_confirmController, 'Confirm', (value) { if (value == null || value.isEmpty) return 'Required'; if (value != _passwordController.text) return 'Mismatch'; return null; }),
                        const SizedBox(height: 20),
                        _buildSignUpButton(authState),
                        const SizedBox(height: 12),
                        if (authState.error != null) Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.withOpacity(0.3))), child: Text(authState.error, style: TextStyle(color: Colors.red.shade400, fontSize: 11))),
                        const SizedBox(height: 12),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('Have an account? ', style: TextStyle(color: Colors.white70, fontSize: 12)), TextButton(onPressed: () => context.push('/login'), child: const Text('Sign in', style: TextStyle(color: Color(0xFF00C896), fontSize: 12, fontWeight: FontWeight.w700)))]),
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

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, [TextInputType? keyboardType, bool required = true]) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: label,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.6)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00C896), width: 2)),
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
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String label, String? Function(String?) validator) {
    bool obscure = label.contains('Confirm') ? _obscureConfirm : _obscurePassword;
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: label,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        prefixIcon: Icon(Icons.lock_outline_rounded, color: Colors.white.withOpacity(0.6)),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.white.withOpacity(0.6)),
          onPressed: () => setState(() {
            if (label.contains('Confirm')) _obscureConfirm = !_obscureConfirm;
            else _obscurePassword = !_obscurePassword;
          }),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00C896), width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      validator: validator,
    );
  }

  Widget _buildSignUpButton(dynamic authState) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF00C896), Color(0xFF009E76)]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: const Color(0xFF00C896).withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
        ),
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
