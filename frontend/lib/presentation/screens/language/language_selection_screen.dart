import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/presentation/providers/localization_provider.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';
import 'package:excellencecoachinghub/l10n/app_localizations.dart';

class LanguageSelectionScreen extends ConsumerStatefulWidget {
  final bool isFirstTime;
  final VoidCallback? onComplete;

  const LanguageSelectionScreen({
    super.key,
    this.isFirstTime = true,
    this.onComplete,
  });

  @override
  _LanguageSelectionScreenState createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends ConsumerState<LanguageSelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  String? _selectedLanguage;

  // Theme-aware getters
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _cardColor => _isDark ? const Color(0xFF1E293B) : Colors.white.withOpacity(0.95);
  Color get _textColor => _isDark ? Colors.white : const Color(0xFF1A2433);
  Color get _secondaryTextColor => _isDark ? Colors.white70 : const Color(0xFF4A5568);
  Color get _languageCardBg => _isDark ? const Color(0xFF0F172A) : Colors.grey.shade50;
  Color get _languageCardBorder => _isDark ? const Color(0xFF334155) : Colors.grey.shade200;
  Color get _flagBgColor => _isDark ? const Color(0xFF1E293B) : Colors.white;
  Color get _selectionBorderColor => _isDark ? const Color(0xFF334155) : Colors.grey.shade300;

  final List<Map<String, dynamic>> _languages = [
    {
      'code': 'en',
      'name': 'English',
      'nativeName': 'English',
      'flag': '🇬🇧',
    },
    {
      'code': 'rw',
      'name': 'Kinyarwanda',
      'nativeName': 'Ikinyarwanda',
      'flag': '🇷🇼',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    _animController.forward();

    // Load saved language preference
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentLocale = ref.read(localeProvider);
      setState(() {
        _selectedLanguage = currentLocale.languageCode;
      });
    });
  }

  @override
  void dispose() {
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

    debugPrint('LanguageSelection: Changing language to $_selectedLanguage');

    // Save language preference
    await ref.read(localeProvider.notifier).setLanguage(_selectedLanguage!);

    debugPrint('LanguageSelection: Language set, current locale is ${ref.read(localeProvider)}');

    if (widget.isFirstTime) {
      await ref.read(localeProvider.notifier).markLanguageSelected();
    }

    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      // Navigate to appropriate next screen
      if (widget.isFirstTime) {
        context.go('/auth-selection');
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
    // Default to English when skipped
    await ref.read(localeProvider.notifier).setLanguage('en');
    await ref.read(localeProvider.notifier).markLanguageSelected();

    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      context.go('/auth-selection');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              isDesktop ? 'assets/onboading desktop.png' : 'assets/onboardign mobile.png',
            ),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF0F172A).withOpacity(0.4),
                const Color(0xFF1E293B).withOpacity(0.6),
                const Color(0xFF0F172A).withOpacity(0.85),
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
          ),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Center(
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 40,
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: _buildContent(isDesktop: true),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmall = screenHeight < 680;
    return Column(
      children: [
        // Top section with logo
        SizedBox(
          height: isSmall ? screenHeight * 0.25 : screenHeight * 0.30,
          child: _buildHeader(compact: isSmall),
        ),
        // Bottom section with language options
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: SingleChildScrollView(
              child: _buildContent(isDesktop: false),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader({bool compact = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo
          Container(
            width: compact ? 72 : 100,
            height: compact ? 72 : 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.9),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: ClipOval(
              child: Padding(
                padding: EdgeInsets.all(compact ? 12 : 16),
                child: Image.asset(
                  'assets/logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          SizedBox(height: compact ? 12 : 20),
          // App name
          Text(
            'Excellence Coaching Hub',
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 20 : 24,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContent({required bool isDesktop}) {
    return Padding(
      padding: EdgeInsets.all(isDesktop ? 40 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isDesktop) ...[
            // Logo for desktop
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00C896).withOpacity(0.1),
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
            const SizedBox(height: 24),
          ],
          // Title
          Text(
            AppLocalizations.of(context)!.languageSelectionTitle,
            style: TextStyle(
              color: _textColor,
              fontSize: isDesktop ? 28 : 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Subtitle
          Text(
            AppLocalizations.of(context)!.languageSelectionSubtitle,
            style: TextStyle(
              color: _secondaryTextColor,
              fontSize: isDesktop ? 16 : 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Language options
          ..._languages.map((language) => _buildLanguageCard(
                language: language,
                isSelected: _selectedLanguage == language['code'],
                isDesktop: isDesktop,
              )),
          const SizedBox(height: 24),
          // Continue button
          _buildContinueButton(isDesktop: isDesktop),
          // Skip button (only for first-time users)
          if (widget.isFirstTime) ...[
            const SizedBox(height: 16),
            _buildSkipButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildLanguageCard({
    required Map<String, dynamic> language,
    required bool isSelected,
    required bool isDesktop,
  }) {
    return GestureDetector(
      onTap: () => _handleLanguageSelection(language['code']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(isDesktop ? 20 : 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00C896).withOpacity(_isDark ? 0.2 : 0.1) : _languageCardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF00C896) : _languageCardBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected && !_isDark
              ? [
                  BoxShadow(
                    color: const Color(0xFF00C896).withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Flag emoji
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _flagBgColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: _isDark ? [] : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  language['flag'],
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Language names
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    language['nativeName'],
                    style: TextStyle(
                      color: _textColor,
                      fontSize: isDesktop ? 18 : 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    language['name'],
                    style: TextStyle(
                      color: _secondaryTextColor,
                      fontSize: isDesktop ? 14 : 12,
                    ),
                  ),
                ],
              ),
            ),
            // Selection indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFF00C896) : Colors.transparent,
                border: Border.all(
                  color: isSelected ? const Color(0xFF00C896) : _selectionBorderColor,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton({required bool isDesktop}) {
    final canContinue = _selectedLanguage != null;

    return GestureDetector(
      onTap: canContinue ? _handleContinue : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: isDesktop ? 56 : 52,
        decoration: BoxDecoration(
          gradient: canContinue
              ? const LinearGradient(
                  colors: [Color(0xFF00C896), Color(0xFF059669)],
                )
              : LinearGradient(
                  colors: [Colors.grey.shade300, Colors.grey.shade400],
                ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: canContinue
              ? [
                  BoxShadow(
                    color: const Color(0xFF00C896).withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppLocalizations.of(context)!.continueText,
                style: TextStyle(
                  color: canContinue ? Colors.white : Colors.grey.shade600,
                  fontSize: isDesktop ? 17 : 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (canContinue) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkipButton() {
    return GestureDetector(
      onTap: _handleSkip,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        child: Text(
          AppLocalizations.of(context)!.skipForNow,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
