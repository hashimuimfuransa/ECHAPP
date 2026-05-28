import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellencecoachinghub/models/course.dart';
import 'package:excellencecoachinghub/widgets/enhanced_course_navigation.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';

/// Example implementation of enhanced course card with fast navigation
class EnhancedCourseCard extends ConsumerWidget {
  final Course course;
  final String? heroTag;

  const EnhancedCourseCard({
    super.key,
    required this.course,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: EnhancedCourseNavigation(
        course: course,
        showRipple: true,
        enableHapticFeedback: true,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course image with hero animation
              if (course.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Hero(
                    tag: heroTag ?? 'course_image_${course.id}',
                    child: Image.network(
                      course.imageUrl!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 150,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, size: 50),
                        );
                      },
                    ),
                  ),
                ),
              
              const SizedBox(height: 12),
              
              // Course title
              Text(
                course.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 8),
              
              // Course description
              Text(
                course.description ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 12),
              
              // Course metadata
              Row(
                children: [
                  // Price
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '\$${course.price?.toStringAsFixed(2) ?? '0.00'}',
                      style: const TextStyle(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Duration or lessons count
                  if (course.duration != null)
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          course.duration!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Quick navigation button
              QuickCourseNavButton(
                course: course,
                heroTag: heroTag != null ? '${heroTag}_button' : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grid view of enhanced course cards
class EnhancedCourseGrid extends StatelessWidget {
  final List<Course> courses;
  final String? Function(Course)? getHeroTag;

  const EnhancedCourseGrid({
    super.key,
    required this.courses,
    this.getHeroTag,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        return EnhancedCourseCard(
          course: course,
          heroTag: getHeroTag?.call(course),
        );
      },
    );
  }
}

/// List view of enhanced course cards
class EnhancedCourseList extends StatelessWidget {
  final List<Course> courses;
  final String? Function(Course)? getHeroTag;

  const EnhancedCourseList({
    super.key,
    required this.courses,
    this.getHeroTag,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        return EnhancedCourseCard(
          course: course,
          heroTag: getHeroTag?.call(course),
        );
      },
    );
  }
}

/// Compact course card for horizontal scrolling
class CompactCourseCard extends StatelessWidget {
  final Course course;
  final double width;

  const CompactCourseCard({
    super.key,
    required this.course,
    this.width = 280,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      margin: const EdgeInsets.only(right: 16),
      child: EnhancedCourseNavigation(
        course: course,
        showRipple: true,
        enableHapticFeedback: false,
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course image
              if (course.imageUrl != null)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(
                    course.imageUrl!,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 120,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, size: 40),
                      );
                    },
                  ),
                ),
              
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Course title
                    Text(
                      course.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Price and quick nav
                    Row(
                      children: [
                        Text(
                          '\$${course.price?.toStringAsFixed(2) ?? '0.00'}',
                          style: const TextStyle(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: AppTheme.primaryGreen,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal scrolling list of compact course cards
class CompactCourseList extends StatelessWidget {
  final List<Course> courses;

  const CompactCourseList({
    super.key,
    required this.courses,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: courses.length,
        itemBuilder: (context, index) {
          return CompactCourseCard(course: courses[index]);
        },
      ),
    );
  }
}
