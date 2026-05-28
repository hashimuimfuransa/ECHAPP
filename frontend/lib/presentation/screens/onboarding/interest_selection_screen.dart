import 'dart:math' show pi, sin, cos, Random;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/course_provider.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';
import 'package:excellencecoachinghub/utils/category_utils.dart';
import 'package:excellencecoachinghub/config/storage_manager.dart';

final _storageManager = StorageManager();




// ─── Shared design tokens ─────────────────────────────────────────────────────
const _kAccent      = Color(0xFF10B981);
const _kAccentLight = Color(0xFF34D399);

// ─── Animated floating background (reused from auth screens) ─────────────────
class _FloatingBg extends StatefulWidget {
  const _FloatingBg();
  @override
  State<_FloatingBg> createState() => _FloatingBgState();
}

class _FloatingBgState extends State<_FloatingBg> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final List<Offset> _particles = List.generate(12, (_) => Offset(Random().nextDouble(), Random().nextDouble()));
  final List<double> _sizes = List.generate(12, (_) => Random().nextDouble() * 36 + 8);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 15))..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;
        return Stack(children: [
          Positioned(
            top: -100 + 30 * sin(t * 2 * pi),
            right: -100 + 20 * cos(t * 2 * pi),
            child: _blob(size: 400, color: _kAccent.withOpacity(0.07), blur: 70),
          ),
          Positioned(
            bottom: 80 + 40 * cos(t * 2 * pi + 1),
            left: -120 + 30 * sin(t * 2 * pi + 1),
            child: _blob(size: 300, color: _kAccentLight.withOpacity(0.05), blur: 55),
          ),
          ...List.generate(_particles.length, (i) {
            final p = _particles[i];
            final y = (p.dy + t * 0.08 * (i % 3 + 1)) % 1.0;
            return Positioned(
              left: MediaQuery.of(context).size.width * p.dx,
              top: MediaQuery.of(context).size.height * y,
              child: Opacity(
                opacity: 0.12 + 0.08 * sin(t * 2 * pi + i),
                child: Container(
                  width: _sizes[i], height: _sizes[i],
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      Colors.white.withOpacity(0.4),
                      Colors.white.withOpacity(0.0),
                    ]),
                  ),
                ),
              ),
            );
          }),
        ]);
      },
    );
  }

  Widget _blob({required double size, required Color color, required double blur}) =>
      Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color, blurRadius: blur, spreadRadius: blur / 2)],
        ),
      );
}

class InterestSelectionScreen extends ConsumerStatefulWidget {
  const InterestSelectionScreen({super.key});

  @override
  _InterestSelectionScreenState createState() => _InterestSelectionScreenState();
}

class _InterestSelectionScreenState extends ConsumerState<InterestSelectionScreen> {
  final Set<String> _selectedInterests = {};

  // Theme-aware getters
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _cardColor => _isDark ? const Color(0xFF1E293B) : Colors.white.withOpacity(0.95);
  Color get _textColor => _isDark ? Colors.white : const Color(0xFF1A2433);
  Color get _secondaryTextColor => _isDark ? Colors.white70 : const Color(0xFF4A5568);
  Color get _interestCardBg => _isDark ? const Color(0xFF0F172A) : Colors.grey.shade50;
  Color get _interestCardBorder => _isDark ? const Color(0xFF334155) : Colors.grey.shade200;
  Color get _selectedInterestBg => _isDark ? const Color(0xFF10B981).withOpacity(0.2) : const Color(0xFFECFDF5);

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    // Guard: Only enforce when auth has finished restoring state.
    // `AuthNotifier` can briefly have a stale user (restored session) while storage/Firebase sync runs.
    final authState = ref.watch(authProvider);

