import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/presentation/providers/admin_course_provider.dart';
import 'package:excellencecoachinghub/models/course.dart';

class AdminCoursesScreen extends ConsumerStatefulWidget {
  const AdminCoursesScreen({super.key});

  @override
  ConsumerState<AdminCoursesScreen> createState() => _AdminCoursesScreenState();
}

class _AdminCoursesScreenState extends ConsumerState<AdminCoursesScreen> {
  final bool _hasLoadedInitialData = false;
  String _filterStatus = 'All';

  @override
  void initState() {
    super.initState();
    // Load courses when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminCourseProvider.notifier).loadCourses();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch the admin course provider
    final courseState = ref.watch(adminCourseProvider);
    
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(adminCourseProvider.notifier).loadCourses(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'delete_all') {
                _confirmDeleteAllCourses(ref, courseState.courses);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Delete All Courses'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildCoursesContent(context, ref, courseState),
    );
  }

  Widget _buildCoursesContent(BuildContext context, WidgetRef ref, AdminCourseState courseState) {
    if (courseState.isLoading && courseState.courses.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Loading courses...'),
          ],
        ),
      );
    }

    if (courseState.error != null && courseState.courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 50, color: Colors.red),
            const SizedBox(height: 20),
            Text(
              'Error loading courses: ${courseState.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => ref.read(adminCourseProvider.notifier).loadCourses(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search and Filter
          _buildSearchAndFilter(context),
          
          const SizedBox(height: 20),
          
          // Courses List
          _buildCoursesList(context, ref, courseState.courses),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(BuildContext context) {
    final TextEditingController searchController = TextEditingController();
    
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
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: 'Search courses...',
                border: InputBorder.none,
                icon: Icon(Icons.search),
              ),
              onSubmitted: (query) {
                if (query.isNotEmpty) {
                  ref.read(adminCourseProvider.notifier).searchCourses(query);
                } else {
                  ref.read(adminCourseProvider.notifier).loadCourses();
                }
              },
              onChanged: (query) {
                // Optional: Implement debounced search
                if (query.isEmpty) {
                  ref.read(adminCourseProvider.notifier).loadCourses();
                }
              },
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
              setState(() {
                _filterStatus = value == 'all' ? 'All' : 
                               value == 'published' ? 'Published' : 'Draft';
              });
              ref.read(adminCourseProvider.notifier).filterCoursesByStatus(value);
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

  Widget _buildCoursesList(BuildContext context, WidgetRef ref, List<Course> courses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'All Courses (${courses.length})',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.blackColor,
              ),
            ),
            if (courses.isNotEmpty)
              TextButton(
                onPressed: () {
                  _confirmDeleteAllCourses(ref, courses);
                },
                child: const Text(
                  'Delete All',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        const SizedBox(height: 15),
        if (courses.isEmpty)
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Column(
              children: [
                Icon(Icons.school_outlined, size: 60, color: AppTheme.greyColor),
                SizedBox(height: 15),
                Text(
                  'No courses found',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppTheme.greyColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Create your first course to get started',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.greyColor,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return _buildCourseCard(context, ref, course);
            },
          ),
      ],
    );
  }

  Widget _buildCourseCard(BuildContext context, WidgetRef ref, Course course) {
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 768;
            final isMediumScreen = constraints.maxWidth >= 768 && constraints.maxWidth < 1024;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Course Thumbnail
                    Container(
                      width: isSmallScreen ? 60 : 80,
                      height: isSmallScreen ? 60 : 80,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: course.thumbnail != null && course.thumbnail!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                course.thumbnail!,
                                fit: BoxFit.cover,
                                width: isSmallScreen ? 60 : 80,
                                height: isSmallScreen ? 60 : 80,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    width: isSmallScreen ? 60 : 80,
                                    height: isSmallScreen ? 60 : 80,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryGreen.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        value: null,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: isSmallScreen ? 60 : 80,
                                    height: isSmallScreen ? 60 : 80,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryGreen.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.school,
                                      color: AppTheme.primaryGreen,
                                      size: isSmallScreen ? 30 : 40,
                                    ),
                                  );
                                },
                              ),
                            )
                          : Container(
                              width: isSmallScreen ? 60 : 80,
                              height: isSmallScreen ? 60 : 80,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.school,
                                color: AppTheme.primaryGreen,
                                size: isSmallScreen ? 30 : 40,
                              ),
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
                                  course.title ?? 'Untitled Course',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 16 : 18,
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
                                  color: course.isPublished 
                                    ? AppTheme.primaryGreen.withOpacity(0.1)
                                    : AppTheme.accent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  course.isPublished ? 'Published' : 'Draft',
                                  style: TextStyle(
                                    color: course.isPublished 
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
                            course.description,
                            style: const TextStyle(
                              color: AppTheme.greyColor,
                              fontSize: 14,
                            ),
                            maxLines: isSmallScreen ? 2 : 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              _buildInfoChip(
                                Icons.access_time,
                                '${course.duration} mins',
                                AppTheme.primaryGreen,
                                isSmall: isSmallScreen,
                              ),
                              _buildInfoChip(
                                Icons.speed,
                                course.level.capitalize(),
                                AppTheme.accent,
                                isSmall: isSmallScreen,
                              ),
                              if (course.category != null)
                                _buildInfoChip(
                                  Icons.category,
                                  course.category!['name'] as String? ?? 'Uncategorized',
                                  AppTheme.primaryGreen,
                                  isSmall: isSmallScreen,
                                ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'RWF ${course.price.toString().replaceAllMapped(
                                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                  (Match m) => '${m[1]},',
                                )}',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 16 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                              Row(
                                children: [
                                  // Publish Toggle Button
                                  Switch(
                                    value: course.isPublished,
                                    onChanged: (value) {
                                      ref.read(adminCourseProvider.notifier)
                                          .toggleCoursePublish(course.id, course.isPublished);
                                    },
                                    activeThumbColor: AppTheme.primaryGreen,
                                  ),
                                  const SizedBox(width: 8),
                                  if (isSmallScreen)
                                    _buildCompactActionButtons(context, ref, course)
                                  else
                                    _buildFullActionButtons(context, ref, course),
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
            );
          },
        ),
      ),
    );
  }
  
  void _confirmDeleteCourse(WidgetRef ref, Course course) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Course'),
          content: Text(
            'Are you sure you want to delete "${course.title ?? 'Untitled Course'}"? This will permanently remove all associated content including videos, materials, and exams. This action cannot be undone.',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(adminCourseProvider.notifier).deleteCourse(course.id);
                  
                // Show success snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Course "${course.title ?? 'Untitled Course'}" deleted successfully'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 3),
                  ),
                );
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
  
  void _confirmDeleteAllCourses(WidgetRef ref, List<Course> courses) {
    if (courses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No courses to delete'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
  
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete All Courses'),
          content: Text(
            'Are you sure you want to delete ALL ${courses.length} courses? This will permanently remove all courses and their associated content. This action cannot be undone.',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                  
                // Delete all courses one by one
                for (var course in courses) {
                  ref.read(adminCourseProvider.notifier).deleteCourse(course.id);
                }
                  
                // Show success snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('All ${courses.length} courses deleted successfully'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 3),
                  ),
                );
              },
              child: const Text('DELETE ALL', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color, {bool isSmall = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 6 : 8, vertical: isSmall ? 3 : 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isSmall ? 12 : 14, color: color),
          SizedBox(width: isSmall ? 3 : 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: isSmall ? 11 : 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullActionButtons(BuildContext context, WidgetRef ref, Course course) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit, size: 20),
          tooltip: 'Edit Course',
          onPressed: () {
            context.push('/admin/courses/${course.id}/edit');
          },
        ),
        IconButton(
          icon: const Icon(Icons.visibility, size: 20),
          tooltip: 'View Content',
          onPressed: () {
            context.push('/admin/courses/${course.id}/content');
          },
        ),
        IconButton(
          icon: const Icon(Icons.video_library, size: 20, color: AppTheme.primaryGreen),
          tooltip: 'Manage Videos',
          onPressed: () {
            context.push('/admin/courses/${course.id}/videos');
          },
        ),
        IconButton(
          icon: const Icon(Icons.note, size: 20, color: AppTheme.accent),
          tooltip: 'Manage Materials',
          onPressed: () {
            context.push('/admin/courses/${course.id}/materials');
          },
        ),
        IconButton(
          icon: const Icon(Icons.quiz, size: 20, color: Colors.orange),
          tooltip: 'Manage Exams',
          onPressed: () {
            context.push('/admin/courses/${course.id}/exams');
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
          tooltip: 'Delete Course',
          onPressed: () {
            _confirmDeleteCourse(ref, course);
          },
        ),
      ],
    );
  }

  Widget _buildCompactActionButtons(BuildContext context, WidgetRef ref, Course course) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      tooltip: 'Course Actions',
      onSelected: (value) {
        switch (value) {
          case 'edit':
            context.push('/admin/courses/${course.id}/edit');
            break;
          case 'content':
            context.push('/admin/courses/${course.id}/content');
            break;
          case 'videos':
            context.push('/admin/courses/${course.id}/videos');
            break;
          case 'materials':
            context.push('/admin/courses/${course.id}/materials');
            break;
          case 'exams':
            context.push('/admin/courses/${course.id}/exams');
            break;
          case 'delete':
            _confirmDeleteCourse(ref, course);
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 20),
              SizedBox(width: 10),
              Text('Edit Course'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'content',
          child: Row(
            children: [
              Icon(Icons.visibility, size: 20),
              SizedBox(width: 10),
              Text('View Content'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'videos',
          child: Row(
            children: [
              Icon(Icons.video_library, size: 20, color: AppTheme.primaryGreen),
              SizedBox(width: 10),
              Text('Manage Videos'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'materials',
          child: Row(
            children: [
              Icon(Icons.note, size: 20, color: AppTheme.accent),
              SizedBox(width: 10),
              Text('Manage Materials'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'exams',
          child: Row(
            children: [
              Icon(Icons.quiz, size: 20, color: Colors.orange),
              SizedBox(width: 10),
              Text('Manage Exams'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 20, color: Colors.red),
              SizedBox(width: 10),
              Text('Delete Course', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }
}

// Extension to capitalize first letter
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
