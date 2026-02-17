import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/models/category.dart';
import 'package:excellencecoachinghub/data/repositories/category_repository.dart';
import 'package:excellencecoachinghub/data/repositories/course_repository.dart';
import 'package:excellencecoachinghub/services/image_upload_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'dart:io';


class AdminCreateCourseScreen extends ConsumerStatefulWidget {
  final String? courseId; // Added courseId parameter to differentiate between create and edit
  
  const AdminCreateCourseScreen({super.key, this.courseId});

  @override
  ConsumerState<AdminCreateCourseScreen> createState() => _AdminCreateCourseScreenState();
}

class _AdminCreateCourseScreenState extends ConsumerState<AdminCreateCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _objectivesController = TextEditingController();
  final _accessDurationController = TextEditingController();

  bool _isFree = false;
  bool _isLoading = false;
  bool _isPublished = false; // Add publish status
  String? _selectedCategoryId;
  String _selectedLevel = 'beginner';
  String? _thumbnailUrl;
  File? _selectedImage;
  bool _isUploadingImage = false;
  UniqueKey _thumbnailKey = UniqueKey();

  List<String> _learningObjectives = [];
  List<String> _requirementsList = [];

  List<Category> _categories = [];
  bool _categoriesLoading = true;
  bool _isEditing = false;
  bool _courseLoading = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.courseId != null;
    print('Course ID in initState: ${widget.courseId}'); // Debug log
    _loadCategories();
    
    if (_isEditing) {
      _loadCourseDetails();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _requirementsController.dispose();
    _objectivesController.dispose();
    super.dispose();
  }

  Future<void> _loadCourseDetails() async {
    if (widget.courseId == null) return;
    
    print('Loading course details for ID: ${widget.courseId}'); // Debug log
    
    setState(() {
      _courseLoading = true;
    });

    try {
      final repository = CourseRepository();
      final course = await repository.getCourseById(widget.courseId!);
      
      print('Course loaded successfully: ${course.title}'); // Debug log
      
      // Populate form with course data
      _titleController.text = course.title ?? '';
      _descriptionController.text = course.description;
      _priceController.text = course.price.toString();
      _durationController.text = course.duration.toString();
      _isFree = course.price == 0.0;
      _selectedLevel = course.level.toLowerCase();
      _thumbnailUrl = course.thumbnail;
      _isPublished = course.isPublished; // Set publish status
      _selectedCategoryId = course.category?['id'];
      _thumbnailKey = UniqueKey(); // Refresh key when loading course details
      
      // Load access duration days if available
      if (course.accessDurationDays != null) {
        _accessDurationController.text = course.accessDurationDays.toString();
      } else {
        _accessDurationController.text = '';
      }
      
      if (course.learningObjectives != null) {
        _learningObjectives = List.from(course.learningObjectives!);
      }
      
      if (course.requirements != null) {
        _requirementsList = List.from(course.requirements!);
      }
      
      setState(() {
        _courseLoading = false;
      });
    } catch (e) {
      setState(() {
        _courseLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading course details: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop(); // Go back if there's an error
      }
    }
  }

  Future<void> _loadCategories() async {
    try {
      final repository = CategoryRepository();
      final categories = await repository.getAllCategories();
      setState(() {
        _categories = categories;
        _categoriesLoading = false;
      });
    } catch (e) {
      setState(() {
        _categoriesLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading categories: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addLearningObjective() {
    if (_objectivesController.text.trim().isNotEmpty) {
      setState(() {
        _learningObjectives.add(_objectivesController.text.trim());
        _objectivesController.clear();
      });
    }
  }

  void _removeLearningObjective(int index) {
    setState(() {
      _learningObjectives.removeAt(index);
    });
  }

  void _addRequirement() {
    if (_requirementsController.text.trim().isNotEmpty) {
      setState(() {
        _requirementsList.add(_requirementsController.text.trim());
        _requirementsController.clear();
      });
    }
  }

  void _removeRequirement(int index) {
    setState(() {
      _requirementsList.removeAt(index);
    });
  }

  Future<void> _pickAndUploadImage() async {
    if (!mounted) return;
    
    ImageSource source;
    
    // On web, we should only use gallery since camera access might not work properly
    if (kIsWeb) {
      source = ImageSource.gallery;
    } else {
      ImageSource? dialogResult = await showDialog<ImageSource?>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Select Image Source'),
            content: const Text('Choose where to pick your course thumbnail from:'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(ImageSource.camera),
                child: const Text('Camera'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
                child: const Text('Gallery'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );
      
      if (dialogResult == null) return;
      source = dialogResult;
    }

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final imageUrl = await ImageUploadService.pickAndUploadImage(source: source);
      if (imageUrl != null) {
        setState(() {
          _thumbnailUrl = imageUrl;
          _thumbnailKey = UniqueKey(); // Regenerate key to force image refresh
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thumbnail uploaded successfully!'),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.contains('cancelled')) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  Future<void> _saveCourse() async {
    // Minimal validation to ensure required fields have values
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Course title is required")),
      );
      return;
    }
    
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Course description is required")),
      );
      return;
    }
    
    if (_durationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Course duration is required")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final repository = CourseRepository();

      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();
      final duration = int.tryParse(_durationController.text.trim()) ?? 1; // Default to 1 if parsing fails
      final price = _isFree ? 0.0 : (double.tryParse(_priceController.text.trim()) ?? 0.0);

      if (_isEditing && widget.courseId != null) {
        // Update existing course
        final accessDurationDays = _accessDurationController.text.trim().isEmpty 
            ? null 
            : int.tryParse(_accessDurationController.text.trim());
        
        final course = await repository.updateCourse(
          id: widget.courseId!,
          title: title,
          description: description,
          price: price,
          duration: duration,
          level: _selectedLevel,
          categoryId: _selectedCategoryId,
          thumbnail: _thumbnailUrl,
          learningObjectives: _learningObjectives.isEmpty ? null : _learningObjectives,
          requirements: _requirementsList.isEmpty ? null : _requirementsList,
          accessDurationDays: accessDurationDays,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Course updated successfully!'),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
          Navigator.of(context).pop(course);
        }
      } else {
        // Create new course
        final accessDurationDays = _accessDurationController.text.trim().isEmpty 
            ? null 
            : int.tryParse(_accessDurationController.text.trim());
        
        final course = await repository.createCourse(
          title: title,
          description: description,
          price: price,
          duration: duration,
          level: _selectedLevel,
          categoryId: _selectedCategoryId,
          thumbnail: _thumbnailUrl,
          isPublished: _isPublished, // Add publish status
          learningObjectives: _learningObjectives.isEmpty ? null : _learningObjectives,
          requirements: _requirementsList.isEmpty ? null : _requirementsList,
          accessDurationDays: accessDurationDays,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Course created successfully!'),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
          Navigator.of(context).pop(course);
        }
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Course' : 'Create New Course'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Course Creation/Edit Guide'),
                  content: const Text(
                    'Fill in all required fields. Add learning objectives and requirements '
                    'to help students understand what they will learn and what they need '
                    'before taking this course.'
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('OK'),
                    )
                  ],
                ),
              );
            },
          )
        ],
      ),
      body: SafeArea(
        child: _courseLoading ? _buildLoading() : _buildForm(),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text('Loading course details...'),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildThumbnailSection(),
          const SizedBox(height: 20),
          _buildBasicInfoSection(),
          const SizedBox(height: 20),
          _buildCategorySection(),
          const SizedBox(height: 20),
          _buildLevelSection(),
          const SizedBox(height: 20),
          _buildRequirementsSection(),
          const SizedBox(height: 20),
          _buildObjectivesSection(),
          const SizedBox(height: 20),
          _buildPricingSection(),
          const SizedBox(height: 30),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.school,
            size: 40,
            color: AppTheme.primaryGreen,
          ),
          const SizedBox(height: 8),
          Text(
            _isEditing ? 'Edit Your Course' : 'Create Your Course',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _isEditing 
                ? 'Update the details of your existing course'
                : 'Fill in the details to create a new course',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnailSection() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Course Thumbnail',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_thumbnailUrl != null)
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _thumbnailUrl!,
                  key: _thumbnailKey,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    print('Error loading thumbnail image: $error, stack: $stackTrace'); // Debug log
                    return Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.broken_image,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Failed to load image',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _thumbnailUrl != null 
                              ? (_thumbnailUrl!.length > 50 
                                  ? '${_thumbnailUrl!.substring(0, 50)}...' 
                                  : _thumbnailUrl!)
                              : 'No URL',
                            style: const TextStyle(color: Colors.grey, fontSize: 10),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Try uploading again',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isUploadingImage ? null : _pickAndUploadImage,
                    icon: _isUploadingImage
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload),
                    label: Text(_isUploadingImage ? 'Uploading...' : 'Upload Image'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                if (_thumbnailUrl != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _thumbnailUrl = null;
                      });
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Basic Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Course Title *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a course title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                hintText: 'Describe what this course is about...',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Category',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            if (_categoriesLoading)
              const LinearProgressIndicator()
            else if (_categories.isEmpty)
              const Text('No categories available')
            else
              DropdownButtonFormField<String>(
                initialValue: _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Select Category',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categories.map<DropdownMenuItem<String>>((category) {
                  return DropdownMenuItem(
                    value: category.id,
                    child: Text(category.name ?? 'Unnamed Category'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                  });
                },
                validator: (value) {
                  // Make category selection optional
                  return null;
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelSection() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Difficulty Level',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'beginner', label: Text('Beginner')),
                ButtonSegment(value: 'intermediate', label: Text('Intermediate')),
                ButtonSegment(value: 'advanced', label: Text('Advanced')),
              ],
              selected: {_selectedLevel},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _selectedLevel = newSelection.first;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementsSection() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Requirements',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _requirementsController,
                    decoration: const InputDecoration(
                      labelText: 'Add a requirement',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addRequirement,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_requirementsList.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _requirementsList.asMap().entries.map((entry) {
                  final index = entry.key;
                  final requirement = entry.value;
                  return Chip(
                    label: Text(requirement),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => _removeRequirement(index),
                    backgroundColor: Colors.blue[50],
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildObjectivesSection() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Learning Objectives',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _objectivesController,
                    decoration: const InputDecoration(
                      labelText: 'Add a learning objective',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addLearningObjective,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_learningObjectives.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _learningObjectives.asMap().entries.map((entry) {
                  final index = entry.key;
                  final objective = entry.value;
                  return Chip(
                    label: Text(objective),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => _removeLearningObjective(index),
                    backgroundColor: Colors.green[50],
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingSection() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pricing & Duration',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _durationController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Duration (minutes) *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.schedule),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter duration';
                      }
                      final parsedValue = int.tryParse(value);
                      if (parsedValue == null || parsedValue <= 0) {
                        return 'Please enter a valid duration';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SwitchListTile(
                    title: const Text('Free Course'),
                    value: _isFree,
                    onChanged: (value) {
                      setState(() {
                        _isFree = value;
                        if (value) {
                          _priceController.clear();
                        }
                      });
                    },
                  ),
                ),
                Expanded(
                  child: SwitchListTile(
                    title: const Text('Publish Course'),
                    value: _isPublished,
                    onChanged: (value) {
                      setState(() {
                        _isPublished = value;
                      });
                    },
                    activeThumbColor: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _accessDurationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Access Duration (days) - Leave empty for unlimited access',
                hintText: 'e.g., 30, 60, 90 (Leave empty for unlimited)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.timer),
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final parsedValue = int.tryParse(value);
                  if (parsedValue == null || parsedValue <= 0) {
                    return 'Please enter a valid positive number of days';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            if (!_isFree)
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price (RWF)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (value) {
                  // Only validate if not free and has a value
                  if (!_isFree && value != null && value.isNotEmpty && double.tryParse(value) == null) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveCourse,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                _isEditing ? 'Update Course' : 'Create Course',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
