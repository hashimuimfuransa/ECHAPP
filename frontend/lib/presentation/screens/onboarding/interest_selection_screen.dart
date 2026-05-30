import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/course_provider.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';
import 'package:excellencecoachinghub/utils/category_utils.dart';
import 'package:excellencecoachinghub/config/storage_manager.dart';
import 'package:excellencecoachinghub/presentation/widgets/desktop_brand_panel.dart';
import 'package:excellencecoachinghub/l10n/app_localizations.dart';

final _storageManager = StorageManager();

// ─── Shared design tokens ─────────────────────────────────────────────────────
const _kAccent      = Color(0xFF10B981);
const _kAccentDark  = Color(0xFF059669);

class InterestSelectionScreen extends ConsumerStatefulWidget {
  final bool isEditMode;

  const InterestSelectionScreen({super.key, this.isEditMode = false});

  @override
  _InterestSelectionScreenState createState() => _InterestSelectionScreenState();
}

class _InterestSelectionScreenState extends ConsumerState<InterestSelectionScreen> {
  final Set<String> _selectedInterests = {};
  bool _interestsInitialized = false;

  // ─── Theme-aware color tokens ────────────────────────────────────────────────
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _scaffoldBg => _isDark ? const Color(0xFF0F1419) : const Color(0xFFF8FAFB);
  Color get _cardBg     => _isDark ? const Color(0xFF1A202C) : Colors.white;
  Color get _surfaceBg  => _isDark ? const Color(0xFF1E2733) : const Color(0xFFF1F5F9);
  Color get _borderColor => _isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0);

  Color get _textPrimary    => _isDark ? const Color(0xFFE2E8F0) : const Color(0xFF111827);
  Color get _textSecondary  => _isDark ? const Color(0xFFA0AEC0) : const Color(0xFF6B7280);
  Color get _textMuted      => _isDark ? const Color(0xFF718096) : const Color(0xFF9CA3AF);

  Color get _chipUnselectedBg     => _isDark ? const Color(0xFF232D3C) : const Color(0xFFF8FAFC);
  Color get _chipUnselectedBorder => _isDark ? const Color(0xFF374151) : const Color(0xFFD1D5DB);

  Color get _continueBtnDisabledBg   => _isDark ? const Color(0xFF2D3748) : const Color(0xFFE5E7EB);
  Color get _continueBtnDisabledText => _isDark ? const Color(0xFF4B5563) : const Color(0xFF9CA3AF);

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final l10n = AppLocalizations.of(context);

    final authState = ref.watch(authProvider);

    if (authState.user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/auth-selection');
      });
      return const SizedBox.shrink();
    }

    // If user already completed onboarding and NOT in edit mode, skip straight to dashboard
    if (authState.user!.hasCompletedOnboarding && !widget.isEditMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/dashboard');
      });
      return const SizedBox.shrink();
    }

    // Pre-populate with previously saved interests (skip + come back, or edit)
    if (!_interestsInitialized) {
      final savedInterests = authState.user!.interests;
      if (savedInterests != null && savedInterests.isNotEmpty) {
        _selectedInterests.addAll(savedInterests);
      }
      _interestsInitialized = true;
    }

    if (isDesktop) {
      return Scaffold(
        backgroundColor: _scaffoldBg,
        body: _buildDesktopLayout(l10n),
      );
    }

    return Scaffold(
      backgroundColor: _scaffoldBg,
      body: SafeArea(
        child: _buildMobileLayout(l10n),
      ),
    );
  }

  // ─── Desktop layout ─────────────────────────────────────────────────────────
  Widget _buildDesktopLayout(AppLocalizations? l10n) {
    return Row(
      children: [
        // Left branding panel (42%)
        const Expanded(
          flex: 42,
          child: DesktopBrandPanel(
            headline: 'Personalize Your',
            title: 'Learning\nJourney',
            tagline: 'Choose the topics that matter\nmost to you.',
          ),
        ),
        // Right content panel (58%)
        Expanded(
          flex: 58,
          child: Container(
            color: _scaffoldBg,
            child: Column(
              children: [
                // Top header bar
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    border: Border(
                      bottom: BorderSide(color: _borderColor, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: _kAccent.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _kAccent.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.tune_rounded, color: _kAccent, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              '${l10n?.step ?? 'Step'} 1 ${l10n?.ofText ?? 'of'} 2',
                              style: const TextStyle(
                                color: _kAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Excellence Coaching Hub',
                        style: TextStyle(
                          color: _textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 40),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildPageHeading(l10n),
                          const SizedBox(height: 28),
                          _buildInterestsCard(l10n),
                          const SizedBox(height: 28),
                          _buildButtons(l10n),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Mobile layout ───────────────────────────────────────────────────────────
  Widget _buildMobileLayout(AppLocalizations? l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top navigation bar
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
          child: Row(
            children: [
              if (context.canPop())
                IconButton(
                  onPressed: () => context.pop(),
                  icon: Icon(Icons.arrow_back_ios_new_rounded, color: _textSecondary, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              const Spacer(),
              _buildStepBadge(l10n),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Header section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: _buildPageHeading(l10n),
        ),
        const SizedBox(height: 24),
        // Scrollable interests + buttons
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 4, 22, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInterestsCard(l10n),
                const SizedBox(height: 24),
                _buildButtons(l10n),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Shared sub-widgets ──────────────────────────────────────────────────────

  Widget _buildStepBadge(AppLocalizations? l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: _kAccent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kAccent.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.tune_rounded, color: _kAccent, size: 13),
          const SizedBox(width: 5),
          Text(
            '${l10n?.step ?? 'Step'} 1 ${l10n?.ofText ?? 'of'} 2',
            style: const TextStyle(color: _kAccent, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeading(AppLocalizations? l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon + title row
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_kAccent, _kAccentDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.interests_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                l10n?.onboardingInterestTitle ?? 'What are you\ninterested in?',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          l10n?.onboardingInterestSubtitle ?? 'Pick the coaching areas you want to focus on. You can always change them later.',
          style: TextStyle(
            color: _textSecondary,
            fontSize: 13.5,
            height: 1.55,
          ),
        ),
        if (_selectedInterests.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _kAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kAccent.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: _kAccent, size: 13),
                    const SizedBox(width: 5),
                    Text(
                      '${_selectedInterests.length} ${l10n?.selected ?? 'selected'}',
                      style: const TextStyle(
                        color: _kAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildInterestsCard(AppLocalizations? l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDark ? 0.25 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _buildInterestsGrid(l10n),
    );
  }

  Widget _buildInterestsGrid(AppLocalizations? l10n) {
    final categoriesAsync = ref.watch(backendCategoriesProvider);

    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.category_outlined, color: _textMuted, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    l10n?.noCategoriesAvailable ?? 'No categories available',
                    style: TextStyle(color: _textSecondary, fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }

        return Wrap(
          spacing: 9,
          runSpacing: 9,
          children: categories.map((category) {
            final interest = category.name;
            final isSelected = _selectedInterests.contains(interest);
            final color = CategoryUtils.getCategoryColor(category.id, name: category.name);

            return GestureDetector(
              onTap: () => setState(() {
                isSelected
                    ? _selectedInterests.remove(interest)
                    : _selectedInterests.add(interest);
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(_isDark ? 0.22 : 0.12)
                      : _chipUnselectedBg,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: isSelected ? color : _chipUnselectedBorder,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: color.withOpacity(0.18), blurRadius: 8, offset: const Offset(0, 2))]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 160),
                      child: Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : CategoryUtils.getCategoryIcon(category.id, name: category.name),
                        key: ValueKey(isSelected),
                        color: isSelected ? color : _textMuted,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      interest,
                      style: TextStyle(
                        color: isSelected ? (_isDark ? color.withOpacity(0.9) : color.withOpacity(0.85)) : _textSecondary,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Column(
            children: [
              const SizedBox(
                width: 32, height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(_kAccent),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                l10n?.loading ?? 'Loading...',
                style: TextStyle(color: _textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
      error: (_, __) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isDark ? const Color(0xFF2D1515) : const Color(0xFFFFF5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isDark ? const Color(0xFF7F1D1D).withOpacity(0.6) : const Color(0xFFFECACA),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: _isDark ? const Color(0xFFFCA5A5) : const Color(0xFFEF4444),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n?.failedToLoadCategories ?? 'Failed to load categories',
                style: TextStyle(
                  color: _isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtons(AppLocalizations? l10n) {
    final hasSelection = _selectedInterests.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Continue button
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: 52,
          decoration: BoxDecoration(
            gradient: hasSelection
                ? const LinearGradient(
                    colors: [_kAccent, _kAccentDark],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: hasSelection ? null : _continueBtnDisabledBg,
            borderRadius: BorderRadius.circular(13),
            boxShadow: hasSelection
                ? [BoxShadow(color: _kAccent.withOpacity(0.28), blurRadius: 14, offset: const Offset(0, 4))]
                : [],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: hasSelection ? _handleContinue : null,
              borderRadius: BorderRadius.circular(13),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n?.continueText ?? 'Continue',
                    style: TextStyle(
                      color: hasSelection ? Colors.white : _continueBtnDisabledText,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: hasSelection ? Colors.white : _continueBtnDisabledText,
                    size: 17,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Skip button
        TextButton(
          onPressed: _handleSkip,
          style: TextButton.styleFrom(
            foregroundColor: _textMuted,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          ),
          child: Text(
            l10n?.skipForNow ?? 'Skip for now',
            style: TextStyle(
              color: _textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  void _handleContinue() async {
    // Store selected interests and check phone number
    try {
      await ref.read(authProvider.notifier).updateProfile(
        interests: _selectedInterests.toList(),
      );
      
      if (mounted) {
        // In edit mode, just go back to previous screen
        if (widget.isEditMode) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/dashboard');
          }
          return;
        }

        final authState = ref.read(authProvider);
        final user = authState.user;

        // Check if user has phone number
        if (user?.phone == null || user!.phone!.trim().isEmpty) {
          // Navigate to phone collection screen
          context.push('/phone-collection');
        } else {
          // Complete onboarding and go to dashboard
          await _completeOnboarding();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving interests: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleSkip() async {
    // Skip interests and check phone number
    if (mounted) {
      // In edit mode, just go back to previous screen
      if (widget.isEditMode) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/dashboard');
        }
        return;
      }

      final authState = ref.read(authProvider);
      final user = authState.user;
      
      // Check if user has phone number
      if (user?.phone == null || user!.phone!.trim().isEmpty) {
        // Navigate to phone collection screen
        context.push('/phone-collection');
      } else {
        // Complete onboarding and go to dashboard
        await _completeOnboarding();
      }
    }
  }

  Future<void> _completeOnboarding() async {
    try {
      await ref.read(authProvider.notifier).updateProfile(
        hasCompletedOnboarding: true,
      );

      // Ensure local flag is persisted so the user is not routed back to onboarding
      await _storageManager.saveHasCompletedOnboarding(true);

      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing onboarding: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
