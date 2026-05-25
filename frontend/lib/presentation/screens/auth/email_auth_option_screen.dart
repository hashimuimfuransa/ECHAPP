import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';

class EmailAuthOptionScreen extends StatefulWidget {
  const EmailAuthOptionScreen({super.key});

  @override
  State<EmailAuthOptionScreen> createState() => _EmailAuthOptionScreenState();
}

class _EmailAuthOptionScreenState extends State<EmailAuthOptionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    if (isDesktop) {
      return _buildDesktopLayout();
    }

    return _buildMobileLayout();
  }

  Widget _buildDesktopLayout() {
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
                width: ResponsiveBreakpoints.isDesktop(context) ? 500 : 400,
                constraints: const BoxConstraints(maxWidth: 500),
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
                child: _buildRightPanel(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRightPanel() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 28),
                    tooltip: 'Go back',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero)
                      .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Choose Your Path',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Select how you\'d like to proceed with your account',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 50),
                      _AuthOptionButton(
                        icon: Icons.login_rounded,
                        title: 'Sign In',
                        subtitle: 'Access your existing account',
                        color: const Color(0xFF4CAF50),
                        onTap: () => context.push('/login'),
                        delay: 100,
                      ),
                      const SizedBox(height: 20),
                      _AuthOptionButton(
                        icon: Icons.person_add_rounded,
                        title: 'Create Account',
                        subtitle: 'Join our community of learners',
                        color: const Color(0xFF2196F3),
                        onTap: () => context.push('/register'),
                        delay: 200,
                      ),
                      const SizedBox(height: 20),
                      _AuthOptionButton(
                        icon: Icons.lock_reset_rounded,
                        title: 'Reset Password',
                        subtitle: 'Recover your account access',
                        color: const Color(0xFFFF9800),
                        onTap: () => context.push('/forgot-password'),
                        delay: 300,
                      ),
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.verified_user_rounded, color: Color(0xFF00C896), size: 20),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Your account is protected with enterprise-grade security',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      const _TermsFooter(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(context);
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
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallMobile ? 20 : 24, 
                    vertical: isSmallMobile ? 24 : 32
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: isSmallMobile ? 20 : 30),
                      
                      // Logo
                      Center(
                        child: Container(
                          width: isSmallMobile ? 80 : 100,
                          height: isSmallMobile ? 80 : 100,
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
                              padding: EdgeInsets.all(isSmallMobile ? 12 : 15),
                              child: Image.asset(
                                'assets/logo.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: isSmallMobile ? 20 : 30),
                      
                      Text(
                        'Choose Your Path',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFF1A2433),
                          fontSize: isSmallMobile ? 24 : 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      
                      SizedBox(height: isSmallMobile ? 6 : 8),
                      
                      Text(
                        'Select how you\'d like to proceed',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFF4A5568),
                          fontSize: isSmallMobile ? 13 : 14,
                          height: 1.5,
                        ),
                      ),
                      
                      SizedBox(height: isSmallMobile ? 24 : 32),
                      
                      _AuthOptionButton(
                        icon: Icons.login_rounded,
                        title: 'Sign In',
                        subtitle: 'Access your account',
                        color: const Color(0xFF4CAF50),
                        onTap: () => context.push('/login'),
                        compact: isSmallMobile,
                      ),
                      SizedBox(height: isSmallMobile ? 12 : 16),
                      _AuthOptionButton(
                        icon: Icons.person_add_rounded,
                        title: 'Create Account',
                        subtitle: 'Join our community',
                        color: const Color(0xFF2196F3),
                        onTap: () => context.push('/register'),
                        compact: isSmallMobile,
                      ),
                      SizedBox(height: isSmallMobile ? 12 : 16),
                      _AuthOptionButton(
                        icon: Icons.lock_reset_rounded,
                        title: 'Reset Password',
                        subtitle: 'Recover your access',
                        color: const Color(0xFFFF9800),
                        onTap: () => context.push('/forgot-password'),
                        compact: isSmallMobile,
                      ),
                      SizedBox(height: isSmallMobile ? 24 : 32),
                      const _TermsFooter(),
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
}

class _AuthOptionButton extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final int delay;
  final bool compact;

  const _AuthOptionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.delay = 0,
    this.compact = false,
  });

  @override
  State<_AuthOptionButton> createState() => _AuthOptionButtonState();
}

class _AuthOptionButtonState extends State<_AuthOptionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(widget.compact ? 16 : 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(widget.compact ? 12 : 16),
            border: Border.all(
              color: _isHovered
                  ? widget.color.withOpacity(0.5)
                  : const Color(0xFFE2E8F0),
              width: _isHovered ? 2 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
              if (_isHovered)
                BoxShadow(
                  color: widget.color.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: widget.compact ? 44 : 56,
                height: widget.compact ? 44 : 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.color,
                      widget.color.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(widget.compact ? 12 : 14),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  widget.icon,
                  color: Colors.white,
                  size: widget.compact ? 22 : 28,
                ),
              ),
              SizedBox(width: widget.compact ? 14 : 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        color: const Color(0xFF1A2433),
                        fontSize: widget.compact ? 16 : 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: widget.compact ? 2 : 4),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        color: const Color(0xFF4A5568),
                        fontSize: widget.compact ? 12 : 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.arrow_forward_rounded,
                color: _isHovered ? widget.color : const Color(0xFF8899AA),
                size: widget.compact ? 20 : 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF00C896),
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _TermsFooter extends StatelessWidget {
  const _TermsFooter();
  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    return Text.rich(
      TextSpan(
        style: TextStyle(
            color: const Color(0xFF8899AA),
            fontSize: isDesktop ? 12.5 : 11.5,
            height: 1.5),
        children: [
          const TextSpan(text: 'By continuing, you agree to our '),
          TextSpan(
            text: 'Terms of Service',
            style: const TextStyle(
                color: Color(0xFF00C896),
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: Color(0xFF00C896)),
            recognizer: TapGestureRecognizer()
              ..onTap = () => context.push('/terms'),
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Policy',
            style: const TextStyle(
                color: Color(0xFF00C896),
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: Color(0xFF00C896)),
            recognizer: TapGestureRecognizer()
              ..onTap = () => context.push('/privacy'),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
