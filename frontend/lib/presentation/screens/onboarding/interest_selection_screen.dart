import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/course_provider.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';
import 'package:excellencecoachinghub/utils/category_utils.dart';

class InterestSelectionScreen extends ConsumerStatefulWidget {
  const InterestSelectionScreen({super.key});

  @override
  _InterestSelectionScreenState createState() => _InterestSelectionScreenState();
}

class _InterestSelectionScreenState extends ConsumerState<InterestSelectionScreen> {
  final Set<String> _selectedInterests = {};

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
            _buildInterestsGrid(),
            const SizedBox(height: 40),
            _buildButtons(),
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
          _buildInterestsGrid(),
          const SizedBox(height: 30),
          _buildButtons(),
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
          'What are you interested in?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Select multiple areas you want to learn and grow in.',
          style: TextStyle(
            color: Colors.white60,
            fontSize: 16,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildInterestsGrid() {
    final categoriesAsync = ref.watch(backendCategoriesProvider);
    
    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return const Center(
            child: Text(
              'No categories available',
              style: TextStyle(color: Colors.white60),
            ),
          );
        }
        
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: categories.map((category) {
            final interest = category.name;
            final isSelected = _selectedInterests.contains(interest);
            final color = CategoryUtils.getCategoryColor(category.id, name: category.name);
            
            return InkWell(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedInterests.remove(interest);
                  } else {
                    _selectedInterests.add(interest);
                  }
                });
              },
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color
                      : Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected
                        ? color
                        : Colors.white.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CategoryUtils.getCategoryIcon(category.id, name: category.name),
                      color: isSelected ? Colors.white : color,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      interest,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF00C896)),
      ),
      error: (_, __) => const Center(
        child: Text(
          'Failed to load categories',
          style: TextStyle(color: Colors.white60),
        ),
      ),
    );
  }

  Widget _buildButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
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
              onTap: _selectedInterests.isEmpty ? null : _handleContinue,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: const Text(
                  'Continue',
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
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _handleSkip,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: const Text(
            'Skip for now',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 15,
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
