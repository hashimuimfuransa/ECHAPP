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
  String? _selectedLanguage;
  int _hoveredIndex = -1;

  // Theme-aware getters
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  
  Color get _backgroundColor => _isDark 
      ? const Color(0xFF0F172A) 
      : const Color(0xFFF8FAFC);
  
  Color get _cardColor => _isDark 
      ? const Color(0xFF1E293B) 
      : Colors.white;
  
  Color get _textColor => _isDark 
      ? Colors.white 
      : const Color(0xFF0F172A);
  
  Color get _subtitleColor => _isDark 
      ? const Color(0xFF94A3B8) 
      : const Color(0xFF64748B);
  
  Color get _unselectedCardBg => _isDark 
      ? const Color(0xFF334155) 
      : const Color(0xFFF1F5F9);
  
  Color get _borderColor => _isDark 
      ? const Color(0xFF475569) 
      : const Color(0xFFE2E8F0);

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
      backgroundColor: isDesktop 
          ? (_isDark ? const Color(0xFF0F172A) : Colors.white)
          : _backgroundColor,
      body: isDesktop 
          ? _buildDesktopLayout()
          : _buildMobileLayout(),
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
            color: _isDark ? const Color(0xFF0F172A) : Colors.white,
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
    return SafeArea(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildMobileHeader(),
                const SizedBox(height: 32),
                Expanded(
                  child: _buildContent(isDesktop: false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileHeader() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF00C896).withOpacity(_isDark ? 0.15 : 0.1),
          ),
          child: ClipOval(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Image.asset(
                'assets/logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Excellence Coaching Hub',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _textColor,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildContent({required bool isDesktop}) {
    final l10n = AppLocalizations.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isDesktop) ...[
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00C896).withOpacity(_isDark ? 0.15 : 0.1),
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
        ],
        
        // Title section
        Text(
          l10n?.languageSelectionTitle ?? 'Select Your Language',
          style: TextStyle(
            fontSize: isDesktop ? 32 : 26,
            fontWeight: FontWeight.w700,
            color: _textColor,
            letterSpacing: -0.5,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          l10n?.languageSelectionSubtitle ?? 'Choose your preferred language for the best experience',
          style: TextStyle(
            fontSize: isDesktop ? 15 : 14,
            color: _subtitleColor,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        
        // App value proposition
        Container(
          padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16, vertical: 14),
          decoration: BoxDecoration(
            color: _isDark ? const Color(0xFF1E293B) : const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isDark ? const Color(0xFF334155) : const Color(0xFFBBF7D0),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 16,
                    color: const Color(0xFF059669),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Expert-led Courses',
                    style: TextStyle(
                      fontSize: isDesktop ? 14 : 13,
                      fontWeight: FontWeight.w600,
                      color: _isDark ? const Color(0xFF6EE7B7) : const Color(0xFF059669),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Learn from industry experts with interactive lessons, quizzes, and certifications to advance your career.',
                style: TextStyle(
                  fontSize: isDesktop ? 13 : 12,
                  color: _subtitleColor,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        
        SizedBox(height: isDesktop ? 32 : 24),
        
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
        
        SizedBox(height: isDesktop ? 40 : 32),
        
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
                ? const Color(0xFF00C896).withOpacity(_isDark ? 0.15 : 0.08)
                : isHovered
                    ? (_isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0))
                    : _unselectedCardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected 
                  ? const Color(0xFF00C896)
                  : isHovered
                      ? (_isDark ? const Color(0xFF64748B) : const Color(0xFFCBD5E1))
                      : _borderColor,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected && !_isDark
                ? [
                    BoxShadow(
                      color: const Color(0xFF00C896).withOpacity(0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : isHovered && !_isDark
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
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
                      : (_isDark ? const Color(0xFF1E293B) : Colors.white),
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
                        : (_isDark ? const Color(0xFF64748B) : const Color(0xFFCBD5E1)),
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
            color: canContinue ? null : (_isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
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
                        : (_isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
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
