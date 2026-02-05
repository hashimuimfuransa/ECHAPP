import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellence_coaching_hub/config/app_theme.dart';
import 'package:excellence_coaching_hub/presentation/providers/content_management_provider.dart';
import 'package:excellence_coaching_hub/models/section.dart';
import 'package:excellence_coaching_hub/models/lesson.dart';
import 'package:excellence_coaching_hub/data/repositories/course_repository.dart';
import 'package:excellence_coaching_hub/models/course.dart';

class AdminCourseContentScreen extends ConsumerStatefulWidget {
  final String courseId;

  const AdminCourseContentScreen({super.key, required this.courseId});

  @override
  ConsumerState<AdminCourseContentScreen> createState() => _AdminCourseContentScreenState();
}

class _AdminCourseContentScreenState extends ConsumerState<AdminCourseContentScreen> {
  bool _isReordering = false;
  Course? _course;
  bool _courseLoading = true;
  String? _courseError;

  @override
  void initState() {
    super.initState();
    _loadCourseData();
  }

  Future<void> _loadCourseData() async {
    try {
      setState(() {
        _courseLoading = true;
        _courseError = null;
      });

      final repository = CourseRepository();
      final course = await repository.getCourseById(widget.courseId);
      
      setState(() {
        _course = course;
        _courseLoading = false;
      });

      // Load sections for this course
      ref.read(contentManagementProvider.notifier).loadSections(widget.courseId);
    } catch (e) {
      setState(() {
        _courseLoading = false;
        _courseError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final contentState = ref.watch(contentManagementProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Content'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isReordering ? Icons.check : Icons.reorder),
            onPressed: () {
              setState(() {
                _isReordering = !_isReordering;
              });
              ref.read(contentManagementProvider.notifier).toggleReordering();
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _courseLoading ? null : () => _showAddSectionDialog(context),
          ),
        ],
      ),
      body: _courseLoading 
        ? const Center(child: CircularProgressIndicator())
        : _courseError != null 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 50, color: Colors.red),
                  const SizedBox(height: 20),
                  Text('Error: $_courseError'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loadCourseData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _buildContent(context, contentState),
    );
  }

  Widget _buildContent(BuildContext context, ContentManagementState contentState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course Info Header
          _buildCourseHeader(),
          
          const SizedBox(height: 30),
          
          // Sections List
          _buildSectionsList(context, contentState),
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
                Text(
                  _course?.title ?? 'Loading...',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.blackColor,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Manage course sections and lessons',
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
    );
  }

  Widget _buildSectionsList(BuildContext context, ContentManagementState contentState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Course Sections',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.blackColor,
              ),
            ),
            Text(
              '${contentState.sections.length} sections',
              style: const TextStyle(
                color: AppTheme.greyColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        if (contentState.isLoading && contentState.sections.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (contentState.error != null)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(height: 8),
                  Text('Error loading sections: ${contentState.error}'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => ref.read(contentManagementProvider.notifier).loadSections(widget.courseId),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          )
        else if (contentState.sections.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.library_books, size: 60, color: AppTheme.greyColor),
                  const SizedBox(height: 16),
                  const Text(
                    'No sections yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.greyColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add your first section to organize your course content',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.greyColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _showAddSectionDialog(context),
                    child: const Text('Add Section'),
                  ),
                ],
              ),
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onReorder: contentState.isReordering 
              ? ((int oldIndex, int newIndex) => _handleReorder(oldIndex, newIndex))
              : ((int oldIndex, int newIndex) {}),
            itemCount: contentState.sections.length,
            itemBuilder: (context, index) {
              final section = contentState.sections[index];
              return _buildSectionCard(context, section, index);
            },
          ),
      ],
    );
  }

  Widget _buildSectionCard(BuildContext context, Section section, int index) {
    return Container(
      key: ValueKey(section.id),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppTheme.primaryGreen,
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                if (_isReordering) ...[
                  const Icon(Icons.drag_handle, color: Colors.white),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    section.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  'Section ${section.order}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 15),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) => _handleSectionAction(value, section),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 10),
                          Text('Edit Section'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'add_lesson',
                      child: Row(
                        children: [
                          Icon(Icons.add, size: 20),
                          SizedBox(width: 10),
                          Text('Add Lesson'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 10),
                          Text('Delete Section', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Lessons List - temporarily showing empty since we don't have lessons data yet
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text('No lessons in this section yet'),
                const SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: () => _showAddLessonDialog(context, section),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add New Lesson'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                    foregroundColor: AppTheme.primaryGreen,
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonItem(Map<String, dynamic> lesson, bool isLast) {
    IconData getIconForType(String type) {
      switch (type) {
        case 'video': return Icons.video_library;
        case 'notes': return Icons.description;
        case 'quiz': return Icons.quiz;
        default: return Icons.article;
      }
    }

    Color getColorForType(String type) {
      switch (type) {
        case 'video': return AppTheme.primaryGreen;
        case 'notes': return AppTheme.accent;
        case 'quiz': return Colors.orange;
        default: return AppTheme.greyColor;
      }
    }

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderGrey),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: getColorForType(lesson['type']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                getIconForType(lesson['type']),
                color: getColorForType(lesson['type']),
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
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppTheme.blackColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${lesson['duration']} mins • ${lesson['type'].capitalize()}',
                    style: const TextStyle(
                      color: AppTheme.greyColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) => _handleLessonAction(value, lesson),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 10),
                      Text('Edit Lesson'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'preview',
                  child: Row(
                    children: [
                      Icon(Icons.visibility, size: 20),
                      SizedBox(width: 10),
                      Text('Preview'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 10),
                      Text('Delete Lesson', style: TextStyle(color: Colors.red)),
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

  void _handleReorder(int oldIndex, int newIndex) {
    // Handle section reordering
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    
    // Create new order mapping
    final contentState = ref.read(contentManagementProvider);
    final reorderedSections = List<Section>.from(contentState.sections);
    final movedSection = reorderedSections.removeAt(oldIndex);
    reorderedSections.insert(newIndex, movedSection);
    
    // Update order values
    final newOrder = reorderedSections.asMap().entries.map((entry) {
      final index = entry.key;
      final section = entry.value;
      return {'sectionId': section.id, 'order': index + 1};
    }).toList();
    
    // Call the reorder function in the provider
    ref.read(contentManagementProvider.notifier).reorderSections(widget.courseId, newOrder);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sections reordered successfully'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  void _handleSectionAction(String action, Section section) {
    switch (action) {
      case 'edit':
        _showEditSectionDialog(context, section);
        break;
      case 'add_lesson':
        _showAddLessonDialog(context, section);
        break;
      case 'delete':
        _showDeleteConfirmation(context, 'section', section.title, sectionId: section.id);
        break;
    }
  }

  void _handleLessonAction(String action, Map<String, dynamic> lesson) {
    switch (action) {
      case 'edit':
        _showEditLessonDialog(context, lesson);
        break;
      case 'preview':
        // Handle preview
        break;
      case 'delete':
        _showDeleteConfirmation(context, 'lesson', lesson['title']);
        break;
    }
  }

  void _showAddSectionDialog(BuildContext context) {
    final titleController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Section'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            hintText: 'Enter section title',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Clean validation pattern
              if (titleController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Section title is required")),
                );
                return;
              }
              
              // Handle section creation
              Navigator.pop(context);
              final contentState = ref.read(contentManagementProvider);
              final order = contentState.sections.length + 1;
              ref.read(contentManagementProvider.notifier).createSection(
                widget.courseId,
                titleController.text.trim(),
                order,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Section added successfully'),
                  backgroundColor: AppTheme.primaryGreen,
                ),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddLessonDialog(BuildContext context, Section section) {
    context.push('/admin/courses/${widget.courseId}/sections/${section.id}/lessons/create');
  }

  void _showEditSectionDialog(BuildContext context, Section section) {
    final titleController = TextEditingController(text: section.title);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Section'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            hintText: 'Enter section title',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Clean validation pattern
              if (titleController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Section title is required")),
                );
                return;
              }
              
              // Handle section update
              Navigator.pop(context);
              ref.read(contentManagementProvider.notifier).updateSection(section.id, {
                'title': titleController.text.trim()
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Section updated successfully'),
                  backgroundColor: AppTheme.primaryGreen,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditLessonDialog(BuildContext context, Map<String, dynamic> lesson) {
    // Handle lesson editing
  }

  void _showDeleteConfirmation(BuildContext context, String type, String title, {String? sectionId}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Confirmation'),
        content: Text('Are you sure you want to delete this $type: "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (type == 'section' && sectionId != null) {
                ref.read(contentManagementProvider.notifier).deleteSection(sectionId);
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$type deleted successfully'),
                  backgroundColor: AppTheme.primaryGreen,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
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