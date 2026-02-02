import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellence_coaching_hub/presentation/widgets/beautiful_widgets.dart';
import 'package:excellence_coaching_hub/config/app_theme.dart';
import 'package:excellence_coaching_hub/data/models/course.dart';
import 'package:excellence_coaching_hub/data/repositories/course_repository.dart';

class CourseDetailScreen extends ConsumerWidget {
  final String courseId;

  const CourseDetailScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseAsync = ref.watch(FutureProvider<Course>((ref) async {
      final repository = CourseRepository();
      return await repository.getCourseById(courseId);
    }));

    return courseAsync.when(
      data: (course) {
        return Scaffold(
          body: GradientBackground(
            colors: AppTheme.oceanGradient,
            child: CustomScrollView(
              slivers: [
                // Header with back button
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.bookmark_border, color: Colors.white),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_outlined, color: Colors.white),
                      onPressed: () {},
                    ),
                  ],
                  expandedHeight: 300,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Course Image
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.greyColor.withOpacity(0.1),
                          ),
                          child: const Icon(
                            Icons.play_circle_outline,
                            color: AppTheme.greyColor,
                            size: 100,
                          ),
                        ),
                        // Gradient overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                        // Course Info Overlay
                        Positioned(
                          bottom: 20,
                          left: 20,
                          right: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                course.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'by ${course.createdBy.fullName}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Content
                SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Price and Actions
                          _buildPriceSection(course),
                          
                          const SizedBox(height: 25),
                          
                          // Course Stats
                          _buildCourseStats(course),
                          
                          const SizedBox(height: 25),
                          
                          // Description
                          _buildDescription(course),
                          
                          const SizedBox(height: 25),
                          
                          // Curriculum Preview
                          _buildCurriculumPreview(),
                          
                          const SizedBox(height: 25),
                          
                          // Instructor Info
                          _buildInstructorInfo(course),
                          
                          const SizedBox(height: 30),
                          
                          // Enroll Button
                          _buildEnrollButton(context, course),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: GradientBackground(
          colors: AppTheme.oceanGradient,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: GradientBackground(
          colors: AppTheme.oceanGradient,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 60,
                ),
                const SizedBox(height: 20),
                Text(
                  'Error loading course: $error',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // Refresh by rebuilding the widget
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => CourseDetailScreen(courseId: courseId),
                      ),
                    );
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceSection(Course course) {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Price',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      course.price == 0 ? 'Free' : '\$${course.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: course.price == 0 ? Colors.green : Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (course.price != 0) ...[
                      const SizedBox(width: 10),
                      Text(
                        '\$${(course.price * 1.2).toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 18,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            // Note: For simplicity, we're not showing enrollment status here
            // In a real app, you'd check if the user is enrolled
            if (course.price == 0)
              AnimatedButton(
                text: 'Enroll Now',
                onPressed: () {
                  // Handle free enrollment
                },
                color: Colors.green,
              )
            else
              AnimatedButton(
                text: 'Buy Now',
                onPressed: () {
                  // Handle paid enrollment
                },
                color: const Color(0xFF4facfe),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseStats(Course course) {
    final stats = [
      {
        'icon': Icons.access_time_outlined,
        'value': '${course.duration} hours',
        'label': 'Duration'
      },
      {
        'icon': Icons.speed_outlined,
        'value': course.level,
        'label': 'Level'
      },
      {
        'icon': Icons.language_outlined,
        'value': 'English',
        'label': 'Language'
      },
      {
        'icon': Icons.verified_outlined,
        'value': 'Certificate',
        'label': 'Included'
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Course Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        Wrap(
          spacing: 15,
          runSpacing: 15,
          children: stats.map((stat) => _buildStatItem(stat)).toList(),
        ),
      ],
    );
  }

  Widget _buildStatItem(Map<String, dynamic> stat) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(stat['icon'], color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            stat['value'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            stat['label'],
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(Course course) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            course.description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurriculumPreview() {
    final curriculum = [
      {'title': 'Introduction to Flutter', 'duration': '15 mins', 'isCompleted': true},
      {'title': 'Setting up Development Environment', 'duration': '25 mins', 'isCompleted': true},
      {'title': 'Dart Basics', 'duration': '45 mins', 'isCompleted': false},
      {'title': 'Widgets and Layouts', 'duration': '1 hour', 'isCompleted': false},
      {'title': 'State Management', 'duration': '1.5 hours', 'isCompleted': false},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Curriculum Preview',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: curriculum.asMap().entries.map((entry) {
              final index = entry.key;
              final lesson = entry.value;
              return _buildLessonItem(index, lesson, index == curriculum.length - 1);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLessonItem(int index, Map<String, dynamic> lesson, bool isLast) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        border: isLast ? null : Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: lesson['isCompleted'] 
                  ? Colors.green.withOpacity(0.3) 
                  : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              lesson['isCompleted'] ? Icons.check : Icons.play_arrow_outlined,
              color: lesson['isCompleted'] ? Colors.green : Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson['title'],
                  style: TextStyle(
                    color: lesson['isCompleted'] ? Colors.white60 : Colors.white,
                    fontSize: 16,
                    fontWeight: lesson['isCompleted'] ? FontWeight.normal : FontWeight.w500,
                  ),
                ),
                Text(
                  lesson['duration'],
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.lock_outline,
            color: lesson['isCompleted'] ? Colors.green : Colors.white54,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildInstructorInfo(Course course) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Instructor',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        GlassContainer(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(
                    course.createdBy.fullName.split(' ').map((n) => n[0]).join('').toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.createdBy.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Senior Flutter Developer • 8 years experience',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnrollButton(BuildContext context, Course course) {
    if (course.price == 0) {
      return AnimatedButton(
        text: 'Enroll for Free',
        onPressed: () {
          // Handle free enrollment
        },
        color: Colors.green,
      );
    } else {
      return AnimatedButton(
        text: 'Buy Course - \$${course.price.toStringAsFixed(0)}',
        onPressed: () {
          // Handle paid enrollment
        },
        color: const Color(0xFF4facfe),
      );
    }
  }
}