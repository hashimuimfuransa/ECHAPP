import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _emailSent = false;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _sendReset() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      ref.read(authProvider.notifier).sendPasswordResetEmail(_emailController.text.trim());
      setState(() => _emailSent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

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
                    child: const Icon(Icons.mail_outline_rounded, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 50),
                  const Text('Password Help', style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w500, letterSpacing: 0.5)),
                  const SizedBox(height: 10),
                  const Text('Reset Your Password', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900, height: 1.2, letterSpacing: -1)),
                  const SizedBox(height: 20),
                  Container(width: 50, height: 4, decoration: BoxDecoration(color: const Color(0xFF00C896), borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 30),
                  const Text(
                    "We'll send you a reset link to your email address. Click it to create a new password for your account.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.6, fontWeight: FontWeight.w400),
                  ),
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
              position: Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero)
                  .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut)),
              child: _emailSent ? _buildSuccessMessage() : _buildResetForm(authState),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetForm(dynamic authState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Reset Password', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        const SizedBox(height: 12),
        const Text('Enter your email to receive a reset link', style: TextStyle(color: Colors.white60, fontSize: 16, fontWeight: FontWeight.w400, height: 1.5)),
        const SizedBox(height: 40),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Enter your email',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  prefixIcon: Icon(Icons.email_outlined, color: Colors.white.withOpacity(0.6)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.08),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF00C896), width: 2)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Email required';
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'Invalid email';
                  return null;
                },
              ),
              const SizedBox(height: 28),
              Material(
                color: Colors.transparent,
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF00C896), Color(0xFF009E76)]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: const Color(0xFF00C896).withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
                  ),
                  child: InkWell(
                    onTap: authState.isLoading ? null : _sendReset,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: authState.isLoading
                          ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white.withOpacity(0.9))))
                          : const Text('Send Reset Link', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5), textAlign: TextAlign.center),
                    ),
                  ),
                ),
              ),
              if (authState.error != null && !_emailSent) ...[
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.withOpacity(0.3))), child: Text(authState.error, style: TextStyle(color: Colors.red.shade400, fontSize: 12))),
              ],
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('Remember your password? ', style: TextStyle(color: Colors.white70, fontSize: 14)),
                TextButton(onPressed: () => context.push('/login'), child: const Text('Sign in', style: TextStyle(color: Color(0xFF00C896), fontSize: 14, fontWeight: FontWeight.w700))),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessMessage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [Color(0xFF00C896), Color(0xFF009E76)]),
              boxShadow: [BoxShadow(color: const Color(0xFF00C896).withOpacity(0.3), blurRadius: 30, spreadRadius: 5)],
            ),
            child: const Icon(Icons.check_rounded, size: 50, color: Colors.white),
          ),
        ),
        const SizedBox(height: 30),
        const Text('Check Your Email', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        const Text(
          "We've sent a reset link to your email. Click the link to create a new password.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.6),
        ),
        const SizedBox(height: 40),
        Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF00C896), width: 2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: InkWell(
              onTap: () => context.push('/login'),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                child: const Text('Back to Sign In', style: TextStyle(color: Color(0xFF00C896), fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.5), textAlign: TextAlign.center),
              ),
            ),
          ),
        ),
      ],
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
                  const SizedBox(height: 30),
                  Container(width: 80, height: 80, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [Color(0xFF00C896), Color(0xFF009E76)])), child: const Icon(Icons.mail_outline_rounded, size: 40, color: Colors.white)),
                  const SizedBox(height: 30),
                  _emailSent ? _buildMobileSuccessMessage() : _buildMobileResetForm(authState),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileResetForm(dynamic authState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Reset Password', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        const Text('Enter your email to receive a reset link', style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.5)),
        const SizedBox(height: 28),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Enter your email',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  prefixIcon: Icon(Icons.email_outlined, color: Colors.white.withOpacity(0.6)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.08),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00C896), width: 2)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Email required';
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'Invalid email';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Material(
                color: Colors.transparent,
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF00C896), Color(0xFF009E76)]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: const Color(0xFF00C896).withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
                  ),
                  child: InkWell(
                    onTap: authState.isLoading ? null : _sendReset,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: authState.isLoading
                          ? SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white.withOpacity(0.9))))
                          : const Text('Send Reset Link', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                    ),
                  ),
                ),
              ),
              if (authState.error != null && !_emailSent) ...[
                const SizedBox(height: 12),
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.withOpacity(0.3))), child: Text(authState.error, style: TextStyle(color: Colors.red.shade400, fontSize: 11))),
              ],
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('Remember password? ', style: TextStyle(color: Colors.white70, fontSize: 12)), TextButton(onPressed: () => context.push('/login'), child: const Text('Sign in', style: TextStyle(color: Color(0xFF00C896), fontSize: 12, fontWeight: FontWeight.w700)))]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileSuccessMessage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        const Text('Check Your Email', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        const Text(
          "We've sent a reset link to your email. Click it to create a new password.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.6),
        ),
        const SizedBox(height: 30),
        Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFF00C896), width: 2), borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              onTap: () => context.push('/login'),
              borderRadius: BorderRadius.circular(12),
              child: Container(padding: const EdgeInsets.symmetric(vertical: 12), child: const Text('Back to Sign In', style: TextStyle(color: Color(0xFF00C896), fontSize: 14, fontWeight: FontWeight.w700), textAlign: TextAlign.center)),
            ),
          ),
        ),
      ],
    );
  }
}
