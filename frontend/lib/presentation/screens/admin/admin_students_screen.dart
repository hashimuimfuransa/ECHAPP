import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/course_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/notification_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/admin_dashboard_provider.dart';
import 'package:excellencecoachinghub/services/admin_service.dart';
import 'package:excellencecoachinghub/models/user.dart';
import 'package:excellencecoachinghub/models/enrollment.dart';

class AdminStudentsScreen extends ConsumerStatefulWidget {
  final String? studentId;
  const AdminStudentsScreen({super.key, this.studentId});

  @override
  ConsumerState<AdminStudentsScreen> createState() => _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends ConsumerState<AdminStudentsScreen> {
  final AdminService _adminService = AdminService();
  bool _isLoading = false;
  List<User> _students = [];
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  final TextEditingController _searchController = TextEditingController();
  
  // Loading state for student details
  bool _loadingStudentDetail = false;

  @override
  void initState() {
    super.initState();
    _loadStudents();
    if (widget.studentId != null) {
      // Delay to ensure the screen is built
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _loadStudentDetail(widget.studentId!);
        }
      });
    }
  }

  void _handleGlobalRefresh() {
    // Refresh all key providers
    // NOTE: We DO NOT invalidate authProvider here because it causes the user to be logged out.
    ref.invalidate(coursesProvider);
    ref.invalidate(popularCoursesProvider);
    ref.invalidate(enrolledCoursesProvider);
    ref.invalidate(backendCategoriesProvider);
    ref.invalidate(notificationCountProvider);
    ref.invalidate(adminDashboardProvider);
    
    // Also refresh local data
    _loadStudents();
    
    // Show a small feedback to the user
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Application refreshed'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        width: 200,
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  Future<void> _loadStudents({String? searchQuery, String? source}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final studentsData = await _adminService.getStudents(
        page: _currentPage,
        search: searchQuery,
        source: source ?? 'mongodb',
      );
      
      if (!mounted) return;
      setState(() {
        _students = studentsData.students;
        _totalPages = studentsData.totalPages;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStudentDetail(String studentId) async {
    setState(() {
      _loadingStudentDetail = true;
      _errorMessage = null;
    });

    try {
      final studentDetail = await _adminService.getStudentDetail(studentId);
      if (!mounted) return;
      setState(() {
        _loadingStudentDetail = false;
      });
      
      // Show dialog with student detail
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => StudentDetailModal(
            studentDetail: studentDetail,
            onClose: () => Navigator.pop(context),
            isLoading: false,
            onResetDevice: () => _resetUserDevice(studentDetail.user.id),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _loadingStudentDetail = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading student details: $e')),
        );
      }
    }
  }

  Future<void> _loadStudentEnrollments(String studentId) async {
    setState(() {
      _loadingStudentDetail = true;
      _errorMessage = null;
    });

    try {
      final studentDetail = await _adminService.getStudentDetail(studentId);
      if (!mounted) return;
      setState(() {
        _loadingStudentDetail = false;
      });
      
      // Show dialog with only enrollments
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => StudentEnrollmentsModal(
            studentDetail: studentDetail,
            onClose: () => Navigator.pop(context),
            isLoading: false,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _loadingStudentDetail = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading student enrollments: $e')),
        );
      }
    }
  }

  Future<void> _loadUserDeviceInfo(String userId) async {
    setState(() {
      _loadingStudentDetail = true;
      _errorMessage = null;
    });

    try {
      final userDeviceInfo = await _adminService.getUserDeviceInfo(userId);
      if (!mounted) return;
      setState(() {
        _loadingStudentDetail = false;
      });
      
      // Convert UserDeviceInfo to StudentDetail for compatibility with existing modal
      final studentDetail = StudentDetail(
        user: userDeviceInfo.user,
        enrollments: userDeviceInfo.enrolledCourses,
        examResults: [],
        payments: [],
        totalEnrollments: userDeviceInfo.totalEnrollments,
        completedCourses: userDeviceInfo.enrolledCourses.where((e) => e.completionStatus == 'completed').length,
        inProgressCourses: userDeviceInfo.enrolledCourses.where((e) => e.completionStatus == 'in-progress').length,
        totalSpent: 0.0,
        lastActive: null,
      );
      
      // Show dialog with device info
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => StudentDetailModal(
            studentDetail: studentDetail,
            onClose: () => Navigator.pop(context),
            isLoading: false,
            onResetDevice: () => _resetUserDevice(userId),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _loadingStudentDetail = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user device info: $e')),
        );
      }
    }
  }

  Future<void> _resetUserDevice(String userId) async {
    try {
      final result = await _adminService.resetUserDevice(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Device reset successfully: ${result['message']}'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh the student detail
        _loadStudentDetail(userId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error resetting device: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleStudentStatus(User student, bool disabled) async {
    setState(() {
      _loadingStudentDetail = true;
      _errorMessage = null;
    });

    try {
      final result = await _adminService.toggleStudentStatus(student.id, disabled);
      if (!mounted) return;
      
      setState(() {
        _loadingStudentDetail = false;
        // Update the student in the list if found
        final index = _students.indexWhere((s) => s.id == student.id);
        if (index != -1) {
          // We might need to update the User model to include the 'disabled' field
          // For now, we'll just refresh the list
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${student.fullName} ${disabled ? 'deactivated' : 'activated'} successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh the student list to get updated statuses
        await _loadStudents(searchQuery: _searchController.text);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _loadingStudentDetail = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error toggling student status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeactivateDialog(User student) {
    final bool isDeactivating = student.disabled != true;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isDeactivating ? 'Deactivate Account' : 'Activate Account'),
        content: Text('Are you sure you want to ${isDeactivating ? 'deactivate' : 'activate'} ${student.fullName}\'s account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _toggleStudentStatus(student, isDeactivating);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDeactivating ? Colors.red : AppTheme.primaryGreen
            ),
            child: Text(isDeactivating ? 'Deactivate' : 'Activate'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(User student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student'),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.black87, fontSize: 16),
            children: [
              const TextSpan(text: 'Are you sure you want to permanently delete '),
              TextSpan(
                text: student.fullName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: '\'s account?\n\n'),
              const TextSpan(
                text: 'This action will permanently delete:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: '\n• User account\n• All enrollments\n• Payment records\n• Exam results\n\n'),
              const TextSpan(
                text: 'This action cannot be undone!',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
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
            onPressed: () {
              Navigator.pop(context);
              _deleteStudent(student);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteStudent(User student) async {
    setState(() {
      _loadingStudentDetail = true;
      _errorMessage = null;
    });

    try {
      final result = await _adminService.deleteStudent(student.id);
      if (!mounted) return;
      setState(() {
        _loadingStudentDetail = false;
        // Remove the deleted student from the list
        _students.removeWhere((s) => s.id == student.id);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${student.fullName} deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh the student list
        await _loadStudents(searchQuery: _searchController.text);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _loadingStudentDetail = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting student: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _searchStudents(String query) {
    _currentPage = 1;
    _loadStudents(searchQuery: query, source: 'mongodb');
  }

  void _changePage(int page) {
    setState(() {
      _currentPage = page;
    });
    _loadStudents(searchQuery: _searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: (context.canPop() || GoRouterState.of(context).uri.path != '/admin') 
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/admin');
                }
              },
              tooltip: 'Back',
            ) 
          : null,
        title: const Text('Student Management'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _handleGlobalRefresh,
            tooltip: 'Refresh App',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadStudents(),
            tooltip: 'Refresh Students',
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => context.push('/admin/analytics'),
            tooltip: 'Analytics',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Student Management',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.blackColor,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Manage and monitor all students on the platform',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.greyColor,
              ),
            ),
            const SizedBox(height: 20),
            
            // Search bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search students...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                    ),
                    onChanged: _searchStudents,
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _searchStudents('');
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Error message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => setState(() => _errorMessage = null),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 20),
            
            // Students list
            Expanded(
              child: _isLoading && _students.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _students.isEmpty
                  ? _buildEmptyState()
                  : _buildStudentsList(),
            ),
            
            // Pagination
            if (_totalPages > 1)
              _buildPagination(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.people,
              size: 80,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No students found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.blackColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _searchController.text.isEmpty 
              ? 'No students have registered yet' 
              : 'No students match your search criteria',
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.greyColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsList() {
    return ListView.builder(
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 15),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: 25,
              backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
              child: Text(
                student.fullName.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            title: Text(
              student.fullName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 5),
                Text(
                  student.email,
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: student.role == 'admin' 
                            ? AppTheme.primaryGreen.withOpacity(0.2) 
                            : AppTheme.accent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        student.role.toUpperCase(),
                        style: TextStyle(
                          color: student.role == 'admin' 
                              ? AppTheme.primaryGreen 
                              : AppTheme.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (student.disabled == true) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'DISABLED',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 10),
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: AppTheme.greyColor,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Joined: ${_formatDate(student.createdAt)}',
                        style: const TextStyle(
                          fontSize: 12, 
                          color: AppTheme.greyColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (student.deviceId != null && student.deviceId!.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.devices,
                        size: 16,
                        color: Colors.green,
                      ),
                    ] else ...[
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.phonelink_off,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ],
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility, color: AppTheme.primaryGreen),
                  onPressed: () => _loadStudentDetail(student.id),
                  tooltip: 'View Details',
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'view':
                        _loadStudentDetail(student.id);
                        break;
                      case 'enrollments':
                        _loadStudentEnrollments(student.id);
                        break;
                      case 'device_info':
                        _loadUserDeviceInfo(student.id); // student.id is the MongoDB _id
                        break;
                      case 'toggle_status':
                        _showDeactivateDialog(student);
                        break;
                      case 'delete':
                        _showDeleteConfirmationDialog(student);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, color: AppTheme.primaryGreen),
                          SizedBox(width: 10),
                          Text('View Details'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'enrollments',
                      child: Row(
                        children: [
                          Icon(Icons.school, color: AppTheme.accent),
                          SizedBox(width: 10),
                          Text('View Enrollments'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'device_info',
                      child: Row(
                        children: [
                          Icon(Icons.devices, color: Colors.blue),
                          SizedBox(width: 10),
                          Text('View Device Info'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle_status',
                      child: Row(
                        children: [
                          Icon(
                            (student.disabled == true) ? Icons.check_circle : Icons.block, 
                            color: (student.disabled == true) ? Colors.green : Colors.orange
                          ),
                          const SizedBox(width: 10),
                          Text((student.disabled == true) ? 'Activate Account' : 'Deactivate Account'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 10),
                          Text('Delete Student'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _currentPage > 1 ? () => _changePage(_currentPage - 1) : null,
        ),
        Text('Page $_currentPage of $_totalPages'),
        IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: _currentPage < _totalPages ? () => _changePage(_currentPage + 1) : null,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void dispose() {
    _searchController.dispose();
    _adminService.dispose();
    super.dispose();
  }


}

// Student Enrollments Modal Widget
class StudentEnrollmentsModal extends StatelessWidget {
  final StudentDetail studentDetail;
  final VoidCallback onClose;
  final bool isLoading;

  const StudentEnrollmentsModal({
    super.key,
    required this.studentDetail,
    required this.onClose,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Dialog(
        child: Container(
          padding: const EdgeInsets.all(30),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Loading student enrollments...'),
            ],
          ),
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.primaryGreen,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      studentDetail.user.fullName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
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
                          'Course Enrollments',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${studentDetail.user.fullName} - ${studentDetail.enrollments.length} Courses',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: onClose,
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Cards
                    Row(
                      children: [
                        _buildStatCard(
                          context,
                          'Total Enrollments',
                          studentDetail.totalEnrollments.toString(),
                          Icons.school,
                          AppTheme.primaryGreen,
                        ),
                        const SizedBox(width: 15),
                        _buildStatCard(
                          context,
                          'Completed',
                          studentDetail.completedCourses.toString(),
                          Icons.check_circle,
                          Colors.green,
                        ),
                        const SizedBox(width: 15),
                        _buildStatCard(
                          context,
                          'In Progress',
                          studentDetail.inProgressCourses.toString(),
                          Icons.timelapse,
                          AppTheme.accent,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Enrollments Section
                    _buildEnrollmentsSection(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.greyColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnrollmentsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enrolled Courses',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.blackColor,
          ),
        ),
        const SizedBox(height: 15),
        if (studentDetail.enrollments.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.greyColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'No course enrollments found',
              style: TextStyle(color: AppTheme.greyColor),
            ),
          )
        else
          ...studentDetail.enrollments.asMap().entries.map((entry) {
            final index = entry.key;
            final enrollment = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.greyColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.school,
                      color: AppTheme.primaryGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getCourseTitle(enrollment),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(enrollment.completionStatus)
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                enrollment.statusDisplay,
                                style: TextStyle(
                                  color: _getStatusColor(enrollment.completionStatus),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Progress: ${enrollment.progressDisplay}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.greyColor,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Enrolled: ${_formatDateSimple(enrollment.enrollmentDate)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.greyColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'RWF ${enrollment.course?.price ?? 0}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  String _getCourseTitle(Enrollment enrollment) {
    // Try to get the title from the populated course object
    if (enrollment.course != null && 
        enrollment.course!.title.isNotEmpty && 
        enrollment.course!.title != 'Untitled Course' &&
        enrollment.course!.title != 'Unknown Course') {
      return enrollment.course!.title;
    }
    
    // If the course object wasn't properly populated, check if there's course data in the raw enrollment object
    // Sometimes the course data might be in a different format
    if (enrollment.courseId.isNotEmpty && enrollment.courseId != '') {
      // Use courseId as fallback, though ideally we'd have the course title
      return 'Course ID: ${enrollment.courseId}';
    }
    
    // If the course object wasn't properly populated, return a default value
    // The backend might not have populated the course details
    return 'Course Title Unknown';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'in-progress':
        return AppTheme.accent;
      case 'enrolled':
        return AppTheme.primaryGreen;
      default:
        return AppTheme.greyColor;
    }
  }

  String _formatDateSimple(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// Student Detail Modal Widget
class StudentDetailModal extends StatelessWidget {
  final StudentDetail studentDetail;
  final VoidCallback onClose;
  final bool isLoading;
  final VoidCallback? onResetDevice;

  const StudentDetailModal({
    super.key,
    required this.studentDetail,
    required this.onClose,
    required this.isLoading,
    this.onResetDevice,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Dialog(
        child: Container(
          padding: const EdgeInsets.all(30),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Loading student details...'),
            ],
          ),
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.primaryGreen,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      studentDetail.user.fullName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
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
                          studentDetail.user.fullName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          studentDetail.user.email,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: onClose,
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Cards
                    _buildSummaryCards(context),
                    
                    const SizedBox(height: 20),
                    
                    // Enrollments Section
                    _buildEnrollmentsSection(context),
                    
                    const SizedBox(height: 20),
                    
                    // Activity Timeline
                    _buildActivityTimeline(context),
                    
                    const SizedBox(height: 20),
                    
                    // Device Info Section
                    _buildDeviceInfoSection(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceInfoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Device Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.blackColor,
          ),
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppTheme.greyColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Device Binding Status:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(
                studentDetail.user.deviceId != null && studentDetail.user.deviceId!.isNotEmpty 
                    ? 'Bound to device'
                    : 'Not bound to device',
                style: TextStyle(
                  color: studentDetail.user.deviceId != null && studentDetail.user.deviceId!.isNotEmpty ? Colors.green : Colors.orange,
                ),
              ),
              if (studentDetail.user.deviceId != null && studentDetail.user.deviceId!.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Device ID:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                SelectableText(
                  studentDetail.user.deviceId!,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ],
              if (onResetDevice != null) ...[
                const SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: onResetDevice,
                  icon: const Icon(Icons.sync_problem, size: 16),
                  label: const Text('Reset Device Binding'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildSummaryCards(BuildContext context) {
    return Row(
      children: [
        _buildStatCard(
          context,
          'Total Enrollments',
          studentDetail.totalEnrollments.toString(),
          Icons.school,
          AppTheme.primaryGreen,
        ),
        const SizedBox(width: 15),
        _buildStatCard(
          context,
          'Completed',
          studentDetail.completedCourses.toString(),
          Icons.check_circle,
          Colors.green,
        ),
        const SizedBox(width: 15),
        _buildStatCard(
          context,
          'In Progress',
          studentDetail.inProgressCourses.toString(),
          Icons.timelapse,
          AppTheme.accent,
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.greyColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnrollmentsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Course Enrollments',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.blackColor,
          ),
        ),
        const SizedBox(height: 15),
        if (studentDetail.enrollments.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.greyColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'No course enrollments found',
              style: TextStyle(color: AppTheme.greyColor),
            ),
          )
        else
          ...studentDetail.enrollments.asMap().entries.map((entry) {
            final index = entry.key;
            final enrollment = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.greyColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.school,
                      color: AppTheme.primaryGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          enrollment.course?.title ?? 'Unknown Course',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(enrollment.completionStatus)
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                enrollment.statusDisplay,
                                style: TextStyle(
                                  color: _getStatusColor(enrollment.completionStatus),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Progress: ${enrollment.progressDisplay}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.greyColor,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Enrolled: ${_formatDateSimple(enrollment.enrollmentDate)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.greyColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'RWF ${enrollment.course?.price ?? 0}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildActivityTimeline(BuildContext context) {
    final List<Map<String, dynamic>> activities = [];
    
    // Add enrollments to activities
    for (var enrollment in studentDetail.enrollments) {
      activities.add({
        'type': 'enrollment',
        'title': 'Enrolled in Course',
        'subtitle': enrollment.course?.title ?? 'Unknown Course',
        'date': enrollment.enrollmentDate,
        'icon': Icons.school,
        'color': AppTheme.primaryGreen,
      });
    }
    
    // Add payments to activities
    for (var payment in studentDetail.payments) {
      final date = payment['paymentDate'] != null 
          ? DateTime.parse(payment['paymentDate'].toString())
          : (payment['createdAt'] != null ? DateTime.parse(payment['createdAt'].toString()) : DateTime.now());
      
      activities.add({
        'type': 'payment',
        'title': 'Payment Completed',
        'subtitle': 'RWF ${payment['amount']} for ${payment['courseId']?['title'] ?? 'a course'}',
        'date': date,
        'icon': Icons.payment,
        'color': Colors.blue,
      });
    }
    
    // Add exam results to activities
    for (var result in studentDetail.examResults) {
      final date = result['submittedAt'] != null 
          ? DateTime.parse(result['submittedAt'].toString())
          : DateTime.now();
      
      final bool passed = result['passed'] == true;
      
      activities.add({
        'type': 'exam',
        'title': passed ? 'Exam Passed' : 'Exam Failed',
        'subtitle': '${result['examId']?['title'] ?? 'Unknown Exam'} - Score: ${result['score']}/${result['totalPoints']}',
        'date': date,
        'icon': passed ? Icons.check_circle : Icons.cancel,
        'color': passed ? Colors.green : Colors.red,
      });
    }
    
    // Sort by date newest first
    activities.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.blackColor,
          ),
        ),
        const SizedBox(height: 15),
        if (activities.isEmpty)
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppTheme.greyColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'No recent activity recorded',
              style: TextStyle(color: AppTheme.greyColor),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length > 5 ? 5 : activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (activity['color'] as Color).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            activity['icon'] as IconData,
                            color: activity['color'] as Color,
                            size: 16,
                          ),
                        ),
                        if (index < (activities.length > 5 ? 4 : activities.length - 1))
                          Container(
                            width: 2,
                            height: 30,
                            color: AppTheme.greyColor.withOpacity(0.2),
                          ),
                      ],
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                activity['title'] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                _formatDateSimple(activity['date'] as DateTime),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.greyColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            activity['subtitle'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.greyColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'in-progress':
        return AppTheme.accent;
      case 'enrolled':
        return AppTheme.primaryGreen;
      default:
        return AppTheme.greyColor;
    }
  }

  String _formatDateSimple(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

}