    // Only require that user is authenticated; onboarding is typically reached
    // as part of the backend registration/onboarding flow.
    // This avoids relying on local storage flags during login/navigation.
    if (authState.user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/auth-selection');
        }
      });
      return const SizedBox.shrink();
    }


    if (isDesktop) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/onboading desktop.png'),
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
                  const Color(0xFF0F172A).withOpacity(0.5),
                  const Color(0xFF1E293B).withOpacity(0.7),
                  const Color(0xFF0F172A).withOpacity(0.9),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(child: _buildDesktopLayout()),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/onboardign mobile.png'),
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
            child: _buildMobileLayout(),
          ),
        ),
      ),
    );
  }

  // ─── Desktop layout ─────────────────────────────────────────────────────────
  Widget _buildDesktopLayout() {
    return Center(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 820),
        margin: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 40),
          ],
        ),
        child: Column(
          children: [
            // Header band
            Container(
              padding: const EdgeInsets.fromLTRB(32, 28, 32, 24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.15))),
              ),
              child: _buildHeaderContent(dark: false),
            ),
            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildInterestsGrid(dark: false),
                    const SizedBox(height: 32),
                    _buildButtons(dark: false),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Mobile layout ───────────────────────────────────────────────────────────
  Widget _buildMobileLayout() {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmall = screenHeight < 680;
    return Column(
      children: [
        // Green top section
        Padding(
          padding: EdgeInsets.fromLTRB(20, isSmall ? 8 : 12, 20, isSmall ? 12 : 20),
          child: Column(
            children: [
              Row(children: [
                if (context.canPop())
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                const Spacer(),
                _buildStepChip(),
              ]),
              SizedBox(height: isSmall ? 8 : 16),
              _buildHeaderContent(dark: false),
            ],
          ),
        ),
        // Card sliding up
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildInterestsGrid(dark: _isDark),
                  const SizedBox(height: 28),
                  _buildButtons(dark: _isDark),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: const Text(
        'Step 1 of 2',
        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildHeaderContent({required bool dark}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: dark ? _kAccent.withOpacity(0.12) : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: dark ? _kAccent.withOpacity(0.3) : Colors.white.withOpacity(0.3),
                ),
              ),
              child: Icon(
                Icons.interests_rounded,
                color: dark ? _kAccent : Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'What are you interested in?',
                style: TextStyle(
                  color: dark ? const Color(0xFF1A2433) : Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Pick the coaching areas you want to focus on. You can always change them later.',
          style: TextStyle(
            color: dark ? const Color(0xFF4A5568) : Colors.white.withOpacity(0.8),
            fontSize: 13,
            height: 1.5,
          ),
        ),
        if (_selectedInterests.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: dark ? _kAccent.withOpacity(0.1) : Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: dark ? _kAccent.withOpacity(0.3) : Colors.white.withOpacity(0.3),
              ),
            ),
            child: Text(
              '${_selectedInterests.length} selected',
              style: TextStyle(
                color: dark ? _kAccent : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInterestsGrid({required bool dark}) {
    final categoriesAsync = ref.watch(backendCategoriesProvider);

    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return Center(
            child: Column(
              children: [
                Icon(Icons.category_outlined, color: dark ? Colors.grey.shade600 : Colors.white38, size: 40),
                const SizedBox(height: 12),
                Text('No categories available',
                    style: TextStyle(color: dark ? Colors.grey.shade500 : Colors.white54, fontSize: 14)),
              ],
            ),
          );
        }

        return Wrap(
          spacing: 10,
          runSpacing: 10,
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
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                decoration: BoxDecoration(
                  color: isSelected ? color : (dark ? _interestCardBg : Colors.white.withOpacity(0.08)),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: isSelected ? color : (dark ? _interestCardBorder : Colors.white.withOpacity(0.2)),
                    width: isSelected ? 1.8 : 1.2,
                  ),
                  boxShadow: isSelected && !dark
                      ? [BoxShadow(color: color.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected ? Icons.check_circle_rounded : CategoryUtils.getCategoryIcon(category.id, name: category.name),
                      color: isSelected ? Colors.white : (dark ? color : Colors.white70),
                      size: 15,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      interest,
                      style: TextStyle(
                        color: isSelected ? Colors.white : (dark ? _secondaryTextColor : Colors.white70),
                        fontSize: 13.5,
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
      loading: () => Center(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const SizedBox(
              width: 36, height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(_kAccent),
              ),
            ),
            const SizedBox(height: 12),
            Text('Loading categories...', style: TextStyle(color: dark ? Colors.grey.shade400 : Colors.white54, fontSize: 13)),
            const SizedBox(height: 20),
          ],
        ),
      ),
      error: (_, __) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF450A0A) : Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: dark ? const Color(0xFF7F1D1D) : Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: dark ? const Color(0xFFFCA5A5) : Colors.red.shade400, size: 20),
            const SizedBox(width: 10),
            Text('Failed to load categories', style: TextStyle(color: dark ? const Color(0xFFFCA5A5) : Colors.red.shade600, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildButtons({required bool dark}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Continue button
        GestureDetector(
          onTap: _selectedInterests.isEmpty ? null : _handleContinue,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 54,
            decoration: BoxDecoration(
              gradient: _selectedInterests.isEmpty
                  ? LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade300])
                  : const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: _selectedInterests.isEmpty
                  ? []
                  : [BoxShadow(color: _kAccent.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Continue',
                  style: TextStyle(
                    color: _selectedInterests.isEmpty ? Colors.grey.shade500 : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: _selectedInterests.isEmpty ? Colors.grey.shade500 : Colors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Skip button
        GestureDetector(
          onTap: _handleSkip,
          child: Container(
            height: 48,
            alignment: Alignment.center,
            child: Text(
              'Skip for now',
              style: TextStyle(
                color: dark ? const Color(0xFF6B7280) : Colors.white60,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
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
