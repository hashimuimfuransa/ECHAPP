import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellence_coaching_hub/config/app_theme.dart';

class AdminCourseContentScreen extends ConsumerStatefulWidget {
  final String courseId;

  const AdminCourseContentScreen({super.key, required this.courseId});

  @override
  ConsumerState<AdminCourseContentScreen> createState() => _AdminCourseContentScreenState();
}

class _AdminCourseContentScreenState extends ConsumerState<AdminCourseContentScreen> {
  bool _isReordering = false;

  @override
  Widget build(BuildContext context) {
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
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddSectionDialog(context),
          ),
        ],
      ),
      body: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course Info Header
          _buildCourseHeader(),
          
          const SizedBox(height: 30),
          
          // Sections List
          _buildSectionsList(context),
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mathematics Advanced',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.blackColor,
                  ),
                ),
                SizedBox(height: 5),
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

  Widget _buildSectionsList(BuildContext context) {
    // Mock sections data
    final sections = [
      {
        'id': '1',
        'title': 'Introduction to Advanced Mathematics',
        'order': 1,
        'lessons': [
          {'id': '1', 'title': 'Course Overview', 'type': 'video', 'duration': 15},
          {'id': '2', 'title': 'Prerequisites Review', 'type': 'notes', 'duration': 10},
          {'id': '3', 'title': 'Getting Started Quiz', 'type': 'quiz', 'duration': 20},
        ]
      },
      {
        'id': '2',
        'title': 'Algebra Fundamentals',
        'order': 2,
        'lessons': [
          {'id': '4', 'title': 'Linear Equations', 'type': 'video', 'duration': 25},
          {'id': '5', 'title': 'Quadratic Equations', 'type': 'video', 'duration': 30},
          {'id': '6', 'title': 'Algebra Practice Problems', 'type': 'notes', 'duration': 15},
        ]
      },
      {
        'id': '3',
        'title': 'Calculus Basics',
        'order': 3,
        'lessons': [
          {'id': '7', 'title': 'Limits and Continuity', 'type': 'video', 'duration': 35},
          {'id': '8', 'title': 'Derivatives Introduction', 'type': 'video', 'duration': 40},
          {'id': '9', 'title': 'Calculus Formula Sheet', 'type': 'notes', 'duration': 5},
        ]
      },
    ];

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
              '${sections.length} sections',
              style: const TextStyle(
                color: AppTheme.greyColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorder: _isReordering 
            ? ((int oldIndex, int newIndex) => _handleReorder(oldIndex, newIndex))
            : ((int oldIndex, int newIndex) {}),
          itemCount: sections.length,
          itemBuilder: (context, index) {
            final section = sections[index];
            return _buildSectionCard(context, section, index);
          },
        ),
      ],
    );
  }

  Widget _buildSectionCard(BuildContext context, Map<String, dynamic> section, int index) {
    return Container(
      key: ValueKey(section['id']),
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
                    section['title'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  'Section ${section['order']}',
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
          
          // Lessons List
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                ...List.generate(section['lessons'].length, (lessonIndex) {
                  final lesson = section['lessons'][lessonIndex];
                  return _buildLessonItem(lesson, lessonIndex == section['lessons'].length - 1);
                }),
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
    // In a real implementation, this would update the backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sections reordered successfully'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  void _handleSectionAction(String action, Map<String, dynamic> section) {
    switch (action) {
      case 'edit':
        _showEditSectionDialog(context, section);
        break;
      case 'add_lesson':
        _showAddLessonDialog(context, section);
        break;
      case 'delete':
        _showDeleteConfirmation(context, 'section', section['title']);
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

  void _showAddLessonDialog(BuildContext context, Map<String, dynamic> section) {
    context.push('/admin/courses/${widget.courseId}/sections/${section['id']}/lessons/create');
  }

  void _showEditSectionDialog(BuildContext context, Map<String, dynamic> section) {
    final titleController = TextEditingController(text: section['title']);
    
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

  void _showDeleteConfirmation(BuildContext context, String type, String title) {
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