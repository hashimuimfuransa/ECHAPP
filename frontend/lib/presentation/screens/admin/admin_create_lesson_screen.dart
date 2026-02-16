import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../config/app_theme.dart';
import '../../../config/api_config.dart';
import '../../../data/repositories/lesson_repository.dart';
import '../../../data/repositories/video_repository.dart';
import '../../../models/video.dart';
import '../../../presentation/providers/content_management_provider.dart';
import '../../../services/document/lesson_document_service.dart';
import '../../../services/infrastructure/api_client.dart';

class AdminCreateLessonScreen extends ConsumerStatefulWidget {
  final String courseId;
  final String sectionId;

  const AdminCreateLessonScreen({
    super.key,
    required this.courseId,
    required this.sectionId,
  });

  @override
  ConsumerState<AdminCreateLessonScreen> createState() => _AdminCreateLessonScreenState();
}

class _AdminCreateLessonScreenState extends ConsumerState<AdminCreateLessonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String? _selectedVideoId;
  String? _documentPath; // Store document path from S3
  int _duration = 0;
  bool _isLoading = false;
  bool _isUploadingVideo = false;
  bool _isUploadingDocument = false; // Track document upload status
  String? _errorMessage;
  List<Video> _videos = [];
  final ImagePicker _picker = ImagePicker();
  final ApiClient _apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    // Validate required parameters
    if (widget.courseId.isEmpty || widget.sectionId.isEmpty) {
      throw ArgumentError('Course ID and Section ID must not be empty');
    }
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final videoRepo = VideoRepository();
      // Load videos specifically for this course
      final videos = await videoRepo.getVideosByCourse(widget.courseId);
      setState(() {
        _videos = videos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _createLesson() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // If we're currently uploading a video, wait for it to complete
      // The lesson creation logic will be in the _handleVideoUpload function

      if (mounted) {
        final lessonRepo = LessonRepository();
        // Get the next order number by counting existing lessons in this section
        final lessonsInSection = await lessonRepo.getLessonsBySection(widget.sectionId);
        final nextOrder = lessonsInSection.length + 1;
        
        // Use createLessonWithDocument if documentPath is available, otherwise use regular createLesson
        if (_documentPath != null) {
          await lessonRepo.createLessonWithDocument(
            courseId: widget.courseId,
            sectionId: widget.sectionId,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            documentPath: _documentPath, // Use document path instead of text notes
            order: nextOrder, // Set order to next available
            duration: _duration,
          );
        } else {
          await lessonRepo.createLesson(
            courseId: widget.courseId,
            sectionId: widget.sectionId,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            videoId: _selectedVideoId,
            notes: null, // No notes if no document
            order: nextOrder, // Set order to next available
            duration: _duration,
          );
        }
        
        // Refresh the content management provider
        ref.read(contentManagementProvider.notifier).loadSections(widget.courseId);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lesson created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back to course content
        context.pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleVideoUpload() async {
    try {
      final XFile? videoFile = await _picker.pickVideo(source: ImageSource.gallery);
      
      if (videoFile == null) return;

      setState(() {
        _isUploadingVideo = true;
        _errorMessage = null;
      });

      final videoRepo = VideoRepository();
      final video = await videoRepo.uploadVideo(
        videoFile: videoFile,
        courseId: widget.courseId,
        sectionId: widget.sectionId,
        title: _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : null,
        description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
        createLesson: false, // Disable automatic lesson creation during upload
        onProgress: (progress) {
          // Handle progress updates if needed
          print('Upload progress: $progress%');
        },
      );

      setState(() {
        _isUploadingVideo = false;
        _selectedVideoId = video.id;
        // Update the videos list with the newly uploaded video
        _videos = [..._videos, video];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploadingVideo = false;
        _errorMessage = e.toString();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleDocumentUpload() async {
    try {
      // Pick a document file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'ppt', 'pptx', 'xls', 'xlsx'],
      );
      
      if (result == null) return;

      final file = result.files.single;
      setState(() {
        _isUploadingDocument = true;
        _errorMessage = null;
      });

      // Upload the document to the backend (this will create a lesson automatically)
      // Handle web vs mobile platform differences
      print('=== PLATFORM CHECK ===');
      print('Is web: $kIsWeb');
      print('File path: ${file.path}');
      print('File bytes available: ${file.bytes != null}');
      print('=====================');
      
      Map<String, dynamic> responseData;
      
      if (kIsWeb) {
        print('=== WEB UPLOAD PATH ===');
        // On web, use LessonDocumentService with PlatformFile
        try {
          final lessonDocumentService = LessonDocumentService();
          print('Calling LessonDocumentService with file: ${file.name}');
          responseData = await lessonDocumentService.uploadDocumentForLessonNotes(
            file: file,
            courseId: widget.courseId,
            sectionId: widget.sectionId,
            title: _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : file.name,
            description: _descriptionController.text.trim(),
          );
          print('Web upload successful, response: $responseData');
        } catch (e) {
          print('=== WEB UPLOAD ERROR ===');
          print('Error type: ${e.runtimeType}');
          print('Error message: $e');
          print('Stack trace: ${e is Error ? (e).stackTrace : 'No stack trace'}');
          print('=======================');
          rethrow;
        }
      } else {
        // On mobile, use the existing API client method
        final response = await _apiClient.postFile(
          '${ApiConfig.baseUrl.replaceFirst('/api', '')}/api/documents/upload',
          filePath: file.path!,
          fieldName: 'document',
          additionalFields: {
            'courseId': widget.courseId,
            'sectionId': widget.sectionId,
            'title': _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : file.name,
            'description': _descriptionController.text.trim(),
            'duration': _duration.toString(),
          },
        );
        responseData = jsonDecode(response.body);
      }

      print('=== RESPONSE HANDLING ===');
      print('Response data: $responseData');
      print('Success: ${responseData['success']}');
      print('Data keys: ${responseData['data']?.keys?.toList()}');
      print('Lesson data: ${responseData['data']?['lesson']}');
      print('========================');
      
      if (responseData['success'] == true) {
        final lessonData = responseData['data']['lesson'];
        
        if (lessonData != null) {
          // The lesson was created automatically with the document
          setState(() {
            _documentPath = lessonData['notes']; // Store the document path from the created lesson
            _isUploadingDocument = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Document uploaded and lesson created successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          // Just store the document path if lesson wasn't created automatically
          final documentPath = responseData['data']['s3Key'];
          setState(() {
            _documentPath = documentPath;
            _isUploadingDocument = false;
          });
        }
      } else {
        throw Exception('Failed to upload document');
      }
    } catch (e) {
      setState(() {
        _isUploadingDocument = false;
        _errorMessage = e.toString();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Document upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Lesson'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _createLesson,
            tooltip: 'Save Lesson',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 768;
          
          return Padding(
            padding: EdgeInsets.all(isSmallScreen ? 15 : 20),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderSection(isSmallScreen),
                    const SizedBox(height: 20),
                    _buildFormFields(isSmallScreen),
                    const SizedBox(height: 20),
                    _buildVideoSelectionSection(isSmallScreen),
                    const SizedBox(height: 20),
                    _buildErrorMessage(),
                    const SizedBox(height: 20),
                    _buildSubmitButton(isSmallScreen),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create New Lesson',
          style: TextStyle(
            fontSize: isSmallScreen ? 20 : 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.blackColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Add a new lesson to this section. You can attach a video and add notes.',
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            color: AppTheme.greyColor,
          ),
        ),
      ],
    );
  }

  Widget _buildFormFields(bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppTheme.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Field
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Lesson Title *',
              hintText: 'Enter lesson title',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.title),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a title';
              }
              return null;
            },
          ),
          const SizedBox(height: 15),

          // Description Field
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Enter lesson description',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description),
            ),
          ),
          const SizedBox(height: 15),

          // Duration Field
          TextFormField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Duration (minutes)',
              hintText: 'Enter duration in minutes',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.schedule),
            ),
            onChanged: (value) {
              setState(() {
                _duration = int.tryParse(value ?? '0') ?? 0;
              });
            },
          ),
          const SizedBox(height: 15),

          // Document Upload Field
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.greyColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _documentPath != null 
                    ? AppTheme.primaryGreen.withOpacity(0.3) 
                    : AppTheme.borderGrey,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _documentPath != null ? Icons.check_circle : Icons.upload_file,
                      color: _documentPath != null ? AppTheme.primaryGreen : AppTheme.greyColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _documentPath != null 
                            ? 'Document uploaded successfully' 
                            : 'Upload Study Material (PDF, DOC, PPT)',
                        style: TextStyle(
                          color: _documentPath != null ? AppTheme.primaryGreen : AppTheme.greyColor,
                          fontWeight: _documentPath != null ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_documentPath != null)
                  Text(
                    'Document: ${_documentPath!.split('/').last}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.greyColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isUploadingDocument ? null : _handleDocumentUpload,
                        icon: _isUploadingDocument
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Icon(_documentPath != null ? Icons.refresh : Icons.upload),
                        label: Text(_isUploadingDocument 
                            ? 'Uploading...' 
                            : (_documentPath != null ? 'Change Document' : 'Upload Document')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _documentPath != null 
                              ? AppTheme.primaryGreen 
                              : AppTheme.accent,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    if (_documentPath != null)
                      const SizedBox(width: 10),
                    if (_documentPath != null)
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _documentPath = null;
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
          ),
        ],
      ),
    );
  }

  Widget _buildVideoSelectionSection(bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppTheme.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppTheme.accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.video_library,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Attach Video',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.blackColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Select an existing video or upload a new one:',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.greyColor,
                  ),
                ),
              ),
              if (_isUploadingVideo)
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Uploading...', style: TextStyle(fontSize: 12)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 15),
          if (_isLoading && _videos.isEmpty)
            const Center(child: CircularProgressIndicator())
          else
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedVideoId,
                        decoration: const InputDecoration(
                          labelText: 'Select Existing Video',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.videocam),
                        ),
                        items: _videos.map((video) {
                          return DropdownMenuItem(
                            value: video.id,
                            child: Text(video.title),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedVideoId = value;
                          });
                        },
                        hint: const Text('Choose from existing videos'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _isUploadingVideo ? null : _handleVideoUpload,
                      icon: const Icon(Icons.upload, size: 18),
                      label: const Text('Upload Video'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Tip: You can upload a new video or select from existing ones for this course',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.greyColor,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 10),
          if (_selectedVideoId != null)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppTheme.primaryGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Selected: ${_videos.firstWhere((v) => v.id == _selectedVideoId).title}',
                      style: TextStyle(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w500,
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

  Widget _buildSubmitButton(bool isSmallScreen) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_isLoading || _isUploadingVideo) ? null : _createLesson,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: (_isLoading || _isUploadingVideo)
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Text(_isUploadingVideo ? 'Uploading Video...' : 'Creating Lesson...'),
                ],
              )
            : const Text(
                'Create Lesson',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    if (_errorMessage == null) return const SizedBox.shrink();
    
    return Container(
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
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _apiClient.dispose();
    super.dispose();
  }
}
