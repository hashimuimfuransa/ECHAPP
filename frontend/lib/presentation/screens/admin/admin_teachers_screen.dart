import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/course_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/admin_dashboard_provider.dart';
import 'package:excellencecoachinghub/services/infrastructure/api_client.dart';
import 'package:excellencecoachinghub/models/course.dart';
import 'package:excellencecoachinghub/models/user.dart';

/// Admin Teachers Screen - Manage teachers and course assignments
class AdminTeachersScreen extends ConsumerStatefulWidget {
  const AdminTeachersScreen({super.key});

  @override
  ConsumerState<AdminTeachersScreen> createState() => _AdminTeachersScreenState();
}

class _AdminTeachersScreenState extends ConsumerState<AdminTeachersScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  bool _isLoadingCourses = false;
  String? _errorMessage;
  
  List<TeacherData> _teachers = [];
  List<Course> _courses = [];
  
  int _currentPage = 1;
  int _totalPages = 1;
  final TextEditingController _searchController = TextEditingController();
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    _loadTeachers();
    _loadCourses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTeachers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiClient.get(
        '/api/admin/teachers?page=$_currentPage&limit=20${
          _searchQuery != null && _searchQuery!.isNotEmpty 
              ? '&search=${Uri.encodeComponent(_searchQuery!)}' 
              : ''
        }',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        final teachers = (data['teachers'] as List)
            .map((t) => TeacherData.fromJson(t))
            .toList();

        setState(() {
          _teachers = teachers;
          _totalPages = data['totalPages'] ?? 1;
          _currentPage = data['currentPage'] ?? 1;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load teachers: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading teachers: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoadingCourses = true;
    });

    try {
      final response = await _apiClient.get('/api/courses?limit=100');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        final courses = (data['courses'] as List)
            .map((c) => Course.fromJson(c))
            .toList();

        setState(() {
          _courses = courses;
          _isLoadingCourses = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingCourses = false;
      });
    }
  }

  void _handleSearch() {
    setState(() {
      _searchQuery = _searchController.text.trim();
      _currentPage = 1;
    });
    _loadTeachers();
  }

  Future<void> _createTeacher() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const CreateTeacherDialog(),
    );

    if (result != null) {
      try {
        final response = await _apiClient.post(
          '/api/admin/teachers',
          body: jsonEncode(result),
        );

        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Teacher created successfully')),
          );
          _loadTeachers();
        } else {
          throw Exception('Failed to create teacher: ${response.statusCode}');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating teacher: $e')),
        );
      }
    }
  }

  Future<void> _editTeacher(TeacherData teacher) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => EditTeacherDialog(teacher: teacher),
    );

    if (result != null) {
      try {
        final response = await _apiClient.put(
          '/api/admin/teachers/${teacher.id}',
          body: jsonEncode(result),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Teacher updated successfully')),
          );
          _loadTeachers();
        } else {
          throw Exception('Failed to update teacher: ${response.statusCode}');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating teacher: $e')),
        );
      }
    }
  }

  Future<void> _deleteTeacher(TeacherData teacher) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Teacher'),
        content: Text('Are you sure you want to delete ${teacher.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await _apiClient.delete('/api/admin/teachers/${teacher.id}');

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Teacher deleted successfully')),
          );
          _loadTeachers();
        } else {
          throw Exception('Failed to delete teacher: ${response.statusCode}');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting teacher: $e')),
        );
      }
    }
  }

  Future<void> _assignCourses(TeacherData teacher) async {
    // Get current assignments
    List<String> assignedCourseIds = [];
    try {
      final response = await _apiClient.get('/api/admin/teachers/${teacher.id}/assignments');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        final assignments = data['assignments'] as List;
        assignedCourseIds = assignments
            .map((a) => a['course']['_id']?.toString() ?? a['course']['id']?.toString())
            .where((id) => id != null)
            .cast<String>()
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading assignments: $e');
    }

    if (!mounted) return;

    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => AssignCoursesDialog(
        courses: _courses,
        assignedCourseIds: assignedCourseIds,
        teacherName: teacher.fullName,
      ),
    );

    if (result != null) {
      // Unassign courses that are no longer selected
      for (final courseId in assignedCourseIds) {
        if (!result.contains(courseId)) {
          try {
            await _apiClient.post(
              '/api/admin/teachers/unassign',
              body: jsonEncode({
                'teacherId': teacher.id,
                'courseId': courseId,
              }),
            );
          } catch (e) {
            debugPrint('Error unassigning course: $e');
          }
        }
      }

      // Assign new courses
      for (final courseId in result) {
        if (!assignedCourseIds.contains(courseId)) {
          try {
            await _apiClient.post(
              '/api/admin/teachers/assign',
              body: jsonEncode({
                'teacherId': teacher.id,
                'courseId': courseId,
              }),
            );
          } catch (e) {
            debugPrint('Error assigning course: $e');
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course assignments updated')),
      );
      _loadTeachers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Manage Teachers'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTeachers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Create bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search teachers...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery != null && _searchQuery!.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = null);
                                _loadTeachers();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onSubmitted: (_) => _handleSearch(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _createTeacher,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Teacher'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorWidget()
                    : _teachers.isEmpty
                        ? _buildEmptyWidget()
                        : _buildTeachersTable(),
          ),

          // Pagination
          if (!_isLoading && _teachers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _currentPage > 1
                        ? () {
                            setState(() => _currentPage--);
                            _loadTeachers();
                          }
                        : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('Page $_currentPage of $_totalPages'),
                  IconButton(
                    onPressed: _currentPage < _totalPages
                        ? () {
                            setState(() => _currentPage++);
                            _loadTeachers();
                          }
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
        ],
      ),
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
            onPressed: _loadTeachers,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            _searchQuery != null
                ? 'No teachers found for "$_searchQuery"'
                : 'No teachers found',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTeachersTable() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Phone')),
            DataColumn(label: Text('Courses')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Actions')),
          ],
          rows: _teachers.map((teacher) {
            return DataRow(
              cells: [
                DataCell(
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppTheme.primaryGreen,
                        child: Text(
                          teacher.fullName.isNotEmpty
                              ? teacher.fullName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(teacher.fullName),
                    ],
                  ),
                ),
                DataCell(Text(teacher.email ?? '-')),
                DataCell(Text(teacher.phone ?? '-')),
                DataCell(
                  Chip(
                    label: Text('${teacher.assignedCourseCount}'),
                    backgroundColor: Colors.blue[50],
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: teacher.isActive ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      teacher.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: teacher.isActive ? Colors.green : Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editTeacher(teacher),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: const Icon(Icons.assignment, color: Colors.orange),
                        onPressed: () => _assignCourses(teacher),
                        tooltip: 'Assign Courses',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteTeacher(teacher),
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Teacher Data class
class TeacherData {
  final String id;
  final String firebaseUid;
  final String fullName;
  final String? email;
  final String? phone;
  final String role;
  final bool isActive;
  final int assignedCourseCount;
  final DateTime? createdAt;

  TeacherData({
    required this.id,
    this.firebaseUid = '',
    required this.fullName,
    this.email,
    this.phone,
    this.role = 'instructor',
    this.isActive = true,
    this.assignedCourseCount = 0,
    this.createdAt,
  });

  factory TeacherData.fromJson(Map<String, dynamic> json) {
    return TeacherData(
      id: json['_id'] ?? json['id'] ?? '',
      firebaseUid: json['firebaseUid'] ?? '',
      fullName: json['fullName'] ?? 'Unknown',
      email: json['email'],
      phone: json['phone'],
      role: json['role'] ?? 'instructor',
      isActive: json['isActive'] ?? true,
      assignedCourseCount: json['assignedCourseCount'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }
}

/// Create Teacher Dialog
class CreateTeacherDialog extends StatefulWidget {
  const CreateTeacherDialog({super.key});

  @override
  State<CreateTeacherDialog> createState() => _CreateTeacherDialogState();
}

class _CreateTeacherDialogState extends State<CreateTeacherDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _generatePassword = true;
  bool _sendCredentials = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Teacher'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              if (!_generatePassword)
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (!_generatePassword && (value == null || value.length < 6)) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
              CheckboxListTile(
                value: _generatePassword,
                onChanged: (value) => setState(() => _generatePassword = value ?? true),
                title: const Text('Auto-generate password'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                value: _sendCredentials,
                onChanged: (value) => setState(() => _sendCredentials = value ?? false),
                title: const Text('Send credentials via email'),
                controlAffinity: ListTileControlAffinity.leading,
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
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'fullName': _nameController.text.trim(),
                'email': _emailController.text.trim().isNotEmpty
                    ? _emailController.text.trim()
                    : null,
                'phone': _phoneController.text.trim().isNotEmpty
                    ? _phoneController.text.trim()
                    : null,
                'password': _generatePassword
                    ? 'AutoGenerated123!'
                    : _passwordController.text,
                'sendCredentials': _sendCredentials,
              });
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
          child: const Text('Create'),
        ),
      ],
    );
  }
}

/// Edit Teacher Dialog
class EditTeacherDialog extends StatefulWidget {
  final TeacherData teacher;

  const EditTeacherDialog({super.key, required this.teacher});

  @override
  State<EditTeacherDialog> createState() => _EditTeacherDialogState();
}

class _EditTeacherDialogState extends State<EditTeacherDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.teacher.fullName);
  late final _emailController = TextEditingController(text: widget.teacher.email ?? '');
  late final _phoneController = TextEditingController(text: widget.teacher.phone ?? '');
  late bool _isActive = widget.teacher.isActive;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Teacher'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
                title: const Text('Active Account'),
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
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'fullName': _nameController.text.trim(),
                'email': _emailController.text.trim().isNotEmpty
                    ? _emailController.text.trim()
                    : null,
                'phone': _phoneController.text.trim().isNotEmpty
                    ? _phoneController.text.trim()
                    : null,
                'isActive': _isActive,
              });
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Assign Courses Dialog
class AssignCoursesDialog extends StatefulWidget {
  final List<Course> courses;
  final List<String> assignedCourseIds;
  final String teacherName;

  const AssignCoursesDialog({
    super.key,
    required this.courses,
    required this.assignedCourseIds,
    required this.teacherName,
  });

  @override
  State<AssignCoursesDialog> createState() => _AssignCoursesDialogState();
}

class _AssignCoursesDialogState extends State<AssignCoursesDialog> {
  late List<String> _selectedCourseIds = List.from(widget.assignedCourseIds);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Assign Courses to ${widget.teacherName}'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.courses.length,
          itemBuilder: (context, index) {
            final course = widget.courses[index];
            final isSelected = _selectedCourseIds.contains(course.id);

            return CheckboxListTile(
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedCourseIds.add(course.id);
                  } else {
                    _selectedCourseIds.remove(course.id);
                  }
                });
              },
              title: Text(course.title),
              subtitle: Text('${course.level} • ${course.enrollmentCount} students'),
              secondary: course.thumbnail != null
                  ? Image.network(course.thumbnail!, width: 48, height: 48, fit: BoxFit.cover)
                  : const Icon(Icons.school),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedCourseIds),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
