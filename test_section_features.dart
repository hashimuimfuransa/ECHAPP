import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  const baseUrl = 'http://192.168.1.3:5000/api';
  
  print('Testing Section Features...\n');
  
  // Test 1: Get sections for a course (public endpoint)
  print('1. Testing GET sections for course:');
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/sections/course/67a1b2c3d4e5f67890123456'),
    );
    
    print('Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('Success: ${data['message']}');
      print('Sections count: ${data['data']?.length ?? 0}\n');
    } else {
      print('Error: ${response.body}\n');
    }
  } catch (e) {
    print('Network error: $e\n');
  }
  
  // Test 2: Test section creation (would require auth token)
  print('2. Section creation requires admin authentication');
  print('   (Test manually through the admin panel)\n');
  
  // Test 3: Test section deletion (would require auth token)
  print('3. Section deletion requires admin authentication');
  print('   (Test manually through the admin panel)\n');
  
  print('Manual testing recommended:');
  print('- Log in as admin');
  print('- Navigate to course content management');
  print('- Test creating sections');
  print('- Test editing section titles');
  print('- Test deleting sections');
  print('- Test reordering sections');
  print('- Verify lessons are properly handled when sections are deleted\n');
}