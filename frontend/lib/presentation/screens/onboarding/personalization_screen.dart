import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
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

  final List<String> _shortTermOptions = [
    'Improve my skills',
    'Learn something new',
    'Complete a project',
    'Prepare for interview',
    'Get certified',
  ];

  final List<String> _midTermOptions = [
    'Get certified',
    'Career growth',
    'Start a business',
    'Switch careers',
    'Build portfolio',
  ];

  final List<String> _longTermOptions = [
    'Career growth',
    'Become an expert',
    'Leadership role',
    'Start a company',
    'Financial freedom',
  ];

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
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Let\'s personalize your experience',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'What are your learning goals?',
          style: TextStyle(
            color: Colors.white60,
            fontSize: 16,
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
      await ref.read(authProvider.notifier).updateProfile(
        shortTermGoal: _shortTermGoal,
        midTermGoal: _midTermGoal,
        longTermGoal: _longTermGoal,
        hasCompletedOnboarding: true,
      );
      if (mounted) {
        context.go('/dashboard');
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
}
