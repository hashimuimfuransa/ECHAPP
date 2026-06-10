import 'dart:math' show pi, sin, cos, Random;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/presentation/providers/localization_provider.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';
import 'package:excellencecoachinghub/l10n/app_localizations.dart';
import 'package:excellencecoachinghub/presentation/widgets/desktop_brand_panel.dart';

class LanguageSelectionScreen extends ConsumerStatefulWidget {
  final bool isFirstTime;
  final VoidCallback? onComplete;

  const LanguageSelectionScreen({
    super.key,
    this.isFirstTime = true,
    this.onComplete,
  });

  @override
  ConsumerState<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends ConsumerState<LanguageSelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late AnimationController _animController;
  String? _selectedLanguage;
  int _hoveredIndex = -1;

  // Fixed dark theme to match splash screen
  Color get _backgroundColor => const Color(0xFF071810);
  Color get _cardColor => const Color(0xFF1E293B);
  Color get _textColor => Colors.white;
  Color get _subtitleColor => const Color(0xFF94A3B8);
  Color get _unselectedCardBg => Colors.white.withOpacity(0.06);
  Color get _borderColor => Colors.white.withOpacity(0.1);
  Color get _accentColor => const Color(0xFF10B981);

  final List<Map<String, dynamic>> _languages = [
    {
      'code': 'en',
      'name': 'English',
      'nativeName': 'English',
      'flag': '🇬🇧',
      'description': 'World\'s most spoken language',
    },
    {
      'code': 'rw',
      'name': 'Kinyarwanda',
      'nativeName': 'Ikinyarwanda',
      'flag': '🇷🇼',
      'description': 'Native language of Rwanda',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOutQuart,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentLocale = ref.read(localeProvider);
      setState(() {
        _selectedLanguage = currentLocale.languageCode;
      });
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _handleLanguageSelection(String languageCode) {
    setState(() {
      _selectedLanguage = languageCode;
    });
  }

  Future<void> _handleContinue() async {
    if (_selectedLanguage == null) return;
    
    await ref.read(localeProvider.notifier).setLanguage(_selectedLanguage!);
    
    if (widget.isFirstTime) {
      await ref.read(localeProvider.notifier).markLanguageSelected();
    }

    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      if (widget.isFirstTime) {
        final isDesktop = ResponsiveBreakpoints.isDesktop(context);
        context.go(isDesktop ? '/email-auth-option' : '/auth-selection');
      } else {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/settings');
        }
      }
    }
  }

