import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/services/teacher_service.dart';
import 'package:excellencecoachinghub/services/live_session_service.dart';
import 'package:excellencecoachinghub/services/api/section_service.dart';
import 'package:excellencecoachinghub/models/teacher_course.dart';
import 'package:excellencecoachinghub/models/live_session.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';

/// Schedule Live Session Screen - Create BBB sessions
class ScheduleLiveSessionScreen extends ConsumerStatefulWidget {
  final String? courseId;
  final String? sectionId;
  final String? lessonId;

  const ScheduleLiveSessionScreen({
    super.key,
    this.courseId,
    this.sectionId,
    this.lessonId,
  });

  @override
  ConsumerState<ScheduleLiveSessionScreen> createState() => _ScheduleLiveSessionScreenState();
}

class _ScheduleLiveSessionScreenState extends ConsumerState<ScheduleLiveSessionScreen> {
  final TeacherService _teacherService = TeacherService();
  final LiveSessionService _liveSessionService = LiveSessionService();
  final SectionService _sectionService = SectionService();

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<TeacherCourse> _courses = [];
  CourseContent? _selectedCourseContent;
  
  String? _selectedCourseId;
  String? _selectedSectionId;
  String? _selectedLessonId;
  
  DateTime _scheduledDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _scheduledTime = const TimeOfDay(hour: 10, minute: 0);
  int _duration = 60;
  int _maxParticipants = 100;
  
  SessionSettings _settings = SessionSettings();

  bool _isLoading = true;
  bool _isCreating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedCourseId = widget.courseId;
    _selectedSectionId = widget.sectionId;
    _selectedLessonId = widget.lessonId;
    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _teacherService.getAssignedCourses(limit: 100);
      setState(() {
        _courses = response.courses;
        _isLoading = false;
      });

