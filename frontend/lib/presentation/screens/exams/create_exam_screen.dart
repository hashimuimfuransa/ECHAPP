import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/services/api/exam_service.dart';
import 'package:excellencecoachinghub/services/api/upload_service.dart';

class CreateExamScreen extends StatefulWidget {
  final String courseId;
  final String sectionId;

  const CreateExamScreen({
    super.key, 
    required this.courseId, 
    required this.sectionId
  });

  @override
  State<CreateExamScreen> createState() => _CreateExamScreenState();
}

class _CreateExamScreenState extends State<CreateExamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _passingScoreController = TextEditingController(text: '50');
  final _timeLimitController = TextEditingController(text: '0');
  
  String _selectedType = 'quiz';
  bool _isPublished = false;
  bool _isLoading = false;
  
  // For document upload
  String? _uploadedDocumentPath;
  String? _documentFileName;
  bool _isProcessing = false;
  String _processingStatus = '';

  Future<void> _pickAndUploadDocument() async {
    try {
      // Pick a document file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
      );

      if (result != null) {
        PlatformFile file = result.files.first;
        
        setState(() {
          _isProcessing = true;
          _processingStatus = 'Uploading document...';
        });

        // Use the UploadService to upload the document and create exam from it
        final uploadService = UploadService();
        
        final response = await uploadService.uploadDocumentWithExamCreation(
          file: file,
          courseId: widget.courseId,
          sectionId: widget.sectionId,
          examType: _selectedType,
          title: _titleController.text.isEmpty ? null : _titleController.text,
          passingScore: int.tryParse(_passingScoreController.text) ?? 50,
          timeLimit: int.tryParse(_timeLimitController.text) ?? 0,
        );

        setState(() {
          _uploadedDocumentPath = response['documentUrl'];
          _documentFileName = file.name;
          _processingStatus = 'Document processed successfully!';
          _isProcessing = false;
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Document processed and exam created successfully!'),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process document: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createExam() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final examService = ExamService();
      
      // If a document was uploaded and processed, we don't need to create another exam
      // as the document upload process already created the exam
      if (_uploadedDocumentPath != null && _documentFileName != null) {
        // Just navigate back since exam was already created during document upload
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Exam created successfully from document!'),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
          
          // Pop back to the previous screen
          Navigator.pop(context);
        }
      } else {
        // Create exam manually if no document was processed
        final exam = await examService.createExam(
          courseId: widget.courseId,
          sectionId: widget.sectionId,
          title: _titleController.text,
          type: _selectedType,
          passingScore: int.tryParse(_passingScoreController.text) ?? 50,
          timeLimit: int.tryParse(_timeLimitController.text) ?? 0,
          isPublished: _isPublished,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Exam created successfully!'),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
          
          Navigator.pop(context, exam);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create exam: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _passingScoreController.dispose();
    _timeLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Exam'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Exam Type Selection
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Exam Type',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        children: [
                          ChoiceChip(
                            label: const Text('Quiz'),
                            selected: _selectedType == 'quiz',
                            selectedColor: Colors.blue,
                            onSelected: _isLoading || _isProcessing
                                ? null
                                : (selected) {
                                    if (selected) {
                                      setState(() {
                                        _selectedType = 'quiz';
                                      });
                                    }
                                  },
                          ),
                          ChoiceChip(
                            label: const Text('Past Paper'),
                            selected: _selectedType == 'pastpaper',
                            selectedColor: Colors.orange,
                            onSelected: _isLoading || _isProcessing
                                ? null
                                : (selected) {
                                    if (selected) {
                                      setState(() {
                                        _selectedType = 'pastpaper';
                                      });
                                    }
                                  },
                          ),
                          ChoiceChip(
                            label: const Text('Final Exam'),
                            selected: _selectedType == 'final',
                            selectedColor: Colors.red,
                            onSelected: _isLoading || _isProcessing
                                ? null
                                : (selected) {
                                    if (selected) {
                                      setState(() {
                                        _selectedType = 'final';
                                      });
                                    }
                                  },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),

              // Basic Info
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Basic Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Exam Title',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter exam title';
                          }
                          return null;
                        },
                        enabled: !_isLoading && !_isProcessing,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _passingScoreController,
                              decoration: const InputDecoration(
                                labelText: 'Passing Score (%)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter passing score';
                                }
                                final score = int.tryParse(value);
                                if (score == null || score < 0 || score > 100) {
                                  return 'Enter a value between 0-100';
                                }
                                return null;
                              },
                              enabled: !_isLoading && !_isProcessing,
                            ),
                          ),
                          
                          const SizedBox(width: 16),
                          
                          Expanded(
                            child: TextFormField(
                              controller: _timeLimitController,
                              decoration: const InputDecoration(
                                labelText: 'Time Limit (minutes)',
                                hintText: '0 for unlimited',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              enabled: !_isLoading && !_isProcessing,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      SwitchListTile(
                        title: const Text('Publish Exam'),
                        value: _isPublished,
                        onChanged: _isLoading || _isProcessing
                            ? null
                            : (value) {
                                setState(() {
                                  _isPublished = value;
                                });
                              },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Document Upload Section
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Document Upload & AI Processing',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      Text(
                        'Upload a document containing questions that will be processed by AI to create the exam.',
                        style: const TextStyle(
                          color: AppTheme.greyColor,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      if (_uploadedDocumentPath != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            border: Border.all(color: Colors.green.shade200),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Processed: $_documentFileName',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                onPressed: _isLoading || _isProcessing
                                    ? null
                                    : () {
                                        setState(() {
                                          _uploadedDocumentPath = null;
                                          _documentFileName = null;
                                        });
                                      },
                              ),
                            ],
                          ),
                        )
                      else
                        OutlinedButton.icon(
                          onPressed: _isLoading || _isProcessing
                              ? null
                              : _pickAndUploadDocument,
                          icon: const Icon(Icons.upload),
                          label: const Text('Upload Document for AI Processing'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          ),
                        ),
                      
                      const SizedBox(height: 16),
                      
                      if (_isProcessing)
                        LinearProgressIndicator(
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                        ),
                      
                      if (_isProcessing || _processingStatus.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _processingStatus,
                            style: TextStyle(
                              color: _isProcessing ? Colors.orange : Colors.green,
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Create Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading || _isProcessing ? null : _createExam,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(strokeWidth: 2)
                      : const Text(
                          'Create Exam',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}