  void _handleSkip() async {
    await ref.read(localeProvider.notifier).setLanguage('en');
    await ref.read(localeProvider.notifier).markLanguageSelected();

    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      final isDesktop = ResponsiveBreakpoints.isDesktop(context);
      context.go(isDesktop ? '/email-auth-option' : '/auth-selection');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    return Scaffold(
      backgroundColor: const Color(0xFF071810),
      body: Stack(
        children: [
          _buildBackgroundGradient(),
          _buildFloatingAnimation(),
          SafeArea(
            child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundGradient() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF071A0F),
            Color(0xFF0A2415),
            Color(0xFF071810),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingAnimation() {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final t = _animController.value;
        return Stack(
          children: [
            Positioned(
              top: -100 + 30 * sin(t * 2 * pi),
              right: -100 + 20 * cos(t * 2 * pi),
              child: _glowCircle(400, const Color(0xFF00C896).withOpacity(0.15), 70),
            ),
            Positioned(
              bottom: 80 + 40 * cos(t * 2 * pi + 1),
              left: -120 + 30 * sin(t * 2 * pi + 1),
              child: _glowCircle(300, const Color(0xFF34D399).withOpacity(0.1), 55),
            ),
            ...List.generate(12, (i) {
              final random = Random(i);
              final p = Offset(random.nextDouble(), random.nextDouble());
              final size = random.nextDouble() * 36 + 8;
              final y = (p.dy + t * 0.08 * (i % 3 + 1)) % 1.0;
              return Positioned(
                left: MediaQuery.of(context).size.width * p.dx,
                top: MediaQuery.of(context).size.height * y,
                child: Opacity(
                  opacity: 0.15 + 0.08 * sin(t * 2 * pi + i),
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.4),
                          Colors.white.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _glowCircle(double size, Color color, double blur) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: blur,
            spreadRadius: blur / 2,
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        const Expanded(
          flex: 45,
          child: DesktopBrandPanel(
            headline: 'Welcome to',
            title: 'Excellence\nCoaching Hub',
            tagline: 'Empowering Growth.\nInspiring Excellence.',
          ),
        ),
        Expanded(
          flex: 55,
          child: Container(
            color: const Color(0xFF0A2415),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
                  child: _buildContent(isDesktop: true),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    final size = MediaQuery.of(context).size;
    final isSmall = size.height < 680;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, isSmall ? 12 : 20, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: const Color(0xFF10B981).withOpacity(0.6),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.45),
                          blurRadius: 22,
                          spreadRadius: 4,
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(0.30),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(7),
                        child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Excellence',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Coaching Hub',
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: isSmall ? 10 : 16),
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildContent(isDesktop: false, isSmall: isSmall),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent({required bool isDesktop, bool isSmall = false}) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isDesktop) ...[
          Text(
            l10n?.languageSelectionTitle ?? 'Select Your Language',
            style: TextStyle(
              fontSize: isSmall ? 22 : 26,
              fontWeight: FontWeight.w700,
              color: _textColor,
              letterSpacing: -0.5,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            l10n?.languageSelectionSubtitle ?? 'Choose your preferred language for the best experience',
            style: TextStyle(
              fontSize: 13,
              color: _subtitleColor,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isSmall ? 12 : 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Image.asset(
                'assets/Course app-bro.png',
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
                errorBuilder: (c, e, s) => const SizedBox.shrink(),
              ),
            ),
          ),
          SizedBox(height: isSmall ? 12 : 16),
        ] else ...[
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF00C896).withOpacity(0.3),
                  const Color(0xFF00C896).withOpacity(0.1),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00C896).withOpacity(0.4),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: ClipOval(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Image.asset(
                  'assets/logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            l10n?.languageSelectionTitle ?? 'Select Your Language',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n?.languageSelectionSubtitle ?? 'Choose your preferred language for the best experience',
            style: TextStyle(
              fontSize: 15,
              color: _subtitleColor,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
        ],

        // Language cards
        ..._languages.asMap().entries.map((entry) {
          final index = entry.key;
          final language = entry.value;
          final isSelected = _selectedLanguage == (language['code'] ?? '');
          final isHovered = _hoveredIndex == index;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildModernLanguageCard(
              language: language,
              isSelected: isSelected,
              isHovered: isHovered,
              index: index,
              isDesktop: isDesktop,
            ),
          );
        }),

        SizedBox(height: isDesktop ? 40 : (isSmall ? 16 : 24)),

        // Continue button
        _buildModernContinueButton(isDesktop: isDesktop),

        // Skip button
        if (widget.isFirstTime) ...[
          const SizedBox(height: 16),
          _buildModernSkipButton(),
        ],
      ],
    );
  }

  Widget _buildModernLanguageCard({
    required Map<String, dynamic> language,
    required bool isSelected,
    required bool isHovered,
    required int index,
    required bool isDesktop,
  }) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = -1),
      child: GestureDetector(
        onTap: () => _handleLanguageSelection(language['code'] ?? ''),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.all(isDesktop ? 20 : 18),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF00C896).withOpacity(0.15)
                : isHovered
                    ? Colors.white.withOpacity(0.1)
                    : _unselectedCardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF00C896)
                  : isHovered
                      ? Colors.white.withOpacity(0.2)
                      : _borderColor,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF00C896).withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : isHovered
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
          ),
          child: Row(
            children: [
              // Flag with modern container
              Container(
                width: isDesktop ? 56 : 52,
                height: isDesktop ? 56 : 52,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF00C896).withOpacity(0.12)
                      : const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF00C896).withOpacity(0.3)
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    language['flag'] ?? '🌐',
                    style: TextStyle(
                      fontSize: isDesktop ? 28 : 26,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Language info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      language['nativeName'] ?? '',
                      style: TextStyle(
                        fontSize: isDesktop ? 17 : 16,
                        fontWeight: FontWeight.w600,
                        color: _textColor,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      language['description'] ?? '',
                      style: TextStyle(
                        fontSize: isDesktop ? 13 : 12,
                        color: _subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Modern check indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? const Color(0xFF00C896)
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF00C896)
                        : const Color(0xFF64748B),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernContinueButton({required bool isDesktop}) {
    final canContinue = _selectedLanguage != null;
    final l10n = AppLocalizations.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canContinue ? _handleContinue : null,
        splashColor: canContinue ? Colors.white.withOpacity(0.2) : Colors.transparent,
        highlightColor: canContinue ? Colors.white.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: isDesktop ? 54 : 52,
          decoration: BoxDecoration(
            gradient: canContinue
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF00C896), Color(0xFF059669)],
                  )
                : null,
            color: canContinue ? null : const Color(0xFF334155),
            borderRadius: BorderRadius.circular(14),
            boxShadow: canContinue
                ? [
                    BoxShadow(
                      color: const Color(0xFF00C896).withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n?.continueText ?? 'Continue',
                  style: TextStyle(
                    color: canContinue
                        ? Colors.white
                        : const Color(0xFF64748B),
                    fontSize: isDesktop ? 16 : 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
                if (canContinue) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernSkipButton() {
    final l10n = AppLocalizations.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _handleSkip,
        splashColor: _subtitleColor.withOpacity(0.2),
        highlightColor: _subtitleColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          child: Text(
            l10n?.skipForNow ?? 'Skip for now',
            style: TextStyle(
              color: _subtitleColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
