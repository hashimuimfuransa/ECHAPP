import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellence_coaching_hub/config/app_theme.dart';
import 'package:excellence_coaching_hub/data/models/coaching_category.dart';
import 'package:excellence_coaching_hub/data/repositories/category_repository.dart';
import 'package:excellence_coaching_hub/data/repositories/course_repository.dart';

class AdminCreateCourseScreen extends ConsumerStatefulWidget {
  const AdminCreateCourseScreen({super.key});

  @override
  ConsumerState<AdminCreateCourseScreen> createState() => _AdminCreateCourseScreenState();
}

class _AdminCreateCourseScreenState extends ConsumerState<AdminCreateCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  
  bool _isFree = false;
  bool _isLoading = false;
  String? _selectedCategoryId;
  String _selectedLevel = 'beginner';
  
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
          SnackBar(content: Text('Error loading categories: $e')),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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
        title: const Text('Create New Course'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: _buildContent(),
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
            // Title Field
            _buildTextFormField(
              controller: _titleController,
              label: 'Course Title',
              icon: Icons.title,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a course title';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 20),
            
            // Description Field
            _buildTextFormField(
              controller: _descriptionController,
              label: 'Description',
              icon: Icons.description,
              maxLines: 4,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a course description';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 20),
            
            // Category Selection
            _buildCategorySelector(),
            
            const SizedBox(height: 20),
            
            // Course Level
            _buildLevelSelector(),
            
            const SizedBox(height: 20),
            
            // Price and Duration Row
            _buildPriceDurationRow(),
            
            const SizedBox(height: 30),
            
            // Create Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createCourse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Create Course',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int? maxLines,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primaryGreen),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.blackColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: controller,
              maxLines: maxLines ?? 1,
              decoration: InputDecoration(
                hintText: 'Enter $label',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              validator: validator,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.category, color: AppTheme.primaryGreen),
                const SizedBox(width: 10),
                const Text(
                  'Category',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.blackColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_categoriesLoading)
              const Center(child: CircularProgressIndicator())
            else if (_categories.isEmpty)
              const Text('No categories available')
            else
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                hint: const Text('Select a category'),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category.id,
                    child: Text(category.name),
                  );
                }).toList(),
                onChanged: (value) {
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
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.speed, color: AppTheme.primaryGreen),
                const SizedBox(width: 10),
                const Text(
                  'Course Level',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.blackColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
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

  Widget _buildPriceDurationRow() {
    return Row(
      children: [
        // Free/Paid Toggle
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.attach_money, color: AppTheme.primaryGreen),
                      SizedBox(width: 10),
                      Text(
                        'Course Type',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.blackColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
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
                    activeColor: AppTheme.primaryGreen,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 15),
        // Price Field
        Expanded(
          child: _buildTextFormField(
            controller: _priceController,
            label: 'Price (RWF)',
            icon: Icons.currency_franc,
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
      ],
    );
  }
}