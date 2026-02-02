import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellence_coaching_hub/config/app_theme.dart';

class AdminCoursesScreen extends ConsumerWidget {
  const AdminCoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Management'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/admin/courses/create'),
          ),
        ],
      ),
      body: _buildCoursesContent(context),
    );
  }

  Widget _buildCoursesContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search and Filter
          _buildSearchAndFilter(context),
          
          const SizedBox(height: 20),
          
          // Courses List
          _buildCoursesList(context),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: const TextField(
              decoration: InputDecoration(
                hintText: 'Search courses...',
                border: InputBorder.none,
                icon: Icon(Icons.search),
              ),
            ),
          ),
        ),
        const SizedBox(width: 15),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
              ),
            ],
          ),
          child: PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              // Handle filter selection
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('All Courses'),
              ),
              const PopupMenuItem(
                value: 'published',
                child: Text('Published'),
              ),
              const PopupMenuItem(
                value: 'draft',
                child: Text('Draft'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCoursesList(BuildContext context) {
    // Mock course data
    final courses = [
      {
        'id': '1',
        'title': 'Mathematics Advanced',
        'description': 'Advanced mathematics concepts for high school students',
        'price': 150000,
        'duration': 120,
        'level': 'advanced',
        'isPublished': true,
        'students': 245,
        'thumbnail': '',
      },
      {
        'id': '2',
        'title': 'Physics Fundamentals',
        'description': 'Basic physics concepts for beginners',
        'price': 120000,
        'duration': 90,
        'level': 'beginner',
        'isPublished': false,
        'students': 189,
        'thumbnail': '',
      },
      {
        'id': '3',
        'title': 'Chemistry Lab Techniques',
        'description': 'Practical chemistry experiments and techniques',
        'price': 180000,
        'duration': 150,
        'level': 'intermediate',
        'isPublished': true,
        'students': 312,
        'thumbnail': '',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'All Courses',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.blackColor,
          ),
        ),
        const SizedBox(height: 15),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: courses.length,
          itemBuilder: (context, index) {
            final course = courses[index];
            return _buildCourseCard(context, course);
          },
        ),
      ],
    );
  }

  Widget _buildCourseCard(BuildContext context, Map<String, dynamic> course) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Course Thumbnail Placeholder
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.school,
                    color: AppTheme.primaryGreen,
                    size: 40,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              course['title'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.blackColor,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: course['isPublished'] 
                                ? AppTheme.primaryGreen.withOpacity(0.1)
                                : AppTheme.accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              course['isPublished'] ? 'Published' : 'Draft',
                              style: TextStyle(
                                color: course['isPublished'] 
                                  ? AppTheme.primaryGreen
                                  : AppTheme.accent,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        course['description'],
                        style: const TextStyle(
                          color: AppTheme.greyColor,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildInfoChip(
                            Icons.access_time,
                            '${course['duration']} mins',
                            AppTheme.primaryGreen,
                          ),
                          const SizedBox(width: 10),
                          _buildInfoChip(
                            Icons.speed,
                            course['level'].toString().capitalize(),
                            AppTheme.accent,
                          ),
                          const SizedBox(width: 10),
                          _buildInfoChip(
                            Icons.people,
                            '${course['students']} students',
                            AppTheme.primaryGreen,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'UGX ${course['price'].toString().replaceAllMapped(
                              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                              (Match m) => '${m[1]},',
                            )}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () {
                                  context.push('/admin/courses/edit/${course['id']}');
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.visibility, size: 20),
                                onPressed: () {
                                  context.push('/admin/courses/${course['id']}/content');
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                onPressed: () {
                                  // Handle delete
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Extension to capitalize first letter
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}