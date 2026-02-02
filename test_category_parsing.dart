void main() {
  // Test data matching the actual API response
  final testData = {
    "_id": "6980c9eaf99bce4cc177627e",
    "name": "Academic Coaching",
    "description": "Primary, Secondary, University, Nursery, Exams, Research",
    "icon": "📚",
    "subcategories": ["Primary", "Secondary", "University", "Nursery", "Exams", "Research"],
    "isPopular": true,
    "isFeatured": true,
    "level": 1
  };

  print('Testing category parsing...');
  print('Test data: $testData');
  
  // Simulate the fromJson parsing
  final id = (testData['_id'] ?? testData['id']) as String;
  final name = testData['name'] as String;
  final description = testData['description'] as String;
  final icon = testData['icon'] as String;
  final subcategories = List<String>.from(testData['subcategories'] as List);
  final isPopular = testData['isPopular'] as bool? ?? false;
  final isFeatured = testData['isFeatured'] as bool? ?? false;
  final level = testData['level'] as int? ?? 1;
  
  print('Parsed values:');
  print('- ID: $id');
  print('- Name: $name');
  print('- Description: $description');
  print('- Icon: $icon');
  print('- Subcategories: $subcategories');
  print('- Is Popular: $isPopular');
  print('- Is Featured: $isFeatured');
  print('- Level: $level');
  
  print('✓ Category parsing test completed successfully');
}