import 'dart:math' show pi, sin, cos, Random;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/course_provider.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _pAccent      = Color(0xFF10B981);
const _pAccentLight = Color(0xFF34D399);
const _pAccentDark  = Color(0xFF059669);

// ─── Floating background ──────────────────────────────────────────────────────
class _FloatingBg extends StatefulWidget {
  const _FloatingBg();
  @override
  State<_FloatingBg> createState() => _FloatingBgState();
}

class _FloatingBgState extends State<_FloatingBg> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final List<Offset> _pts = List.generate(12, (_) => Offset(Random().nextDouble(), Random().nextDouble()));
  final List<double> _sz  = List.generate(12, (_) => Random().nextDouble() * 34 + 8);

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
      builder: (ctx, _) {
        final t = _ctrl.value;
        return Stack(children: [
          Positioned(
            top: -100 + 30 * sin(t * 2 * pi),
            right: -100 + 20 * cos(t * 2 * pi),
            child: _glow(400, _pAccent.withOpacity(0.07), 70),
          ),
          Positioned(
            bottom: 80 + 40 * cos(t * 2 * pi + 1),
            left: -120 + 30 * sin(t * 2 * pi + 1),
            child: _glow(300, _pAccentLight.withOpacity(0.05), 55),
          ),
          ...List.generate(_pts.length, (i) {
            final p = _pts[i];
            final y = (p.dy + t * 0.08 * (i % 3 + 1)) % 1.0;
            return Positioned(
              left: MediaQuery.of(ctx).size.width * p.dx,
              top: MediaQuery.of(ctx).size.height * y,
              child: Opacity(
                opacity: 0.12 + 0.08 * sin(t * 2 * pi + i),
                child: Container(
                  width: _sz[i], height: _sz[i],
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

  Widget _glow(double size, Color color, double blur) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: color, blurRadius: blur, spreadRadius: blur / 2)],
    ),
  );
}

class PersonalizationScreen extends ConsumerStatefulWidget {
  const PersonalizationScreen({super.key});

  @override
  _PersonalizationScreenState createState() => _PersonalizationScreenState();
}

class _PersonalizationScreenState extends ConsumerState<PersonalizationScreen> {
  String? _shortTermGoal;
  String? _midTermGoal;
  String? _longTermGoal;
  bool _isUpdating = false;

  // Base options that are always available
  final List<String> _baseShortTermOptions = [
    'Improve my skills',
    'Learn something new',
    'Complete a project',
    'Prepare for interview',
    'Get certified',
  ];

  final List<String> _baseMidTermOptions = [
    'Get certified',
    'Career growth',
    'Start a business',
    'Switch careers',
    'Build portfolio',
  ];

  final List<String> _baseLongTermOptions = [
    'Career growth',
    'Become an expert',
    'Leadership role',
    'Start a company',
    'Financial freedom',
  ];

  // Dynamic options based on user interests
  List<String> _shortTermOptions = [];
  List<String> _midTermOptions = [];
  List<String> _longTermOptions = [];

  @override
  void initState() {
    super.initState();
    _loadExistingGoals();
    _loadPersonalizedOptions();
  }

  void _loadExistingGoals() {
    final user = ref.read(authProvider).user;
    if (user != null) {
      setState(() {
        _shortTermGoal = user.shortTermGoal;
        _midTermGoal = user.midTermGoal;
        _longTermGoal = user.longTermGoal;
        _isUpdating = user.hasCompletedOnboarding ?? false;
      });
    }
  }

  Future<void> _loadPersonalizedOptions() async {
    final user = ref.read(authProvider).user;
    final userInterests = user?.interests ?? [];
    
    // Start with base options
    _shortTermOptions = List.from(_baseShortTermOptions);
    _midTermOptions = List.from(_baseMidTermOptions);
    _longTermOptions = List.from(_baseLongTermOptions);

    // Add personalized options based on user interests
    if (userInterests.isNotEmpty) {
      final coursesAsync = ref.read(coursesProvider);
      coursesAsync.when(
        data: (courses) {
          // Filter courses by user interests
          final relevantCourses = courses.where((course) {
            if (course.categoryId == null) return false;
            // Check if course category matches user interests
            return userInterests.any((interest) => 
              interest.toLowerCase().contains(course.categoryId!.toLowerCase()) ||
              course.title?.toLowerCase().contains(interest.toLowerCase()) == true
            );
          }).toList();

          // Extract themes from course titles
          final themes = _extractThemesFromCourses(relevantCourses);
          
          setState(() {
            // Add interest-specific options
            if (userInterests.contains('Programming') || userInterests.contains('Data Science')) {
              _shortTermOptions.addAll(['Master a programming language', 'Build a web application']);
              _midTermOptions.addAll(['Become a software engineer', 'Contribute to open source']);
              _longTermOptions.addAll(['Lead development team', 'Build tech startup']);
            }
            if (userInterests.contains('Design')) {
              _shortTermOptions.addAll(['Learn design tools', 'Create a portfolio']);
              _midTermOptions.addAll(['Become a UI/UX designer', 'Work on real projects']);
              _longTermOptions.addAll(['Lead design team', 'Start design agency']);
            }
            if (userInterests.contains('Business') || userInterests.contains('Marketing')) {
              _shortTermOptions.addAll(['Learn marketing basics', 'Launch a campaign']);
              _midTermOptions.addAll(['Grow business revenue', 'Build brand awareness']);
              _longTermOptions.addAll(['Scale business operations', 'Become industry leader']);
            }
            if (userInterests.contains('Artificial Intelligence')) {
              _shortTermOptions.addAll(['Learn ML basics', 'Build AI model']);
              _midTermOptions.addAll(['Become AI engineer', 'Deploy ML systems']);
              _longTermOptions.addAll(['Lead AI research', 'Build AI company']);
            }
            if (userInterests.contains('Leadership')) {
              _shortTermOptions.addAll(['Improve communication', 'Lead a team']);
              _midTermOptions.addAll(['Management role', 'Strategic planning']);
              _longTermOptions.addAll(['Executive leadership', 'Board position']);
            }
            if (userInterests.contains('Personal Development') || userInterests.any((i) => i.toLowerCase().contains('job') || i.toLowerCase().contains('exam') || i.toLowerCase().contains('interview'))) {
              _shortTermOptions.addAll(['Prepare for job exam', 'Improve interview skills', 'Build professional network']);
              _midTermOptions.addAll(['Land dream job', 'Career advancement', 'Professional certification']);
              _longTermOptions.addAll(['Senior management', 'Industry expert', 'Consulting role']);
            }
          });
        },
        loading: () {},
        error: (_, __) {},
      );
    } else {
      setState(() {
        _shortTermOptions = _baseShortTermOptions;
        _midTermOptions = _baseMidTermOptions;
        _longTermOptions = _baseLongTermOptions;
      });
    }
  }

  List<String> _extractThemesFromCourses(List<dynamic> courses) {
    // Extract common themes from course titles and descriptions
    final themes = <String>{};
    for (var course in courses) {
      final title = (course.title ?? '').toLowerCase();
      final description = (course.description ?? '').toLowerCase();
      
      // Common learning themes
      if (title.contains('python') || description.contains('python')) themes.add('Python');
      if (title.contains('javascript') || description.contains('javascript')) themes.add('JavaScript');
      if (title.contains('design') || description.contains('design')) themes.add('Design');
      if (title.contains('business') || description.contains('business')) themes.add('Business');
      if (title.contains('marketing') || description.contains('marketing')) themes.add('Marketing');
      if (title.contains('leadership') || description.contains('leadership')) themes.add('Leadership');
      if (title.contains('ai') || description.contains('artificial intelligence')) themes.add('AI');
      if (title.contains('data') || description.contains('data science')) themes.add('Data Science');
    }
    return themes.toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    if (isDesktop) {
      return Scaffold(
        backgroundColor: const Color(0xFF00C896),
        body: Stack(
          children: [
            const _FloatingBg(),
            SafeArea(child: _buildDesktopLayout()),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF00C896),
      body: SafeArea(
        child: _buildMobileLayout(),
      ),
    );
  }

  // ─── Desktop layout ─────────────────────────────────────────────────────────
  Widget _buildDesktopLayout() {
    return Center(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 840),
        margin: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.09), width: 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 40),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(32, 28, 32, 24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.15))),
              ),
              child: _buildHeaderContent(dark: false),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildGoalDropdowns(dark: false),
                    const SizedBox(height: 32),
                    _buildSaveButton(dark: false),
                    if (!_isUpdating) ...[
                      const SizedBox(height: 14),
                      _buildSkipButton(dark: false),
                    ],
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
                if (!_isUpdating) _buildStepChip(),
              ]),
              const SizedBox(height: 16),
              _buildHeaderContent(dark: false),
            ],
          ),
        ),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildGoalDropdowns(dark: true),
                  const SizedBox(height: 28),
                  _buildSaveButton(dark: true),
                  if (!_isUpdating) ...[
                    const SizedBox(height: 14),
                    _buildSkipButton(dark: true),
                  ],
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
        'Step 2 of 2',
        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildHeaderContent({required bool dark}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: dark ? _pAccent.withOpacity(0.12) : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: dark ? _pAccent.withOpacity(0.3) : Colors.white.withOpacity(0.3),
            ),
          ),
          child: Icon(
            _isUpdating ? Icons.edit_rounded : Icons.rocket_launch_rounded,
            color: dark ? _pAccent : Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isUpdating ? 'Update Your Goals' : 'Set Your Learning Goals',
                style: TextStyle(
                  color: dark ? const Color(0xFF1A2433) : Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _isUpdating
                    ? 'Modify your goals to improve recommendations'
                    : 'Tell us your ambitions and get a personalised path.',
                style: TextStyle(
                  color: dark ? const Color(0xFF4A5568) : Colors.white.withOpacity(0.8),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGoalDropdowns({required bool dark}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildGoalField(
          dark: dark,
          icon: Icons.flash_on_rounded,
          label: 'Short Term Goal',
          hint: 'What do you want to achieve soon?',
          value: _shortTermGoal,
          options: _shortTermOptions,
          color: const Color(0xFF10B981),
          onChanged: (v) => setState(() => _shortTermGoal = v),
        ),
        const SizedBox(height: 18),
        _buildGoalField(
          dark: dark,
          icon: Icons.trending_up_rounded,
          label: 'Mid Term Goal',
          hint: 'Where do you want to be in 1–2 years?',
          value: _midTermGoal,
          options: _midTermOptions,
          color: const Color(0xFF3B82F6),
          onChanged: (v) => setState(() => _midTermGoal = v),
        ),
        const SizedBox(height: 18),
        _buildGoalField(
          dark: dark,
          icon: Icons.flag_rounded,
          label: 'Long Term Goal',
          hint: 'What is your ultimate ambition?',
          value: _longTermGoal,
          options: _longTermOptions,
          color: const Color(0xFF8B5CF6),
          onChanged: (v) => setState(() => _longTermGoal = v),
        ),
      ],
    );
  }

  Widget _buildGoalField({
    required bool dark,
    required IconData icon,
    required String label,
    required String hint,
    required String? value,
    required List<String> options,
    required Color color,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(dark ? 0.1 : 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: dark ? color : Colors.white.withOpacity(0.9), size: 14),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: dark ? const Color(0xFF374151) : Colors.white.withOpacity(0.9),
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 54,
          decoration: BoxDecoration(
            color: dark ? Colors.white : Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: value != null
                  ? (dark ? color.withOpacity(0.5) : color.withOpacity(0.6))
                  : (dark ? const Color(0xFFE2E8F0) : Colors.white.withOpacity(0.12)),
              width: value != null ? 1.8 : 1.2,
            ),
            boxShadow: dark
                ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]
                : [],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: Padding(
                padding: const EdgeInsets.only(left: 14),
                child: Text(
                  hint,
                  style: TextStyle(
                    color: dark ? const Color(0xFF9CA3AF) : Colors.white.withOpacity(0.4),
                    fontSize: 14,
                  ),
                ),
              ),
              dropdownColor: dark ? Colors.white : const Color(0xFF1E2D3D),
              icon: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: value != null ? color : (dark ? const Color(0xFF9CA3AF) : Colors.white38),
                  size: 22,
                ),
              ),
              style: TextStyle(
                color: dark ? const Color(0xFF1A2433) : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              items: options.map((String option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 14),
                    child: Text(option),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
              selectedItemBuilder: (context) => options.map<Widget>((o) => Padding(
                padding: const EdgeInsets.only(left: 14),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    o,
                    style: TextStyle(
                      color: dark ? const Color(0xFF1A2433) : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton({required bool dark}) {
    return GestureDetector(
      onTap: _handleSaveAndContinue,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: _pAccent.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Save & Continue',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  void _handleSaveAndContinue() async {
    // Store goals and navigate to dashboard
    try {
      debugPrint('PersonalizationScreen: Updating profile with hasCompletedOnboarding = true');
      await ref.read(authProvider.notifier).updateProfile(
        shortTermGoal: _shortTermGoal,
        midTermGoal: _midTermGoal,
        longTermGoal: _longTermGoal,
        hasCompletedOnboarding: true,
      );
      
      // Wait for state to propagate
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (mounted) {
        // Verify the state was updated before navigating
        final authState = ref.read(authProvider);
        debugPrint('PersonalizationScreen: After update, hasCompletedOnboarding = ${authState.user?.hasCompletedOnboarding}');
        if (authState.user?.hasCompletedOnboarding == true) {
          if (_isUpdating) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Goals updated successfully!'),
                backgroundColor: Color(0xFF00C896),
              ),
            );
          } else {
            context.go('/dashboard');
          }
        } else {
          // State not updated yet, wait a bit more
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            if (_isUpdating) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Goals updated successfully!'),
                  backgroundColor: Color(0xFF00C896),
                ),
              );
            } else {
              context.go('/dashboard');
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving goals: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleSkip() async {
    // Skip onboarding and mark as completed
    try {
      await ref.read(authProvider.notifier).updateProfile(
        hasCompletedOnboarding: true,
      );
      
      // Wait for state to propagate
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (mounted) {
        // Verify the state was updated before navigating
        final authState = ref.read(authProvider);
        if (authState.user?.hasCompletedOnboarding == true) {
          context.go('/dashboard');
        } else {
          // State not updated yet, wait a bit more
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            context.go('/dashboard');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error skipping: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSkipButton({required bool dark}) {
    return GestureDetector(
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
    );
  }
}
