import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/services/admin_service.dart';
import 'package:excellencecoachinghub/models/user.dart';

class AdminManagementScreen extends ConsumerStatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  ConsumerState<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends ConsumerState<AdminManagementScreen> {
  final AdminService _adminService = AdminService();
  bool _isLoading = false;
  List<User> _admins = [];
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAdmins();
  }

  Future<void> _loadAdmins({String? searchQuery}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final adminsData = await _adminService.getAdmins(
        page: _currentPage,
        search: searchQuery,
      );
      
      if (!mounted) return;
      setState(() {
        _admins = adminsData.admins;
        _totalPages = adminsData.totalPages;
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

  Future<void> _toggleAdminStatus(User adminUser, bool disabled) async {
    try {
      await _adminService.toggleStudentStatus(adminUser.id, disabled);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${adminUser.fullName} ${disabled ? 'deactivated' : 'activated'} successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadAdmins(searchQuery: _searchController.text);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteAdmin(User adminUser) async {
    try {
      await _adminService.deleteStudent(adminUser.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${adminUser.fullName} deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadAdmins(searchQuery: _searchController.text);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _promoteToAdmin(String userId) async {
    try {
      await _adminService.updateUserRole(userId, 'admin');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User promoted to admin successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadAdmins(searchQuery: _searchController.text);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error promoting user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPromoteDialog() {
    showDialog(
      context: context,
      builder: (context) => PromoteAdminDialog(
        onPromote: (userId) {
          _promoteToAdmin(userId);
        },
      ),
    );
  }

  void _showDeactivateDialog(User adminUser) {
    final bool isDeactivating = adminUser.disabled != true;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isDeactivating ? 'Deactivate Admin' : 'Activate Admin'),
        content: Text('Are you sure you want to ${isDeactivating ? 'deactivate' : 'activate'} ${adminUser.fullName}\'s account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _toggleAdminStatus(adminUser, isDeactivating);
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

  void _showDeleteDialog(User adminUser) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Admin'),
        content: Text('Are you sure you want to permanently delete ${adminUser.fullName}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAdmin(adminUser);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Management'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadAdmins(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Management',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Manage platform administrators',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _showPromoteDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Admin'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search admins...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                _currentPage = 1;
                _loadAdmins(searchQuery: value);
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                  ? Center(child: Text(_errorMessage!))
                  : _admins.isEmpty
                    ? const Center(child: Text('No admins found'))
                    : ListView.builder(
                        itemCount: _admins.length,
                        itemBuilder: (context, index) {
                          final adminUser = _admins[index];
                          final isMe = adminUser.id == currentUser?.id;
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                                child: Text(adminUser.fullName[0].toUpperCase()),
                              ),
                              title: Text(adminUser.fullName),
                              subtitle: Text(adminUser.email),
                              trailing: isMe 
                                ? const Chip(label: Text('You'))
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          adminUser.disabled == true 
                                            ? Icons.play_arrow 
                                            : Icons.pause,
                                          color: adminUser.disabled == true ? Colors.green : Colors.orange,
                                        ),
                                        onPressed: () => _showDeactivateDialog(adminUser),
                                        tooltip: adminUser.disabled == true ? 'Activate' : 'Deactivate',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _showDeleteDialog(adminUser),
                                        tooltip: 'Delete',
                                      ),
                                    ],
                                  ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class PromoteAdminDialog extends StatefulWidget {
  final Function(String) onPromote;

  const PromoteAdminDialog({super.key, required this.onPromote});

  @override
  State<PromoteAdminDialog> createState() => _PromoteAdminDialogState();
}

class _PromoteAdminDialogState extends State<PromoteAdminDialog> {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();
  List<User> _students = [];
  bool _isLoading = false;

  Future<void> _searchStudents(String query) async {
    if (query.isEmpty) {
      setState(() => _students = []);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await _adminService.getStudents(search: query, source: 'firebase');
      setState(() {
        _students = result.students;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Promote Student to Admin'),
      content: SizedBox(
        width: 400,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _searchStudents,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _students.length,
                    itemBuilder: (context, index) {
                      final student = _students[index];
                      return ListTile(
                        title: Text(student.fullName),
                        subtitle: Text(student.email),
                        trailing: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onPromote(student.id);
                          },
                          child: const Text('Promote'),
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
