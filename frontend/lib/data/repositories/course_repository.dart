import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../models/course.dart';

class CourseRepository {
  Future<List<Course>> getCourses({String? categoryId}) async {
    try {
      String url = ApiConfig.courses;
      
      // Add category filter if provided
      if (categoryId != null) {
        url += '?category=$categoryId';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final coursesJson = data['data']['courses'] as List;
        
        return coursesJson.map((json) => Course.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to load courses: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching courses: $e');
    }
  }

  Future<Course> getCourseById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.courses}/$id'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] is Map<String, dynamic>) {
          return Course.fromJson(data['data'] as Map<String, dynamic>);
        } else {
          // If it's already a string, parse it again
          final mapData = json.decode(data['data'].toString()) as Map<String, dynamic>;
          return Course.fromJson(mapData);
        }
      } else {
        throw Exception('Failed to load course: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching course: $e');
    }
  }
}