      // If course is pre-selected, load its content
      if (_selectedCourseId != null) {
        await _loadCourseContent(_selectedCourseId!);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading courses: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) {
        context.go('/auth-selection');
      }
    }
  }

  Future<void> _loadCourseContent(String courseId) async {
    try {
      final content = await _teacherService.getCourseContent(courseId);
      setState(() {
        _selectedCourseContent = content;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading course content: $e')),
      );
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _scheduledDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _scheduledTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _scheduledTime = picked);
    }
  }

  DateTime get _scheduledDateTime {
    return DateTime(
      _scheduledDate.year,
      _scheduledDate.month,
      _scheduledDate.day,
      _scheduledTime.hour,
      _scheduledTime.minute,
    );
  }

  DateTime get _endDateTime {
    return _scheduledDateTime.add(Duration(minutes: _duration));
  }

  Future<void> _createSession() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCourseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a course')),
      );
      return;
    }
    if (_selectedSectionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a section')),
      );
      return;
    }

    // Validate that scheduled time is in the future
    final scheduledAt = _scheduledDateTime;
    final now = DateTime.now();
    if (scheduledAt.isBefore(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot schedule sessions in the past. Please select a future date and time.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      // Use the calculated scheduled datetime

      await _liveSessionService.createSession(
        courseId: _selectedCourseId!,
        sectionId: _selectedSectionId!,
        lessonId: _selectedLessonId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        scheduledAt: scheduledAt,
        duration: _duration,
        maxParticipants: _maxParticipants,
        settings: _settings,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Live session scheduled successfully')),
        );
        context.pop(true);
      }
    } catch (e) {
      setState(() => _isCreating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating session: $e')),
      );
    }
  }

  // Show dialog to create a new section
  Future<void> _showCreateSectionDialog() async {
    if (!mounted) return;

    // Defer to next frame to avoid build cycle issues
    await Future.delayed(Duration.zero);
    if (!mounted) return;

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CreateSectionDialog(isDark: Theme.of(context).brightness == Brightness.dark),
    );

    if (result != null && result.isNotEmpty && _selectedCourseId != null) {
      await _createNewSection(result);
    }
  }

  // Create a new section via API
  Future<void> _createNewSection(String title) async {
    if (_selectedCourseId == null) return;

    setState(() => _isLoading = true);

    try {
      // Calculate order as next available
      final order = (_selectedCourseContent?.sections.length ?? 0) + 1;

      final newSection = await _sectionService.createSection(
        courseId: _selectedCourseId!,
        title: title,
        order: order,
      );

      // Refresh course content to include new section
      await _loadCourseContent(_selectedCourseId!);

      // Auto-select the newly created section
      setState(() {
        _selectedSectionId = newSection.id;
        _selectedLessonId = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Section "$title" created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating section: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Show dialog to create a new lesson
  Future<void> _showCreateLessonDialog() async {
    if (_selectedSectionId == null || _selectedCourseContent == null) return;
    if (!mounted) return;

    // Defer to next frame to avoid build cycle issues
    await Future.delayed(Duration.zero);
    if (!mounted) return;

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CreateLessonDialog(isDark: Theme.of(context).brightness == Brightness.dark),
    );

    if (result != null && result.isNotEmpty) {
      await _createNewLesson(result);
    }
  }

  // Create a new lesson via API
  Future<void> _createNewLesson(String title) async {
    if (_selectedSectionId == null || _selectedCourseId == null || _selectedCourseContent == null) return;

    setState(() => _isLoading = true);

    try {
      // Get current section's lessons count for order
      final section = _selectedCourseContent!.sections.firstWhere((s) => s.id == _selectedSectionId);
      final order = section.lessons.length + 1;

      final newLesson = await _sectionService.createLesson(
        sectionId: _selectedSectionId!,
        courseId: _selectedCourseId!,
        title: title,
        order: order,
        isPublished: false, // New lessons start unpublished
      );

      // Refresh course content to include new lesson
      await _loadCourseContent(_selectedCourseId!);

      // Auto-select the newly created lesson
      setState(() {
        _selectedLessonId = newLesson.id;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lesson "$title" created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating lesson: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = AppTheme.getCardColor(context);
    final textPrimary = isDark ? AppTheme.darkTextPrimary : Colors.black87;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : Colors.grey[600];

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('Schedule Live Session'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorWidget()
              : _buildForm(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = AppTheme.getCardColor(context);
    final textPrimary = isDark ? AppTheme.darkTextPrimary : Colors.black87;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : Colors.grey[600]!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Session Details Card
            Card(
              color: cardColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Session Title *',
                        hintText: 'e.g., Week 1: Introduction to Algebra',
                        prefixIcon: Icon(Icons.title),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a session title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        hintText: 'What will be covered in this session?',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Course & Section Card
            Card(
              color: cardColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Course & Location',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Course Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedCourseId,
                      decoration: const InputDecoration(
                        labelText: 'Course *',
                        prefixIcon: Icon(Icons.school),
                        border: OutlineInputBorder(),
                      ),
                      items: _courses.map((course) {
                        return DropdownMenuItem(
                          value: course.course.id,
                          child: Text(
                            course.course.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCourseId = value;
                          _selectedSectionId = null;
                          _selectedLessonId = null;
                          _selectedCourseContent = null;
                        });
                        if (value != null) {
                          _loadCourseContent(value);
                        }
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a course';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Section Dropdown with Create Button
                    if (_selectedCourseContent != null)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedSectionId,
                              decoration: const InputDecoration(
                                labelText: 'Section *',
                                prefixIcon: Icon(Icons.folder),
                                border: OutlineInputBorder(),
                              ),
                              items: _selectedCourseContent!.sections.map((section) {
                                return DropdownMenuItem(
                                  value: section.id,
                                  child: Text(section.title),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedSectionId = value;
                                  _selectedLessonId = null;
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select a section';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Tooltip(
                            message: 'Create New Section',
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                border: Border.all(color: AppTheme.primaryGreen),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.add_circle, color: AppTheme.primaryGreen),
                                onPressed: _showCreateSectionDialog,
                              ),
                            ),
                          ),
                        ],
                      ),

                    if (_selectedSectionId != null && _selectedCourseContent != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedLessonId,
                                decoration: const InputDecoration(
                                  labelText: 'Lesson (Optional)',
                                  prefixIcon: Icon(Icons.play_circle),
                                  border: OutlineInputBorder(),
                                ),
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text('General Section Session'),
                                  ),
                                  ..._selectedCourseContent!.sections
                                      .firstWhere((s) => s.id == _selectedSectionId)
                                      .lessons
                                      .map((lesson) {
                                    return DropdownMenuItem(
                                      value: lesson.id,
                                      child: Text(lesson.title),
                                    );
                                  }),
                                ],
                                onChanged: (value) {
                                  setState(() => _selectedLessonId = value);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Tooltip(
                              message: 'Create New Lesson',
                              child: Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppTheme.primaryGreen),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.add_circle, color: AppTheme.primaryGreen),
                                  onPressed: _showCreateLessonDialog,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Schedule Card
            Card(
              color: cardColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Schedule',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Date and Time
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _selectDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Date *',
                                prefixIcon: Icon(Icons.calendar_today),
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                DateFormat('MMM d, yyyy').format(_scheduledDate),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: _selectTime,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Time *',
                                prefixIcon: Icon(Icons.access_time),
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                _scheduledTime.format(context),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Duration Slider
                    Row(
                      children: [
                        Icon(Icons.timer, color: textSecondary),
                        const SizedBox(width: 8),
                        Text('Duration:', style: TextStyle(color: textPrimary)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Slider(
                            value: _duration.toDouble(),
                            min: 15,
                            max: 180,
                            divisions: 11,
                            label: '$_duration min',
                            onChanged: (value) {
                              setState(() => _duration = value.toInt());
                            },
                          ),
                        ),
                        Text(
                          '$_duration min',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // End Time Display
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.event_available, color: AppTheme.primaryGreen, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Ends at: ',
                            style: TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            DateFormat('MMM d, yyyy • h:mm a').format(_endDateTime),
                            style: TextStyle(
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Max Participants Slider
                    Row(
                      children: [
                        Icon(Icons.people, color: textSecondary),
                        const SizedBox(width: 8),
                        Text('Max Participants:', style: TextStyle(color: textPrimary)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Slider(
                            value: _maxParticipants.toDouble(),
                            min: 2,
                            max: 100,
                            divisions: 49,
                            label: '$_maxParticipants',
                            onChanged: (value) {
                              setState(() => _maxParticipants = value.toInt());
                            },
                          ),
                        ),
                        Text(
                          '$_maxParticipants',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Settings Card
            Card(
              color: cardColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Meeting Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    SwitchListTile(
                      title: const Text('Enable Chat'),
                      subtitle: const Text('Allow students to use text chat'),
                      value: _settings.enableChat,
                      onChanged: (value) {
                        setState(() {
                          _settings = SessionSettings(
                            enableChat: value,
                            enableWebcam: _settings.enableWebcam,
                            muteOnEntry: _settings.muteOnEntry,
                            allowRecording: _settings.allowRecording,
                            waitingRoom: _settings.waitingRoom,
                          );
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Enable Webcam'),
                      subtitle: const Text('Allow students to share their webcam'),
                      value: _settings.enableWebcam,
                      onChanged: (value) {
                        setState(() {
                          _settings = SessionSettings(
                            enableChat: _settings.enableChat,
                            enableWebcam: value,
                            muteOnEntry: _settings.muteOnEntry,
                            allowRecording: _settings.allowRecording,
                            waitingRoom: _settings.waitingRoom,
                          );
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Mute on Entry'),
                      subtitle: const Text('Students join muted by default'),
                      value: _settings.muteOnEntry,
                      onChanged: (value) {
                        setState(() {
                          _settings = SessionSettings(
                            enableChat: _settings.enableChat,
                            enableWebcam: _settings.enableWebcam,
                            muteOnEntry: value,
                            allowRecording: _settings.allowRecording,
                            waitingRoom: _settings.waitingRoom,
                          );
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Allow Recording'),
                      subtitle: const Text('Record the session for later viewing'),
                      value: _settings.allowRecording,
                      onChanged: (value) {
                        setState(() {
                          _settings = SessionSettings(
                            enableChat: _settings.enableChat,
                            enableWebcam: _settings.enableWebcam,
                            muteOnEntry: _settings.muteOnEntry,
                            allowRecording: value,
                            waitingRoom: _settings.waitingRoom,
                          );
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Waiting Room'),
                      subtitle: const Text('Students wait for approval before joining'),
                      value: _settings.waitingRoom,
                      onChanged: (value) {
                        setState(() {
                          _settings = SessionSettings(
                            enableChat: _settings.enableChat,
                            enableWebcam: _settings.enableWebcam,
                            muteOnEntry: _settings.muteOnEntry,
                            allowRecording: _settings.allowRecording,
                            waitingRoom: value,
                          );
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Create Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isCreating ? null : _createSession,
                icon: _isCreating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.schedule),
                label: Text(_isCreating ? 'Creating...' : 'Schedule Session'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog for creating a new section
class _CreateSectionDialog extends StatefulWidget {
  final bool isDark;

  const _CreateSectionDialog({this.isDark = false});

  @override
  State<_CreateSectionDialog> createState() => _CreateSectionDialogState();
}

class _CreateSectionDialogState extends State<_CreateSectionDialog> {
  final _titleController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.getCardColor(context),
      title: Text('Create New Section', style: TextStyle(color: widget.isDark ? AppTheme.darkTextPrimary : Colors.black87)),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Section Title *',
            hintText: 'e.g., Chapter 1: Introduction',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a section title';
            }
            return null;
          },
          autofocus: true,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(_titleController.text.trim());
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.white,
          ),
          child: const Text('Create'),
        ),
      ],
    );
  }
}

/// Dialog for creating a new lesson
class _CreateLessonDialog extends StatefulWidget {
  final bool isDark;

  const _CreateLessonDialog({this.isDark = false});

  @override
  State<_CreateLessonDialog> createState() => _CreateLessonDialogState();
}

class _CreateLessonDialogState extends State<_CreateLessonDialog> {
  final _titleController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.getCardColor(context),
      title: Text('Create New Lesson', style: TextStyle(color: widget.isDark ? AppTheme.darkTextPrimary : Colors.black87)),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Lesson Title *',
            hintText: 'e.g., Introduction to Topic',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a lesson title';
            }
            return null;
          },
          autofocus: true,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(_titleController.text.trim());
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.white,
          ),
          child: const Text('Create'),
        ),
      ],
    );
  }
}
