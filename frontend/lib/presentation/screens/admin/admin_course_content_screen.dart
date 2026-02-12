import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excellence_coaching_hub/config/app_theme.dart';
import 'package:excellence_coaching_hub/presentation/providers/content_management_provider.dart';
import 'package:excellence_coaching_hub/models/section.dart';
import 'package:excellence_coaching_hub/models/lesson.dart';
import 'package:excellence_coaching_hub/data/repositories/course_repository.dart';
import 'package:excellence_coaching_hub/models/course.dart';
import 'package:excellence_coaching_hub/data/repositories/video_repository.dart';
import 'package:excellence_coaching_hub/data/repositories/lesson_repository.dart';
import 'package:excellence_coaching_hub/data/repositories/exam_repository.dart';
import 'package:excellence_coaching_hub/models/video.dart';
import 'package:excellence_coaching_hub/models/exam.dart' as exam_model;
import 'package:excellence_coaching_hub/services/api/exam_service.dart';
import 'package:excellence_coaching_hub/services/infrastructure/api_client.dart'; // For ApiException
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:excellence_coaching_hub/config/api_config.dart';

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
  final Map<String, List<exam_model.Exam>> _examsBySection = {};
  final Map<String, bool> _examsLoading = {};
  final ExamService _examService = ExamService();

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

  Future<void> _loadSectionExams(String sectionId) async {
    print('LoadSectionExams called for: $sectionId, currently loading: ${_examsLoading[sectionId] ?? false}');
    
    if (_examsLoading[sectionId] == true) {
      print('Already loading exams for section: $sectionId, skipping');
      return;
    }
    
    print('Starting exam load for section: $sectionId');
    
    setState(() {
      _examsLoading[sectionId] = true;
    });
    
    try {
      // Add timeout to prevent infinite loading
      print('Making API call for section: $sectionId');
      final exams = await _examService.getSectionExamsAdmin(sectionId).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('Timeout loading exams for section: $sectionId');
          return <exam_model.Exam>[];
        },
      );
      print('API call successful, received ${exams.length} exams for section: $sectionId');
      if (mounted) {
        setState(() {
          _examsBySection[sectionId] = exams;
          _examsLoading[sectionId] = false;
        });
        print('State updated successfully for section: $sectionId');
      } else {
        print('Widget not mounted, skipping state update for section: $sectionId');
      }
    } catch (e) {
      print('Error loading exams for section $sectionId: $e');
      if (mounted) {
        setState(() {
          _examsLoading[sectionId] = false;
        });
        print('Error state updated for section: $sectionId');
        
        // Show user-friendly error message
        if (context.mounted) {
          String errorMessage = 'Failed to load exams';
          if (e is ApiException) {
            if (e.statusCode == 401) {
              errorMessage = 'Authentication required. Please log in again.';
            } else if (e.statusCode == 403) {
              errorMessage = 'Access denied. Check your permissions.';
            } else {
              errorMessage = e.message;
            }
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Retry',
                onPressed: () => _loadSectionExams(sectionId),
              ),
            ),
          );
        }
      }
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
            icon: const Icon(Icons.refresh),
            onPressed: _courseLoading ? null : _refreshAllExams,
            tooltip: 'Refresh All Exams',
          ),
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
        if (contentState.isLoading)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading course content...'),
                ],
              ),
            ),
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
                    'No sections created yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.greyColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create sections to organize your course content into logical modules',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.greyColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddSectionDialog(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Create First Section'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                    ),
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
              return _buildSectionCard(context, section, index, contentState.lessonsBySection);
            },
          ),
      ],
    );
  }

  Widget _buildSectionCard(BuildContext context, Section section, int index, Map<String, List<Lesson>> lessonsBySection) {
      // Schedule exam loading for after the build phase
      if (!_examsBySection.containsKey(section.id) && 
          _examsLoading[section.id] != true) {
        print('Scheduling exam load for section: ${section.id}');
        // Use addPostFrameCallback to schedule after build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _loadSectionExams(section.id);
          }
        });
      } else {
        print('Exams already loaded or loading for section: ${section.id}');
        print('Current exam state - Loaded: ${_examsBySection.containsKey(section.id)}, Loading: ${_examsLoading[section.id] ?? false}');
        if (_examsBySection.containsKey(section.id)) {
          print('Exams count: ${_examsBySection[section.id]?.length ?? 0}');
        }
      }
      
      final exams = _examsBySection[section.id] ?? [];
      final examsLoading = _examsLoading[section.id] ?? false;
      
      print('Building section card - Exams: ${exams.length}, Loading: $examsLoading');
    return Container(
      key: ValueKey('section-${section.id}-exams-${exams.length}-loading-${examsLoading}'),
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
                      value: 'add_exam',
                      child: Row(
                        children: [
                          Icon(Icons.quiz, size: 20),
                          SizedBox(width: 10),
                          Text('Add Exam'),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Lessons in this section',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.greyColor,
                      ),
                    ),
                    if (lessonsBySection[section.id]?.isNotEmpty == true)
                      Text(
                        '${lessonsBySection[section.id]?.length ?? 0} lessons',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Display lessons or empty state
                if (lessonsBySection[section.id]?.isEmpty == true)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.greyColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.greyColor.withOpacity(0.1),
                      ),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.book_outlined, size: 40, color: AppTheme.greyColor),
                        SizedBox(height: 12),
                        Text(
                          'No lessons added yet',
                          style: TextStyle(
                            color: AppTheme.greyColor,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Add lessons to provide course content',
                          style: TextStyle(
                            color: AppTheme.greyColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  // Display actual lessons
                  Column(
                    children: [
                      ...(() {
                        final lessons = lessonsBySection[section.id] ?? [];
                        return lessons.asMap().entries.map((entry) {
                          final index = entry.key;
                          final lesson = entry.value;
                          final isLast = index == lessons.length - 1;
                          return _buildLessonItem(lesson.toJson(), isLast);
                        }).toList();
                      }()),
                    ],
                  ),
                
                // Exams Section
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Exams in this section',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.greyColor,
                      ),
                    ),
                    if (exams.isNotEmpty)
                      Text(
                        '${exams.length} exams',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Display exams or loading state
                if (examsLoading)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 8),
                          Text('Loading exams... (${exams.length} loaded)', style: const TextStyle(fontSize: 12, color: AppTheme.greyColor)),
                        ],
                      ),
                    ),
                  )
                else if (exams.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.greyColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.greyColor.withOpacity(0.1),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.quiz_outlined, size: 40, color: AppTheme.greyColor),
                        const SizedBox(height: 12),
                        const Text(
                          'No exams added yet',
                          style: TextStyle(
                            color: AppTheme.greyColor,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Add exams to assess student knowledge',
                          style: TextStyle(
                            color: AppTheme.greyColor,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => _loadSectionExams(section.id),
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Refresh Exams'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryGreen,
                            side: const BorderSide(color: AppTheme.primaryGreen),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  // Display actual exams
                  Column(
                    children: exams.map((exam) => _buildExamItem(exam, false)).toList(),
                  ),
                
                const SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: (section.id.isEmpty || section.id.length < 5) ? null : () => _showAddLessonDialog(context, section),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Lesson'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (section.id.isEmpty || section.id.length < 5) 
                        ? AppTheme.greyColor.withOpacity(0.1) 
                        : AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: (section.id.isEmpty || section.id.length < 5) ? null : () => _showAddExamDialog(context, section),
                  icon: const Icon(Icons.quiz, size: 18),
                  label: const Text('Add Exam'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: (section.id.isEmpty || section.id.length < 5) 
                        ? AppTheme.greyColor 
                        : AppTheme.primaryGreen,
                    side: BorderSide(
                      color: (section.id.isEmpty || section.id.length < 5) 
                          ? AppTheme.greyColor 
                          : AppTheme.primaryGreen,
                    ),
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
    // Determine lesson type based on available content
    String getLessonType() {
      if (lesson['videoId'] != null && lesson['videoId'] != '') {
        return 'video';
      } else if (lesson['notes'] != null && lesson['notes'] != '') {
        return 'notes';
      } else {
        return 'lesson'; // default type
      }
    }

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

    String lessonType = getLessonType();

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
                color: getColorForType(lessonType).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                getIconForType(lessonType),
                color: getColorForType(lessonType),
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
                    '${lesson['duration']} mins • ${lessonType.capitalize()}',
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

  Widget _buildExamItem(exam_model.Exam exam, bool isLast) {
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
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.quiz,
                color: Colors.orange,
                size: 20,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exam.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppTheme.blackColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${exam.questionsCount} questions • ${exam.type} • ${exam.isPublished ? 'Published' : 'Draft'}',
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
              onSelected: (value) => _handleExamAction(value, exam),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 10),
                      Text('Edit Exam'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'publish',
                  child: Row(
                    children: [
                      Icon(Icons.publish, size: 20),
                      SizedBox(width: 10),
                      Text('Publish Exam'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 10),
                      Text('Delete Exam', style: TextStyle(color: Colors.red)),
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

  void _handleExamAction(String action, exam_model.Exam exam) {
    switch (action) {
      case 'edit':
        _showEditExamDialog(exam);
        break;
      case 'publish':
        _toggleExamPublishStatus(exam);
        break;
      case 'delete':
        _confirmDeleteExam(exam);
        break;
    }
  }

  void _showEditExamDialog(exam_model.Exam exam) {
    final titleController = TextEditingController(text: exam.title);
    final passingScoreController = TextEditingController(text: exam.passingScore.toString());
    final timeLimitController = TextEditingController(text: exam.timeLimit.toString());
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Exam'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Exam Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passingScoreController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Passing Score (%)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: timeLimitController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Time Limit (minutes)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Validation
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Exam title is required')),
                  );
                  return;
                }
                
                final passingScore = int.tryParse(passingScoreController.text);
                if (passingScore == null || passingScore < 0 || passingScore > 100) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Passing score must be between 0 and 100')),
                  );
                  return;
                }
                
                final timeLimit = int.tryParse(timeLimitController.text);
                if (timeLimit == null || timeLimit <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Time limit must be a positive number')),
                  );
                  return;
                }
                
                Navigator.pop(context);
                
                try {
                  final examRepo = ExamRepository();
                  await examRepo.updateExam(
                    examId: exam.id,
                    title: titleController.text.trim(),
                    passingScore: passingScore,
                    timeLimit: timeLimit,
                  );
                  
                  // Refresh the exams for this section
                  _loadSectionExams(exam.sectionId);
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Exam updated successfully'),
                        backgroundColor: AppTheme.primaryGreen,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update exam: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _toggleExamPublishStatus(exam_model.Exam exam) async {
    try {
      final examRepo = ExamRepository();
      final updatedExam = await examRepo.toggleExamPublish(exam.id, exam.isPublished);
      
      // Update the local state
      setState(() {
        final sectionExams = _examsBySection[exam.sectionId] ?? [];
        final index = sectionExams.indexWhere((e) => e.id == exam.id);
        if (index != -1) {
          sectionExams[index] = updatedExam;
          _examsBySection[exam.sectionId] = sectionExams;
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updatedExam.isPublished 
                ? 'Exam published successfully' 
                : 'Exam unpublished successfully'
            ),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to toggle exam status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmDeleteExam(exam_model.Exam exam) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Exam'),
          content: Text('Are you sure you want to delete "${exam.title}"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                
                try {
                  final examRepo = ExamRepository();
                  await examRepo.deleteExam(exam.id);
                  
                  // Remove from local state
                  setState(() {
                    final sectionExams = _examsBySection[exam.sectionId] ?? [];
                    sectionExams.removeWhere((e) => e.id == exam.id);
                    _examsBySection[exam.sectionId] = sectionExams;
                  });
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Exam deleted successfully'),
                        backgroundColor: AppTheme.primaryGreen,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete exam: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _refreshAllExams() {
    print('Refreshing all exams');
    final contentState = ref.read(contentManagementProvider);
    
    // Clear all exam state and reload
    setState(() {
      _examsBySection.clear();
      _examsLoading.clear();
    });
    
    // Trigger reload for all sections
    for (var section in contentState.sections) {
      _loadSectionExams(section.id);
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Refreshing all exams...'),
        backgroundColor: AppTheme.primaryGreen,
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
      case 'add_exam':
        _showAddExamDialog(context, section);
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
        _showLessonPreviewDialog(context, lesson);
        break;
      case 'delete':
        _showDeleteConfirmation(context, 'lesson', lesson['title'], lesson: lesson);
        break;
    }
  }

  void _showLessonPreviewDialog(BuildContext context, Map<String, dynamic> lesson) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lesson Preview'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson['title'] ?? 'Untitled Lesson',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                if (lesson['description'] != null && lesson['description'].toString().isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Description:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(lesson['description'].toString()),
                      const SizedBox(height: 10),
                    ],
                  ),
                if (lesson['videoId'] != null && lesson['videoId'].toString().isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Video:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(lesson['videoId'].toString()),
                      const SizedBox(height: 10),
                    ],
                  ),
                if (lesson['notes'] != null && lesson['notes'].toString().isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notes:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(lesson['notes'].toString()),
                      const SizedBox(height: 10),
                    ],
                  ),
                Text(
                  'Duration: ${(lesson['duration'] ?? 0)} minutes',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 10),
                Text(
                  'Order: ${(lesson['order'] ?? 0)}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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
    // Ensure both IDs are valid before navigating
    if (widget.courseId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Course ID is invalid'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (section.id.isEmpty || section.id.length < 5) { // MongoDB ObjectIds are typically 24 characters long
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Section ID is invalid (${section.id.length} chars): "${section.id}" for section titled: "${section.title}"'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Navigate to create lesson page with section and course IDs
    context.push('/admin/courses/${widget.courseId}/sections/${section.id}/lessons/create');
  }

  void _showAddExamDialog(BuildContext context, Section section) {
    // Ensure both IDs are valid before navigating
    if (widget.courseId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Course ID is invalid'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (section.id.isEmpty || section.id.length < 5) { // MongoDB ObjectIds are typically 24 characters long
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Section ID is invalid (${section.id.length} chars): "${section.id}" for section titled: "${section.title}"'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Navigate to create exam page with section and course IDs
    context.push('/admin/courses/${widget.courseId}/sections/${section.id}/exams/create');
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

  Future<void> _showEditLessonDialog(BuildContext context, Map<String, dynamic> lesson) async {
    final titleController = TextEditingController(text: lesson['title']);
    final descriptionController = TextEditingController(text: lesson['description'] ?? '');
    final notesController = TextEditingController(text: lesson['notes'] ?? '');
    int duration = lesson['duration'] ?? 0;
    
    // Get the selected video ID from the lesson
    String? selectedVideoId = lesson['videoId'];
    
    // Track document upload state
    String? documentPath = lesson['notes']; // If notes contain document path
    bool isUploadingDocument = false;
    
    // Load videos for dropdown first before showing dialog
    List<Video> videos = [];
    bool isLoadingVideos = true;
    String? errorMessage;
    
    try {
      final videoRepo = VideoRepository();
      // Use course-specific videos instead of all videos to avoid potential issues
      final loadedVideos = await videoRepo.getVideosByCourse(lesson['courseId']);
      // Ensure loadedVideos is indeed a List<Video> and not something else
      videos = loadedVideos;
      isLoadingVideos = false;
    } catch (e) {
      errorMessage = e.toString();
      isLoadingVideos = false;
    }
    
    // Show dialog with form
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('Edit Lesson'),
              content: SizedBox(
                width: 500,
                child: isLoadingVideos
                    ? const Center(child: CircularProgressIndicator())
                    : errorMessage != null
                        ? Text('Error: $errorMessage')
                        : Form(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title Field
                                TextFormField(
                                  controller: titleController,
                                  decoration: const InputDecoration(
                                    labelText: 'Lesson Title',
                                    border: OutlineInputBorder(),
                                    hintText: 'Enter lesson title',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter a title';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 10),
                                
                                // Description Field
                                TextFormField(
                                  controller: descriptionController,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    labelText: 'Description',
                                    border: OutlineInputBorder(),
                                    hintText: 'Enter lesson description',
                                  ),
                                ),
                                const SizedBox(height: 10),
                                
                                // Duration Field
                                TextFormField(
                                  initialValue: duration.toString(),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Duration (minutes)',
                                    border: OutlineInputBorder(),
                                    hintText: 'Enter duration in minutes',
                                  ),
                                  onChanged: (value) {
                                    duration = int.tryParse(value) ?? 0;
                                  },
                                ),
                                const SizedBox(height: 10),
                                
                                // Video Selection
                                const Text(
                                  'Select Video',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 5),
                                DropdownButtonFormField<String?>(
                                  initialValue: selectedVideoId,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                  ),
                                  items: _getUniqueVideoItems(videos.where((video) => video != null).toList()),
                                  onChanged: (value) {
                                    setDialogState(() {
                                      selectedVideoId = value;
                                    });
                                  },
                                  hint: const Text('Choose a video'),
                                ),
                                const SizedBox(height: 10),
                                
                                // Document Upload Section (replaces text notes field)
                                if (documentPath != null && documentPath!.isNotEmpty && 
                                    (documentPath!.toLowerCase().contains('.pdf') || 
                                     documentPath!.toLowerCase().contains('.doc') || 
                                     documentPath!.toLowerCase().contains('.docx') ||
                                     documentPath!.toLowerCase().contains('.txt') ||
                                     documentPath!.toLowerCase().contains('.ppt') ||
                                     documentPath!.toLowerCase().contains('.pptx') ||
                                     documentPath!.toLowerCase().contains('.xls') ||
                                     documentPath!.toLowerCase().contains('.xlsx')))
                                  // Document display section
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.greyColor.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            // Different icons based on file type
                                            Icon(
                                              documentPath!.toLowerCase().contains('.pdf') ? Icons.picture_as_pdf :
                                              documentPath!.toLowerCase().contains('.doc') || documentPath!.toLowerCase().contains('.docx') ? Icons.insert_drive_file :
                                              documentPath!.toLowerCase().contains('.ppt') || documentPath!.toLowerCase().contains('.pptx') ? Icons.slideshow :
                                              documentPath!.toLowerCase().contains('.xls') || documentPath!.toLowerCase().contains('.xlsx') ? Icons.table_chart :
                                              Icons.insert_drive_file, // default icon
                                              color: AppTheme.primaryGreen,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                'Document Uploaded: ${documentPath!.split('/').last}',
                                                style: TextStyle(
                                                  color: AppTheme.primaryGreen,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            OutlinedButton.icon(
                                              onPressed: () async {
                                                // Remove document
                                                setDialogState(() {
                                                  documentPath = null;
                                                  notesController.clear();
                                                });
                                              },
                                              icon: const Icon(Icons.delete, size: 16),
                                              label: const Text('Remove'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.red,
                                                side: const BorderSide(color: Colors.red),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  const Text(
                                    'No document uploaded',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                
                                const SizedBox(height: 10),
                                
                                // Document Upload Button (replaces text notes field)
                                ElevatedButton.icon(
                                  onPressed: isUploadingDocument ? null : () async {
                                    // Check if Firebase Auth is ready before proceeding
                                    try {
                                      final auth = firebase_auth.FirebaseAuth.instance;
                                      if (auth.currentUser == null) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Authentication not ready. Please try again.'),
                                              backgroundColor: Colors.orange,
                                            ),
                                          );
                                        }
                                        return;
                                      }
                                    } catch (authError) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Authentication service not ready. Please try again.'),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                      }
                                      return;
                                    }
                                    
                                    setDialogState(() {
                                      isUploadingDocument = true;
                                    });
                                    
                                    try {
                                      final result = await FilePicker.platform.pickFiles(
                                        type: FileType.custom,
                                        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'ppt', 'pptx', 'xls', 'xlsx'],
                                      );
                                      
                                      if (result != null) {
                                        final file = result.files.single;
                                        
                                        // Check if file path is valid before attempting upload
                                        if (file.path != null) {
                                          // Upload the document to the backend
                                          final uploadResult = await _uploadDocument(file.path!, lesson['courseId']);
                                          
                                          if (uploadResult != null) {
                                            // Handle the response - documentUrl might be in different fields
                                            String? documentUrl = uploadResult['documentUrl'] as String?;
                                            documentUrl ??= uploadResult['s3Key'] as String?;
                                            if (documentUrl == null) {
                                              // Try the data object structure
                                              final data = uploadResult['data'];
                                              if (data != null && data is Map<String, dynamic>) {
                                                documentUrl = data['documentUrl'] as String?;
                                                documentUrl ??= data['s3Key'] as String?;
                                              }
                                            }
                                            
                                            if (documentUrl != null) {
                                              setDialogState(() {
                                                documentPath = documentUrl;
                                                notesController.text = documentUrl!;
                                                isUploadingDocument = false;
                                              });
                                              
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Document uploaded successfully!'),
                                                    backgroundColor: Colors.green,
                                                  ),
                                                );
                                              }
                                            } else {
                                              setDialogState(() {
                                                isUploadingDocument = false;
                                              });
                                              
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Document uploaded but URL not found'),
                                                    backgroundColor: Colors.orange,
                                                  ),
                                                );
                                              }
                                            }
                                          } else {
                                            setDialogState(() {
                                              isUploadingDocument = false;
                                            });
                                            
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Failed to upload document'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          }
                                        } else {
                                          setDialogState(() {
                                            isUploadingDocument = false;
                                          });
                                          
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Invalid file path'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      } else {
                                        setDialogState(() {
                                          isUploadingDocument = false;
                                        });
                                      }
                                    } catch (e) {
                                      setDialogState(() {
                                        isUploadingDocument = false;
                                      });
                                      
                                      // Handle the specific late initialization error
                                      final errorMessage = e.toString();
                                      if (errorMessage.contains('LateInitializationError')) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Service not ready. Please try again.'),
                                              backgroundColor: Colors.orange,
                                            ),
                                          );
                                        }
                                      } else {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Document selection failed: $e'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  },
                                  icon: isUploadingDocument
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Icon(Icons.upload),
                                  label: Text(isUploadingDocument ? 'Uploading...' : 'Upload Document'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.accent,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Validate and update lesson
                    if (titleController.text.trim().isEmpty) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a title'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                      return;
                    }
                    
                    try {
                      // Prepare update data
                      final updateData = {
                        'title': titleController.text.trim(),
                        'description': descriptionController.text.trim(),
                        'videoId': selectedVideoId,
                        'notes': documentPath ?? notesController.text.trim(),
                        'duration': duration,
                        'sectionId': lesson['sectionId'], // Pass sectionId for local state update
                      };
                      
                      // Use the optimized updateLesson method from provider
                      await ref.read(contentManagementProvider.notifier).updateLesson(
                        lesson['id'],
                        updateData,
                      );
                      
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Lesson updated successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to update lesson: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, String type, String title, {String? sectionId, Map<String, dynamic>? lesson}) {
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
            onPressed: () async {
              Navigator.pop(context);
              if (type == 'section' && sectionId != null) {
                try {
                  await ref.read(contentManagementProvider.notifier).deleteSection(sectionId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Section deleted successfully'),
                        backgroundColor: AppTheme.primaryGreen,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete section: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } else if (type == 'lesson') {
                // Delete lesson
                try {
                  final lessonRepo = LessonRepository();
                  await lessonRepo.deleteLesson(lesson!['id']);
                  // Reload sections to update the UI
                  await ref.read(contentManagementProvider.notifier).loadSections(widget.courseId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Lesson deleted successfully'),
                        backgroundColor: AppTheme.primaryGreen,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete lesson: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Upload document to backend
  Future<Map<String, dynamic>?> _uploadDocument(String filePath, String courseId) async {
    // Retry mechanism for service initialization
    int retries = 3;
    Exception? lastError;
    
    for (int attempt = 0; attempt < retries; attempt++) {
      try {
        // Wait progressively longer between retries
        if (attempt > 0) {
          await Future.delayed(Duration(milliseconds: 200 * attempt));
        }
        
        // Verify Firebase Auth is ready
        final auth = firebase_auth.FirebaseAuth.instance;
        final currentUser = auth.currentUser;
        if (currentUser == null) {
          throw Exception('User not authenticated');
        }
        
        final file = File(filePath);
        final bytes = await file.readAsBytes();
        final fileName = path.basename(filePath);
        
        final idToken = await currentUser.getIdToken(true);
        
        // Create multipart request
        final uri = Uri.parse('${ApiConfig.upload}/document');
        final request = http.MultipartRequest('POST', uri);
        
        // Add authentication header
        request.headers.addAll({
          'Authorization': 'Bearer $idToken',
        });
        
        // Add form fields
        request.fields['courseId'] = courseId;
        
        // Add file
        final multipartFile = http.MultipartFile.fromBytes(
          'document',
          bytes,
          filename: fileName,
        );
        request.files.add(multipartFile);
        
        // Send request
        final response = await request.send();
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          final responseBody = await response.stream.bytesToString();
          final jsonResponse = json.decode(responseBody);
          
          if (jsonResponse['success'] == true) {
            return jsonResponse['data'];
          } else {
            print('Document upload failed: ${jsonResponse['message']}');
            return null;
          }
        } else {
          print('Document upload failed with status: ${response.statusCode}');
          return null;
        }
      } catch (e) {
        lastError = e as Exception;
        print('Upload attempt ${attempt + 1} failed: $e');
        
        // If it's not a LateInitializationError, don't retry
        if (!e.toString().contains('LateInitializationError')) {
          break;
        }
        
        // If this is the last attempt, rethrow
        if (attempt == retries - 1) {
          print('All upload attempts failed');
          return null;
        }
      }
    }
    
    return null;
  }

  /// Get unique video items for dropdown to avoid duplicate values
  List<DropdownMenuItem<String?>> _getUniqueVideoItems(List<Video> videos) {
    final seenValues = <String>{};
    final uniqueItems = <DropdownMenuItem<String?>>[];

    for (final video in videos) {
      // Use videoId if available, otherwise fall back to video.id
      final value = video.videoId ?? video.id;
      
      // Skip if we've already seen this value to avoid duplicates
      if (!seenValues.contains(value)) {
        seenValues.add(value);
        uniqueItems.add(
          DropdownMenuItem(
            value: value,
            child: Text(video.title),
          ),
        );
      }
    }

    return uniqueItems;
  }
}

// Extension to capitalize first letter
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
