import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'dart:convert';

import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/config/api_config.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';
import 'package:excellencecoachinghub/services/api/course_service.dart';
import 'package:excellencecoachinghub/models/course.dart';
import 'package:excellencecoachinghub/models/user.dart';
import 'package:excellencecoachinghub/presentation/providers/admin_course_provider.dart';

class AdminBooksScreen extends ConsumerStatefulWidget {
  const AdminBooksScreen({super.key});

  @override
  ConsumerState<AdminBooksScreen> createState() => _AdminBooksScreenState();
}

class _AdminBooksScreenState extends ConsumerState<AdminBooksScreen> {
  List<dynamic> _books = [];
  bool _isLoading = true;
  bool _isUploading = false;
  String? _errorMessage;

  // Form controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  String _selectedLanguage = 'en';
  String? _selectedAcademicCategory;
  List<String> _selectedCourseIds = [];
  final TextEditingController _courseSearchController = TextEditingController();

  // File selection
  File? _pdfFile;
  File? _coverFile;
  String? _pdfFileName;
  String? _coverFileName;

  // Upload result
  String? _pdfUrl;
  String? _pdfS3Key;
  String? _coverUrl;
  String? _coverS3Key;
  int? _fileSize;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    _courseSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final idToken = await user.getIdToken(true);
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/books/admin/all'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _books = data['data']['books'];
            _isLoading = false;
          });
        } else {
          throw Exception(data['message'] ?? 'Failed to load books');
        }
      } else {
        throw Exception('Failed to load books: ${response.statusCode}');
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _pickPDF() async {
    try {
      final result = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (result != null) {
        setState(() {
          _pdfFile = File(result.path);
          _pdfFileName = result.name;
        });
      }
    } catch (error) {
      _showErrorSnackBar('Failed to pick PDF: $error');
    }
  }

  Future<void> _pickCover() async {
    try {
      final result = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (result != null) {
        setState(() {
          _coverFile = File(result.path);
          _coverFileName = result.name;
        });
      }
    } catch (error) {
      _showErrorSnackBar('Failed to pick cover: $error');
    }
  }

  Future<void> _uploadFiles() async {
    if (_pdfFile == null) {
      _showErrorSnackBar('Please select a PDF file');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final idToken = await user.getIdToken(true);

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/books/upload-files'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $idToken',
      });

      // Add PDF file
      final pdfBytes = await _pdfFile!.readAsBytes();
      final pdfMultipartFile = http.MultipartFile.fromBytes(
        'pdf',
        pdfBytes,
        filename: _pdfFileName!,
        contentType: MediaType('application', 'pdf'),
      );
      request.files.add(pdfMultipartFile);

      // Add cover file if selected
      if (_coverFile != null) {
        final coverBytes = await _coverFile!.readAsBytes();
        final coverMultipartFile = http.MultipartFile.fromBytes(
          'cover',
          coverBytes,
          filename: _coverFileName!,
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(coverMultipartFile);
      }

      // Send request
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = json.decode(responseBody);

        if (data['success'] == true) {
          setState(() {
            _pdfUrl = data['data']['pdfUrl'];
            _pdfS3Key = data['data']['pdfS3Key'];
            _coverUrl = data['data']['coverUrl'];
            _coverS3Key = data['data']['coverS3Key'];
            _fileSize = data['data']['fileSize'];
            _isUploading = false;
          });

          _showSuccessSnackBar('Files uploaded successfully');
        } else {
          throw Exception(data['message'] ?? 'Upload failed');
        }
      } else {
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } catch (error) {
      setState(() {
        _isUploading = false;
      });
      _showErrorSnackBar('Failed to upload files: $error');
    }
  }

  Future<void> _createBook() async {
    if (_titleController.text.isEmpty || _authorController.text.isEmpty) {
      _showErrorSnackBar('Please fill in title and author');
      return;
    }

    if (_subjectController.text.isEmpty) {
      _showErrorSnackBar('Please fill in subject');
      return;
    }

    if (_pdfUrl == null || _pdfS3Key == null) {
      _showErrorSnackBar('Please upload PDF file first');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final idToken = await user.getIdToken(true);

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/books'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'title': _titleController.text,
          'author': _authorController.text,
          'description': _descriptionController.text,
          'pdfUrl': _pdfUrl,
          'pdfS3Key': _pdfS3Key,
          'coverUrl': _coverUrl,
          'coverS3Key': _coverS3Key,
          'language': _selectedLanguage,
          'subject': _subjectController.text,
          'academicCategory': _selectedAcademicCategory,
          'relatedCourses': _selectedCourseIds,
          'fileSize': _fileSize,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _showSuccessSnackBar('Book created successfully');
          _resetForm();
          _loadBooks();
        } else {
          throw Exception(data['message'] ?? 'Failed to create book');
        }
      } else {
        throw Exception('Failed to create book: ${response.statusCode}');
      }
    } catch (error) {
      _showErrorSnackBar('Failed to create book: $error');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _deleteBook(String bookId) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = AppTheme.getTextColor(context);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
        title: Text('Delete Book', style: TextStyle(color: textColor)),
        content: Text('Are you sure you want to delete this book?', 
            style: TextStyle(color: textColor)),
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

    if (confirmed != true) return;

    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final idToken = await user.getIdToken(true);

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/books/$bookId'),
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        _showSuccessSnackBar('Book deleted successfully');
        _loadBooks();
      } else {
        throw Exception('Failed to delete book: ${response.statusCode}');
      }
    } catch (error) {
      _showErrorSnackBar('Failed to delete book: $error');
    }
  }


  void _resetForm() {
    setState(() {
      _titleController.clear();
      _authorController.clear();
      _descriptionController.clear();
      _subjectController.clear();
      _selectedLanguage = 'en';
      _selectedAcademicCategory = null;
      _selectedCourseIds = [];
      _pdfFile = null;
      _coverFile = null;
      _pdfFileName = null;
      _coverFileName = null;
      _pdfUrl = null;
      _pdfS3Key = null;
      _coverUrl = null;
      _coverS3Key = null;
      _fileSize = null;
    });
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = AppTheme.getTextColor(context);
    final secondaryTextColor = AppTheme.getSecondaryTextColor(context);
    final cardColor = isDark ? const Color(0xFF1F2937) : Colors.white;
    final borderColor = isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    final surfaceColor = isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: borderColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  if (context.canPop())
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_rounded, color: textColor),
                      onPressed: () => context.pop(),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    'Manage Books',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _showAddBookDialog(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Book'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryGreen),
                    )
                  : _errorMessage != null
                      ? _buildErrorWidget()
                      : _buildBooksList(context, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = AppTheme.getTextColor(context);
    final secondaryTextColor = AppTheme.getSecondaryTextColor(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: isDark ? const Color(0xFFF87171) : Colors.red,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading books',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Something went wrong',
            style: TextStyle(
              fontSize: 14,
              color: secondaryTextColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadBooks,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildBooksList(BuildContext context, bool isDark) {
    final textColor = AppTheme.getTextColor(context);
    final secondaryTextColor = AppTheme.getSecondaryTextColor(context);
    
    if (_books.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_rounded,
              color: secondaryTextColor,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'No books uploaded yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Click "Add Book" to upload your first book',
              style: TextStyle(
                fontSize: 14,
                color: secondaryTextColor,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBooks,
      color: AppTheme.primaryGreen,
      child: ListView.builder(
        padding: ResponsiveBreakpoints.getPadding(context),
        itemCount: _books.length,
        itemBuilder: (context, index) {
          final book = _books[index];
          return _buildBookCard(context, book, isDark);
        },
      ),
    );
  }

  Widget _buildBookCard(BuildContext context, dynamic book, bool isDark) {
    final textColor = AppTheme.getTextColor(context);
    final secondaryTextColor = AppTheme.getSecondaryTextColor(context);
    final cardColor = isDark ? const Color(0xFF1F2937) : Colors.white;
    final borderColor = isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Row(
        children: [
          // Book cover
          Container(
            width: 60,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: book['coverUrl'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      book['coverUrl'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.menu_book_rounded,
                          color: AppTheme.primaryGreen,
                          size: 32,
                        );
                      },
                    ),
                  )
                : Icon(
                    Icons.menu_book_rounded,
                    color: AppTheme.primaryGreen,
                    size: 32,
                  ),
          ),
          const SizedBox(width: 16),
          // Book info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book['title'] ?? 'Untitled',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  book['author'] ?? 'Unknown Author',
                  style: TextStyle(
                    fontSize: 14,
                    color: secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        book['subject'] ?? 'Other',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      book['language']?.toUpperCase() ?? 'EN',
                      style: TextStyle(
                        fontSize: 12,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Actions
          Row(
            children: [
              IconButton(
                icon: Icon(
                  book['isPublished'] ? Icons.visibility : Icons.visibility_off,
                  color: book['isPublished'] ? AppTheme.primaryGreen : Colors.grey,
                ),
                onPressed: () {
                  // Toggle publish status (to be implemented)
                },
                tooltip: book['isPublished'] ? 'Published' : 'Unpublished',
              ),
              IconButton(
                icon: const Icon(Icons.delete_rounded, color: Colors.red),
                onPressed: () => _deleteBook(book['_id']),
                tooltip: 'Delete',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddBookDialog(BuildContext context) {
    // Load courses via provider when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminCourseProvider.notifier).loadCourses();
    });
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: ResponsiveBreakpoints.isDesktop(context) ? 600 : double.infinity,
          constraints: const BoxConstraints(maxHeight: 800),
          child: AddBookDialog(
            titleController: _titleController,
            authorController: _authorController,
            descriptionController: _descriptionController,
            subjectController: _subjectController,
            selectedLanguage: _selectedLanguage,
            selectedAcademicCategory: _selectedAcademicCategory,
            selectedCourseIds: _selectedCourseIds,
            pdfFile: _pdfFile,
            coverFile: _coverFile,
            pdfFileName: _pdfFileName,
            coverFileName: _coverFileName,
            pdfUrl: _pdfUrl,
            pdfS3Key: _pdfS3Key,
            coverUrl: _coverUrl,
            coverS3Key: _coverS3Key,
            fileSize: _fileSize,
            isUploading: _isUploading,
            onSubjectChanged: (value) => setState(() => _subjectController.text = value),
            onLanguageChanged: (value) => setState(() => _selectedLanguage = value),
            onAcademicCategoryChanged: (value) => setState(() => _selectedAcademicCategory = value),
            onCourseIdsChanged: (value) => setState(() => _selectedCourseIds = value),
            onPickPDF: _pickPDF,
            onPickCover: _pickCover,
            onUploadFiles: _uploadFiles,
            onCreateBook: _createBook,
            onReset: _resetForm,
            onClose: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }
}

class AddBookDialog extends ConsumerStatefulWidget {
  final TextEditingController titleController;
  final TextEditingController authorController;
  final TextEditingController descriptionController;
  final TextEditingController subjectController;
  final String selectedLanguage;
  final String? selectedAcademicCategory;
  final List<String> selectedCourseIds;
  final File? pdfFile;
  final File? coverFile;
  final String? pdfFileName;
  final String? coverFileName;
  final String? pdfUrl;
  final String? pdfS3Key;
  final String? coverUrl;
  final String? coverS3Key;
  final int? fileSize;
  final bool isUploading;
  final Function(String) onSubjectChanged;
  final Function(String) onLanguageChanged;
  final Function(String?) onAcademicCategoryChanged;
  final Function(List<String>) onCourseIdsChanged;
  final Function() onPickPDF;
  final Function() onPickCover;
  final Function() onUploadFiles;
  final Function() onCreateBook;
  final Function() onReset;
  final Function() onClose;

  const AddBookDialog({
    super.key,
    required this.titleController,
    required this.authorController,
    required this.descriptionController,
    required this.subjectController,
    required this.selectedLanguage,
    required this.selectedAcademicCategory,
    required this.selectedCourseIds,
    required this.pdfFile,
    required this.coverFile,
    required this.pdfFileName,
    required this.coverFileName,
    required this.pdfUrl,
    required this.pdfS3Key,
    required this.coverUrl,
    required this.coverS3Key,
    required this.fileSize,
    required this.isUploading,
    required this.onSubjectChanged,
    required this.onLanguageChanged,
    required this.onAcademicCategoryChanged,
    required this.onCourseIdsChanged,
    required this.onPickPDF,
    required this.onPickCover,
    required this.onUploadFiles,
    required this.onCreateBook,
    required this.onReset,
    required this.onClose,
  });

  @override
  ConsumerState<AddBookDialog> createState() => _AddBookDialogState();
}

class _AddBookDialogState extends ConsumerState<AddBookDialog> {
  final TextEditingController _courseSearchController = TextEditingController();

  @override
  void dispose() {
    _courseSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = AppTheme.getTextColor(context);
    final secondaryTextColor = AppTheme.getSecondaryTextColor(context);
    final cardColor = isDark ? const Color(0xFF1F2937) : Colors.white;
    final borderColor = isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    final surfaceColor = isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6);

    // Watch the admin course provider
    final courseState = ref.watch(adminCourseProvider);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: borderColor,
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Add New Book',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: textColor),
                  onPressed: widget.onClose,
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
                  // Title
                  TextField(
                    controller: widget.titleController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: 'Book Title',
                      labelStyle: TextStyle(color: textColor),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppTheme.primaryGreen),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Author
                  TextField(
                    controller: widget.authorController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: 'Author',
                      labelStyle: TextStyle(color: textColor),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppTheme.primaryGreen),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Description
                  TextField(
                    controller: widget.descriptionController,
                    maxLines: 3,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      labelStyle: TextStyle(color: textColor),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppTheme.primaryGreen),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Subject (text input instead of dropdown)
                  TextField(
                    controller: widget.subjectController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: 'Subject',
                      labelStyle: TextStyle(color: textColor),
                      hintText: 'e.g., Mathematics, Physics, Computer Science',
                      hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppTheme.primaryGreen),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Related Courses (Optional)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Related Courses (Optional)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Link this book to courses so students can easily find it',
                          style: TextStyle(
                            fontSize: 12,
                            color: secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (widget.selectedCourseIds.isEmpty)
                          Text(
                            'No courses selected',
                            style: TextStyle(
                              fontSize: 12,
                              color: secondaryTextColor,
                            ),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: widget.selectedCourseIds.map((courseId) {
                              final course = courseState.courses.firstWhere(
                                (c) => c.id == courseId,
                                orElse: () => Course(
                                  id: courseId,
                                  title: 'Unknown Course',
                                  description: '',
                                  duration: 0,
                                  level: '',
                                  isPublished: false,
                                  createdAt: DateTime.now(),
                                  createdBy: User(
                                    id: '',
                                    fullName: '',
                                    email: '',
                                    role: '',
                                    createdAt: DateTime.now(),
                                  ),
                                ),
                              );
                              return Chip(
                                label: Text(course.title, overflow: TextOverflow.ellipsis, maxLines: 1),
                                onDeleted: () {
                                  final updated = List<String>.from(widget.selectedCourseIds);
                                  updated.remove(courseId);
                                  widget.onCourseIdsChanged(updated);
                                },
                              );
                            }).toList(),
                          ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            _showCourseSelectionDialog(context, courseState);
                          },
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add Courses'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Language
                  DropdownButtonFormField<String>(
                    value: widget.selectedLanguage,
                    style: TextStyle(color: textColor),
                    dropdownColor: cardColor,
                    decoration: InputDecoration(
                      labelText: 'Language',
                      labelStyle: TextStyle(color: textColor),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppTheme.primaryGreen),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('English')),
                      DropdownMenuItem(value: 'rw', child: Text('Kinyarwanda')),
                      DropdownMenuItem(value: 'fr', child: Text('French')),
                    ],
                    onChanged: (value) => widget.onLanguageChanged(value!),
                  ),
                  const SizedBox(height: 16),
                  // PDF Upload
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PDF File',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (widget.pdfFileName != null)
                          Row(
                            children: [
                              const Icon(Icons.check_circle, color: AppTheme.primaryGreen),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.pdfFileName!,
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: widget.onPickPDF,
                            icon: const Icon(Icons.upload_file_rounded),
                            label: const Text('Select PDF'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        if (widget.pdfUrl != null) ...[
                          const SizedBox(height: 8),
                          const Text(
                            '✓ PDF uploaded to cloud',
                            style: TextStyle(
                              color: AppTheme.primaryGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Cover Upload
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cover Image (Optional)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (widget.coverFileName != null)
                          Row(
                            children: [
                              const Icon(Icons.check_circle, color: AppTheme.primaryGreen),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.coverFileName!,
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: widget.onPickCover,
                            icon: const Icon(Icons.image_rounded),
                            label: const Text('Select Cover'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        if (widget.coverUrl != null) ...[
                          const SizedBox(height: 8),
                          const Text(
                            '✓ Cover uploaded to cloud',
                            style: TextStyle(
                              color: AppTheme.primaryGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Upload Files Button
                  if (widget.pdfFile != null && widget.pdfUrl == null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: widget.isUploading ? null : widget.onUploadFiles,
                        icon: widget.isUploading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.cloud_upload_rounded),
                        label: Text(widget.isUploading ? 'Uploading...' : 'Upload Files to Cloud'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: borderColor,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onReset,
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (widget.pdfUrl != null && widget.pdfS3Key != null) && !widget.isUploading
                        ? widget.onCreateBook
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                    ),
                    child: widget.isUploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Create Book'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCourseSelectionDialog(BuildContext context, AdminCourseState courseState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = AppTheme.getTextColor(context);
    final secondaryTextColor = AppTheme.getSecondaryTextColor(context);
    final cardColor = isDark ? const Color(0xFF1F2937) : Colors.white;
    final borderColor = isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    final surfaceColor = isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6);

    // Reset search when dialog opens
    _courseSearchController.clear();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Filter courses based on search
          final searchQuery = _courseSearchController.text.toLowerCase();
          final filteredCourses = searchQuery.isEmpty
              ? courseState.courses
              : courseState.courses.where((course) {
                  return course.title.toLowerCase().contains(searchQuery) ||
                      course.description.toLowerCase().contains(searchQuery);
                }).toList();

          return Dialog(
            child: Container(
              width: ResponsiveBreakpoints.isDesktop(context) ? 600 : double.infinity,
              constraints: const BoxConstraints(maxHeight: 600),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: borderColor),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Select Courses',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: textColor),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  // Search
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _courseSearchController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'Search courses',
                        labelStyle: TextStyle(color: textColor),
                        hintText: 'Search by title or description',
                        hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                        prefixIcon: Icon(Icons.search, color: textColor),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppTheme.primaryGreen),
                        ),
                      ),
                      onChanged: (value) {
                        setDialogState(() {});
                      },
                      onSubmitted: (value) {
                        // Trigger backend search
                        ref.read(adminCourseProvider.notifier).searchCourses(value);
                      },
                    ),
                  ),
                  // Course List
                  Expanded(
                    child: courseState.isLoading && courseState.courses.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(color: AppTheme.primaryGreen),
                                SizedBox(height: 16),
                                Text('Loading courses...'),
                              ],
                            ),
                          )
                        : courseState.error != null && courseState.courses.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.error, color: Colors.red, size: 48),
                                    SizedBox(height: 16),
                                    Text(
                                      'Error: ${courseState.error}',
                                      style: TextStyle(color: Colors.red),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () {
                                        ref.read(adminCourseProvider.notifier).loadCourses();
                                      },
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              )
                            : filteredCourses.isEmpty
                                ? Center(
                                    child: Text(
                                      searchQuery.isEmpty
                                          ? 'No courses available'
                                          : 'No courses match your search',
                                      style: TextStyle(color: secondaryTextColor),
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    itemCount: filteredCourses.length,
                                    itemBuilder: (context, index) {
                                      final course = filteredCourses[index];
                                      final isSelected = widget.selectedCourseIds.contains(course.id);
                                      return CheckboxListTile(
                                        value: isSelected,
                                        onChanged: (value) {
                                          final updated = List<String>.from(widget.selectedCourseIds);
                                          if (value == true) {
                                            if (!updated.contains(course.id)) {
                                              updated.add(course.id);
                                            }
                                          } else {
                                            updated.remove(course.id);
                                          }
                                          widget.onCourseIdsChanged(updated);
                                          setDialogState(() {});
                                        },
                                        title: Text(
                                          course.title,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: textColor,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: Text(
                                          course.description,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: secondaryTextColor,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        secondary: course.thumbnail != null
                                            ? ClipRRect(
                                                borderRadius: BorderRadius.circular(4),
                                                child: Image.network(
                                                  course.thumbnail!,
                                                  width: 48,
                                                  height: 48,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Container(
                                                      width: 48,
                                                      height: 48,
                                                      color: surfaceColor,
                                                      child: Icon(
                                                        Icons.school_rounded,
                                                        color: secondaryTextColor,
                                                        size: 24,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              )
                                            : Container(
                                                width: 48,
                                                height: 48,
                                                decoration: BoxDecoration(
                                                  color: surfaceColor,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Icon(
                                                  Icons.school_rounded,
                                                  color: secondaryTextColor,
                                                  size: 24,
                                                ),
                                              ),
                                      );
                                    },
                                  ),
                  ),
                  // Footer
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: borderColor),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${widget.selectedCourseIds.length} course(s) selected',
                          style: TextStyle(
                            fontSize: 14,
                            color: secondaryTextColor,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Done'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
