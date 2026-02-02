import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellence_coaching_hub/config/app_theme.dart';

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
  
  String _selectedLevel = 'beginner';
  bool _isPublished = false;
  String? _selectedCategory;
  String? _thumbnailUrl;

  final List<String> _levels = ['beginner', 'intermediate', 'advanced'];
  final List<Map<String, dynamic>> _categories = [
    {'id': '1', 'name': 'Mathematics'},
    {'id': '2', 'name': 'Physics'},
    {'id': '3', 'name': 'Chemistry'},
    {'id': '4', 'name': 'Biology'},
    {'id': '5', 'name': 'English'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Course'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _handleSubmit,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _buildFormContent(),
    );
  }

  Widget _buildFormContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Thumbnail Section
            _buildThumbnailSection(),
            
            const SizedBox(height: 30),
            
            // Basic Information Section
            _buildBasicInfoSection(),
            
            const SizedBox(height: 30),
            
            // Pricing and Duration
            _buildPricingSection(),
            
            const SizedBox(height: 30),
            
            // Additional Settings
            _buildSettingsSection(),
            
            const SizedBox(height: 30),
            
            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Course Thumbnail',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.blackColor,
          ),
        ),
        const SizedBox(height: 15),
        GestureDetector(
          onTap: _selectThumbnail,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: _thumbnailUrl == null 
                  ? AppTheme.primaryGreen 
                  : AppTheme.borderGrey,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: _thumbnailUrl == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.image,
                      size: 50,
                      color: AppTheme.primaryGreen,
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Upload Thumbnail',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Recommended size: 800x450px',
                      style: TextStyle(
                        color: AppTheme.greyColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Image.network(
                    _thumbnailUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Basic Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.blackColor,
          ),
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _titleController,
          label: 'Course Title',
          hint: 'Enter course title',
          icon: Icons.title,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a course title';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _descriptionController,
          label: 'Course Description',
          hint: 'Describe what students will learn',
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
        _buildDropdown(
          label: 'Category',
          hint: 'Select course category',
          value: _selectedCategory,
          items: _categories
            .map((cat) => DropdownMenuItem<String>(
                  value: cat['id'] as String,
                  child: Text(cat['name'] as String),
                ))
            .toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value as String?;
            });
          },
          icon: Icons.category,
        ),
        const SizedBox(height: 20),
        _buildDropdown(
          label: 'Difficulty Level',
          hint: 'Select course level',
          value: _selectedLevel,
          items: _levels
            .map((level) => DropdownMenuItem(
                  value: level,
                  child: Text(level.capitalize()),
                ))
            .toList(),
          onChanged: (value) {
            setState(() {
              _selectedLevel = value as String;
            });
          },
          icon: Icons.speed,
        ),
      ],
    );
  }

  Widget _buildPricingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pricing & Duration',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.blackColor,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _priceController,
                label: 'Price (UGX)',
                hint: '0',
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  if (int.tryParse(value) == null || int.parse(value) < 0) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildTextField(
                controller: _durationController,
                label: 'Duration (minutes)',
                hint: '0',
                icon: Icons.access_time,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter duration';
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Please enter a valid duration';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.blackColor,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
              ),
            ],
          ),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text(
                  'Publish Course',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.blackColor,
                  ),
                ),
                subtitle: const Text(
                  'Make course visible to students',
                  style: TextStyle(
                    color: AppTheme.greyColor,
                    fontSize: 12,
                  ),
                ),
                value: _isPublished,
                onChanged: (value) {
                  setState(() {
                    _isPublished = value;
                  });
                },
                activeColor: AppTheme.primaryGreen,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => context.pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              side: const BorderSide(color: AppTheme.primaryGreen),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: ElevatedButton(
            onPressed: _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Create Course',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: AppTheme.blackColor,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppTheme.primaryGreen),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String hint,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: AppTheme.blackColor,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppTheme.primaryGreen),
          ),
        ),
      ],
    );
  }

  void _selectThumbnail() {
    // In a real app, this would open image picker
    // For now, we'll use a placeholder URL
    setState(() {
      _thumbnailUrl = 'https://via.placeholder.com/800x450/10B981/FFFFFF?text=Course+Thumbnail';
    });
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      // Handle course creation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Course created successfully!'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
      
      // Navigate back or to course content management
      context.pop();
    }
  }
}

// Extension to capitalize first letter
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}