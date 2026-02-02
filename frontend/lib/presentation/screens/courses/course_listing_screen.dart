import 'package:flutter/material.dart';
import 'package:excellence_coaching_hub/presentation/widgets/beautiful_widgets.dart';
import 'package:excellence_coaching_hub/config/app_theme.dart';

class CourseListingScreen extends StatefulWidget {
  const CourseListingScreen({super.key});

  @override
  _CourseListingScreenState createState() => _CourseListingScreenState();
}

class _CourseListingScreenState extends State<CourseListingScreen> {
  final List<Map<String, dynamic>> courses = [
    {
      'id': '1',
      'title': 'Complete Flutter Development Bootcamp',
      'instructor': 'Dr. Sarah Johnson',
      'description': 'Learn Flutter from scratch and build real-world applications',
      'price': 59.99,
      'duration': 40,
      'level': 'Beginner',
      'rating': 4.8,
      'students': 1250,
      'thumbnail': 'flutter_course.jpg',
      'isEnrolled': false,
      'isFree': false,
    },
    {
      'id': '2',
      'title': 'Advanced UI/UX Design Masterclass',
      'instructor': 'Michael Chen',
      'description': 'Master professional design principles and Figma',
      'price': 0.0,
      'duration': 25,
      'level': 'Intermediate',
      'rating': 4.9,
      'students': 890,
      'thumbnail': 'design_course.jpg',
      'isEnrolled': true,
      'isFree': true,
    },
    {
      'id': '3',
      'title': 'Digital Marketing Strategy 2026',
      'instructor': 'Emma Rodriguez',
      'description': 'Comprehensive digital marketing course for modern businesses',
      'price': 79.99,
      'duration': 35,
      'level': 'Advanced',
      'rating': 4.7,
      'students': 2100,
      'thumbnail': 'marketing_course.jpg',
      'isEnrolled': false,
      'isFree': false,
    },
    {
      'id': '4',
      'title': 'Python for Data Science',
      'instructor': 'Prof. David Wilson',
      'description': 'Learn Python programming for data analysis and machine learning',
      'price': 49.99,
      'duration': 45,
      'level': 'Intermediate',
      'rating': 4.6,
      'students': 1800,
      'thumbnail': 'python_course.jpg',
      'isEnrolled': true,
      'isFree': false,
    },
  ];

  String selectedLevel = 'All';
  double maxPrice = 100.0;
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        colors: AppTheme.secondaryGradient,
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Filters
              _buildFilters(),
              
              // Course List
              Expanded(
                child: _buildCourseList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'All Courses',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: () {
              // Show filter sheet
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final levels = ['All', 'Beginner', 'Intermediate', 'Advanced'];
    
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: levels.length,
        itemBuilder: (context, index) {
          final level = levels[index];
          final isSelected = selectedLevel == level;
          
          return Container(
            margin: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(
                level,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              selectedColor: Colors.white.withOpacity(0.3),
              backgroundColor: Colors.white.withOpacity(0.1),
              onSelected: (selected) {
                setState(() {
                  selectedLevel = level;
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildCourseList() {
    final filteredCourses = courses.where((course) {
      bool matchesLevel = selectedLevel == 'All' || course['level'] == selectedLevel;
      bool matchesPrice = course['price'] <= maxPrice;
      bool matchesSearch = searchQuery.isEmpty || 
          course['title'].toLowerCase().contains(searchQuery.toLowerCase()) ||
          course['instructor'].toLowerCase().contains(searchQuery.toLowerCase());
      
      return matchesLevel && matchesPrice && matchesSearch;
    }).toList();

    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 0.8,
          ),
          itemCount: filteredCourses.length,
          itemBuilder: (context, index) {
            return _buildCourseCard(filteredCourses[index]);
          },
        ),
      ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    return GlassContainer(
      child: InkWell(
        onTap: () {
          // Navigate to course detail
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: AssetImage('assets/images/${course['thumbnail']}'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    if (course['isEnrolled'])
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    if (course['isFree'])
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'FREE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              
              // Title
              Text(
                course['title'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              
              // Instructor
              Text(
                course['instructor'],
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              
              // Rating and Students
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${course['rating']}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${course['students']})',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Price and Duration
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    course['price'] == 0 ? 'Free' : '\$${course['price']}',
                    style: TextStyle(
                      color: course['price'] == 0 ? Colors.green : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${course['duration']}h',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}