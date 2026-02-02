import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellence_coaching_hub/config/app_theme.dart';
import 'package:excellence_coaching_hub/data/models/coaching_category.dart';
import 'package:excellence_coaching_hub/data/repositories/category_repository.dart';
import 'package:excellence_coaching_hub/data/repositories/course_repository.dart';
import 'package:excellence_coaching_hub/services/image_upload_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AdminCreateCourseScreen extends ConsumerStatefulWidget {
  const AdminCreateCourseScreen({super.key});

  @override
  ConsumerState<AdminCreateCourseScreen> createState() =>
      _AdminCreateCourseScreenState();
}

class _AdminCreateCourseScreenState
    extends ConsumerState<AdminCreateCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();

  bool _isFree = false;
  bool _isLoading = false;
  String? _selectedCategoryId;
  String _selectedLevel = 'beginner';
  String? _thumbnailUrl;
  File? _selectedImage;
  bool _isUploadingImage = false;

  List<CoachingCategory> _categories = [];
  bool _categoriesLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    if (!mounted) return;
    
    // Show options dialog
    final source = await showDialog<ImageSource>(
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
    
    if (source == null) return; // User cancelled
    
    setState(() {
      _isUploadingImage = true;
    });

    try {
      final imageUrl = await ImageUploadService.pickAndUploadImage(source: source);
      if (imageUrl != null) {
        setState(() {
          _thumbnailUrl = imageUrl;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thumbnail uploaded successfully!'),
              backgroundColor: AppTheme.primaryGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.contains('camera_access_denied')) {
          errorMessage = 'Camera access denied. Please enable camera permission in your device settings.';
        } else if (errorMessage.contains('photo_access_denied')) {
          errorMessage = 'Photo library access denied. Please enable photo library permission in your device settings.';
        } else if (errorMessage.contains('no_available_camera')) {
          errorMessage = 'No camera available on this device.';
        } else if (errorMessage.contains('implementation')) {
          errorMessage = 'Image picker not supported on this platform. Please try selecting from gallery instead.';
        } else if (errorMessage.contains('cancelled')) {
          errorMessage = 'Image selection was cancelled.';
          // Don't show snackbar for cancellation
          return;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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

  Future<void> _loadCategories() async {
    try {
      print('Loading categories...');
      final repository = CategoryRepository();
      final categories = await repository.getAllCategories();
      print('Loaded ${categories.length} categories');
      setState(() {
        _categories = categories;
        _categoriesLoading = false;
      });
    } catch (e) {
      print('Error loading categories: $e');
      setState(() {
        _categoriesLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading categories: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _createCourse() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final repository = CourseRepository();

      // Handle price for free courses
      final price = _isFree ? 0.0 : (double.tryParse(_priceController.text) ?? 0.0);

      final course = await repository.createCourse(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: price,
        duration: int.tryParse(_durationController.text) ?? 0,
        level: _selectedLevel,
        categoryId: _selectedCategoryId,
        thumbnail: _thumbnailUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Course created successfully!'),
            backgroundColor: AppTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        );
        Navigator.of(context).pop(course);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
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
        title: const Text(
          'Create New Course',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryGreen.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            _buildHeaderCard(),
            
            const SizedBox(height: 25),
            
            // Thumbnail Image Section
            _buildThumbnailSection(),
            
            const SizedBox(height: 20),
            
            // Title Field
            _buildInputCard(
              icon: Icons.title,
              label: 'Course Title',
              child: TextFormField(
                controller: _titleController,
                style: const TextStyle(fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'Enter course title',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a course title';
                  }
                  return null;
                },
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Description Field
            _buildInputCard(
              icon: Icons.description,
              label: 'Description',
              child: TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                style: const TextStyle(fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'Enter course description',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a course description';
                  }
                  return null;
                },
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Category Selection
            _buildCategorySelector(),
            
            // Refresh Categories Button
            if (!_categoriesLoading)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _loadCategories,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh Categories'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryGreen,
                  ),
                ),
              ),
            
            const SizedBox(height: 20),
            
            // Course Level
            _buildLevelSelector(),
            
            const SizedBox(height: 20),
            
            // Price and Duration Row
            _buildPriceDurationRow(),
            
            const SizedBox(height: 30),
            
            // Create Button
            _buildCreateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailSection() {
    return _buildInputCard(
      icon: Icons.image,
      label: 'Course Thumbnail',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_thumbnailUrl != null)
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderGrey.withOpacity(0.5)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  _thumbnailUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppTheme.surface,
                      child: const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 48,
                          color: AppTheme.greyColor,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          if (_thumbnailUrl != null)
            const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isUploadingImage ? null : _pickAndUploadImage,
                  icon: _isUploadingImage
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_upload_outlined),
                  label: Text(
                    _isUploadingImage ? 'Uploading...' : 'Upload Thumbnail',
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.primaryGreen),
                    foregroundColor: AppTheme.primaryGreen,
                  ),
                ),
              ),
              if (_thumbnailUrl != null) ...[
                const SizedBox(width: 10),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _thumbnailUrl = null;
                    });
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Remove thumbnail',
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Upload a course thumbnail image (JPG, PNG, up to 5MB)',
            style: TextStyle(
              color: AppTheme.greyColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.school,
              color: Colors.white,
              size: 40,
            ),
            const SizedBox(height: 15),
            const Text(
              'Create Your Course',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Fill in the details below to create a new course',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Categories are loaded from backend database',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard({
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: AppTheme.primaryGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.blackColor,
                    ),
                  ),
                ),
                if (label == 'Category' && !_categoriesLoading && _categories.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_categories.length} available',
                      style: const TextStyle(
                        color: AppTheme.primaryGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 15),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return _buildInputCard(
      icon: Icons.category,
      label: 'Category',
      child: _categoriesLoading
          ? const Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 10),
                Text('Loading categories...', style: TextStyle(color: AppTheme.greyColor)),
              ],
            )
          : _categories.isEmpty
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'No categories available',
                      style: TextStyle(color: AppTheme.greyColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please contact administrator to add categories',
                      style: TextStyle(
                        color: AppTheme.greyColor.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select from ${_categories.length} available categories:',
                  style: TextStyle(
                    color: AppTheme.greyColor,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                _buildCategoryDropdown(),
              ],
            ),
    );
  }

  Widget _buildLevelSelector() {
    return _buildInputCard(
      icon: Icons.speed,
      label: 'Course Level',
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.borderGrey.withOpacity(0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'beginner',
                label: Text('Beginner'),
                icon: Icon(Icons.emoji_objects, size: 18),
              ),
              ButtonSegment(
                value: 'intermediate',
                label: Text('Intermediate'),
                icon: Icon(Icons.auto_awesome, size: 18),
              ),
              ButtonSegment(
                value: 'advanced',
                label: Text('Advanced'),
                icon: Icon(Icons.workspace_premium, size: 18),
              ),
            ],
            selected: {_selectedLevel},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                _selectedLevel = newSelection.first;
              });
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith<Color>(
                (Set<WidgetState> states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppTheme.primaryGreen;
                  }
                  return Colors.transparent;
                },
              ),
              foregroundColor: WidgetStateProperty.resolveWith<Color>(
                (Set<WidgetState> states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.white;
                  }
                  return AppTheme.blackColor;
                },
              ),
              side: WidgetStateProperty.all(
                BorderSide(color: AppTheme.borderGrey.withOpacity(0.5)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceDurationRow() {
    return Row(
      children: [
        // Free/Paid Toggle Card
        Expanded(
          flex: 1,
          child: _buildInputCard(
            icon: Icons.money_off,
            label: 'Course Type',
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text(
                    'Free Course',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  value: _isFree,
                  onChanged: (value) {
                    setState(() {
                      _isFree = value;
                      if (value) {
                        _priceController.clear();
                      }
                    });
                  },
                  activeColor: AppTheme.primaryGreen,
                  contentPadding: EdgeInsets.zero,
                ),
                if (!_isFree)
                  const Text(
                    'Students can enroll without payment',
                    style: TextStyle(
                      color: AppTheme.greyColor,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 15),
        // Price Field Card
        Expanded(
          flex: 1,
          child: _buildInputCard(
            icon: Icons.currency_franc,
            label: 'Price (RWF)',
            child: TextFormField(
              controller: _priceController,
              enabled: !_isFree,
              style: const TextStyle(fontSize: 16),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: _isFree ? 'Free' : 'Enter price',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                prefixIcon: const Icon(
                  Icons.currency_franc,
                  color: AppTheme.primaryGreen,
                ),
              ),
              validator: (value) {
                if (!_isFree && (value == null || value.isEmpty)) {
                  return 'Please enter a price';
                }
                if (!_isFree && double.tryParse(value!) == null) {
                  return 'Please enter a valid price';
                }
                return null;
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryGreen,
            AppTheme.primaryGreen.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _createCourse,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Create Course',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    print('Building category dropdown with ${_categories.length} categories');
    
    // Simple version first to ensure it works
    return DropdownButtonFormField<String>(
      value: _selectedCategoryId,
      decoration: const InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      hint: const Text(
        'Select a category',
        style: TextStyle(color: AppTheme.greyColor),
      ),
      items: _categories.map((category) {
        print('Adding category: ${category.name} (${category.id})');
        return DropdownMenuItem<String>(
          value: category.id,
          child: Text('${category.icon} ${category.name}'),
        );
      }).toList(),
      onChanged: (value) {
        print('Selected category: $value');
        setState(() {
          _selectedCategoryId = value;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a category';
        }
        return null;
      },
    );
  }
}