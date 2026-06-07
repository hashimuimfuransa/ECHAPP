import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/services/teacher_service.dart';
import 'package:excellencecoachinghub/services/live_session_service.dart';
import 'package:excellencecoachinghub/models/teacher_course.dart';
import 'package:excellencecoachinghub/models/live_session.dart';

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
    );
    if (picked != null) {
      setState(() => _scheduledTime = picked);
    }
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

    setState(() => _isCreating = true);

    try {
      // Combine date and time
      final scheduledAt = DateTime(
        _scheduledDate.year,
        _scheduledDate.month,
        _scheduledDate.day,
        _scheduledTime.hour,
        _scheduledTime.minute,
      );

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Schedule Live Session'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Session Details Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Session Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Course & Location',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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

                    // Section Dropdown
                    if (_selectedCourseContent != null)
                      DropdownButtonFormField<String>(
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

                    if (_selectedSectionId != null && _selectedCourseContent != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
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
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Schedule Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Schedule',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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
                        const Icon(Icons.timer, color: Colors.grey),
                        const SizedBox(width: 8),
                        const Text('Duration:'),
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
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Settings Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Meeting Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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
