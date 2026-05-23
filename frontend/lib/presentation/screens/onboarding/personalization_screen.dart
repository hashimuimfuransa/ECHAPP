import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/course_provider.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';

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
            ],
          ),
        ),
        child: SafeArea(
          child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Center(
      child: Container(
        width: 600,
        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 40),
            _buildGoalDropdowns(),
            const SizedBox(height: 40),
            _buildSaveButton(),
            if (!_isUpdating) ...[
              const SizedBox(height: 16),
              _buildSkipButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          _buildHeader(),
          const SizedBox(height: 30),
          _buildGoalDropdowns(),
          const SizedBox(height: 30),
          _buildSaveButton(),
          if (!_isUpdating) ...[
            const SizedBox(height: 16),
            _buildSkipButton(),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF00C896).withOpacity(0.2),
                const Color(0xFF009E76).withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00C896), Color(0xFF009E76)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _isUpdating ? Icons.edit_rounded : Icons.rocket_launch_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isUpdating ? 'Update Your Goals' : 'Customize Your Journey',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isUpdating 
                          ? 'Adjust your learning goals anytime'
                          : 'Set your goals to get personalized recommendations',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _isUpdating ? 'Update your learning goals' : 'What are your learning goals?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isUpdating 
              ? 'Modify your goals below to improve recommendations'
              : 'Select your goals below or skip to set them later',
          style: TextStyle(
            color: Colors.white60,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalDropdowns() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDropdown(
          label: 'Short Term Goal',
          value: _shortTermGoal,
          options: _shortTermOptions,
          onChanged: (value) {
            setState(() {
              _shortTermGoal = value;
            });
          },
        ),
        const SizedBox(height: 20),
        _buildDropdown(
          label: 'Mid Term Goal',
          value: _midTermGoal,
          options: _midTermOptions,
          onChanged: (value) {
            setState(() {
              _midTermGoal = value;
            });
          },
        ),
        const SizedBox(height: 20),
        _buildDropdown(
          label: 'Long Term Goal',
          value: _longTermGoal,
          options: _longTermOptions,
          onChanged: (value) {
            setState(() {
              _longTermGoal = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text(
                'Select $label',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 15,
                ),
              ),
              dropdownColor: const Color(0xFF1E293B),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white.withOpacity(0.6),
              ),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
              ),
              items: options.map((String option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
              onChanged: onChanged,
              selectedItemBuilder: (BuildContext context) {
                return options.map<Widget>((String option) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      option,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00C896), Color(0xFF009E76)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00C896).withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: InkWell(
          onTap: _handleSaveAndContinue,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: const Text(
              'Save & Continue',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
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

  Widget _buildSkipButton() {
    return TextButton(
      onPressed: _handleSkip,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.skip_next_rounded,
            color: Colors.white60,
            size: 18,
          ),
          const SizedBox(width: 8),
          const Text(
            'Skip for now',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
