import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellence_coaching_hub/config/app_theme.dart';

class StudentLearningScreen extends ConsumerWidget {
  final String courseId;

  const StudentLearningScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Path'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openEndDrawer(),
          ),
        ],
      ),
      endDrawer: _buildCourseOutline(context),
      body: _buildLearningContent(context),
    );
  }

  Widget _buildLearningContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course Header
          _buildCourseHeader(),
          
          const SizedBox(height: 30),
          
          // Daily Learning Choice
          _buildDailyChoice(context),
          
          const SizedBox(height: 30),
          
          // Progress Overview
          _buildProgressOverview(),
          
          const SizedBox(height: 30),
          
          // Current Section
          _buildCurrentSection(context),
        ],
      ),
    );
  }

  Widget _buildCourseHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.school,
              color: AppTheme.primaryGreen,
              size: 30,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mathematics Advanced',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.blackColor,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Master advanced mathematical concepts',
                  style: TextStyle(
                    color: AppTheme.greyColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: 0.65,
                  backgroundColor: AppTheme.borderGrey,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                ),
                const SizedBox(height: 5),
                const Text(
                  '65% Complete',
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyChoice(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What would you like to learn today?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.blackColor,
          ),
        ),
        const SizedBox(height: 15),
        const Text(
          'Choose your preferred learning method',
          style: TextStyle(
            color: AppTheme.greyColor,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildLearningOption(
                context,
                'Watch Video',
                'Visual learning with expert instructors',
                Icons.video_library,
                AppTheme.primaryGreen,
                () => _startVideoLearning(context),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildLearningOption(
                context,
                'Read Notes',
                'Detailed written explanations',
                Icons.description,
                AppTheme.accent,
                () => _startNotesLearning(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        _buildLearningOption(
          context,
          'Take Practice Exam',
          'Test your knowledge with quizzes',
          Icons.quiz,
          Colors.orange,
          () => _startExam(context),
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildLearningOption(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool isFullWidth = false,
  }) {
    Widget content = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.blackColor,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppTheme.greyColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );

    if (isFullWidth) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: content,
    );
  }

  Widget _buildProgressOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.blackColor,
            ),
          ),
          const SizedBox(height: 20),
          _buildProgressItem('Completed Lessons', '24/36', 0.67, AppTheme.primaryGreen),
          const SizedBox(height: 15),
          _buildProgressItem('Video Watched', '18/24', 0.75, AppTheme.accent),
          const SizedBox(height: 15),
          _buildProgressItem('Notes Read', '12/18', 0.67, Colors.orange),
          const SizedBox(height: 15),
          _buildProgressItem('Exams Taken', '3/5', 0.60, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildProgressItem(String title, String value, double progress, Color color) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppTheme.blackColor,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 15),
        SizedBox(
          width: 100,
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.borderGrey,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Current Section',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.blackColor,
          ),
        ),
        const SizedBox(height: 15),
        _buildSectionCard(context),
      ],
    );
  }

  Widget _buildSectionCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                child: const Icon(
                  Icons.numbers,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 15),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Section 3: Calculus Basics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.blackColor,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      '5 lessons • 2 hours 15 mins',
                      style: TextStyle(
                        color: AppTheme.greyColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Upcoming Lessons',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.blackColor,
            ),
          ),
          const SizedBox(height: 15),
          _buildLessonItem('Limits and Continuity', 'video', 35, true),
          const SizedBox(height: 10),
          _buildLessonItem('Derivatives Introduction', 'video', 40, false),
          const SizedBox(height: 10),
          _buildLessonItem('Calculus Formula Sheet', 'notes', 5, false),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push('/learning/${courseId}/section/3'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continue Learning',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonItem(String title, String type, int duration, bool isNext) {
    IconData getIconForType(String type) {
      switch (type) {
        case 'video': return Icons.video_library;
        case 'notes': return Icons.description;
        default: return Icons.article;
      }
    }

    Color getColorForType(String type) {
      switch (type) {
        case 'video': return AppTheme.primaryGreen;
        case 'notes': return AppTheme.accent;
        default: return AppTheme.greyColor;
      }
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isNext ? AppTheme.primaryGreen.withOpacity(0.1) : AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isNext ? AppTheme.primaryGreen : AppTheme.borderGrey,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: getColorForType(type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              getIconForType(type),
              color: getColorForType(type),
              size: 20,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isNext ? AppTheme.primaryGreen : AppTheme.blackColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${duration} mins • ${type.capitalize()}',
                  style: const TextStyle(
                    color: AppTheme.greyColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (isNext)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Text(
                'Next',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCourseOutline(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppTheme.primaryGreen,
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Course Outline',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Mathematics Advanced',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Sections and lessons would be listed here
          const ListTile(
            leading: Icon(Icons.numbers),
            title: Text('Section 1: Introduction'),
            subtitle: Text('3 lessons'),
          ),
          const ListTile(
            leading: Icon(Icons.numbers),
            title: Text('Section 2: Algebra Fundamentals'),
            subtitle: Text('3 lessons'),
          ),
          const ListTile(
            leading: Icon(Icons.numbers, color: AppTheme.primaryGreen),
            title: Text('Section 3: Calculus Basics', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('3 lessons • Current'),
          ),
          const ListTile(
            leading: Icon(Icons.numbers),
            title: Text('Section 4: Advanced Topics'),
            subtitle: Text('3 lessons'),
          ),
        ],
      ),
    );
  }

  void _startVideoLearning(BuildContext context) {
    context.push('/learning/${courseId}/video');
  }

  void _startNotesLearning(BuildContext context) {
    context.push('/learning/${courseId}/notes');
  }

  void _startExam(BuildContext context) {
    context.push('/learning/${courseId}/exam');
  }
}

// Extension to capitalize first letter
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}