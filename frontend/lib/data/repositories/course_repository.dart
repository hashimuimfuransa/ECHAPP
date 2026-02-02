import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../config/api_config.dart';
import '../models/course.dart';
import '../../config/storage_manager.dart';

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

  Future<Course> createCourse({
    required String title,
    required String description,
    required double price,
    required int duration,
    required String level,
    String? thumbnail,
    String? categoryId,
  }) async {
    try {
      // Get fresh Firebase ID token instead of stored backend JWT token
      final firebase_auth.User? currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      final idToken = await currentUser.getIdToken(true); // Force refresh
      
      if (idToken == null) {
        throw Exception('Failed to get authentication token');
      }

      final response = await http.post(
        Uri.parse(ApiConfig.courses),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'title': title,
          'description': description,
          'price': price,
          'duration': duration,
          'level': level,
          'thumbnail': thumbnail,
          'categoryId': categoryId,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['data'] is Map<String, dynamic>) {
          return Course.fromJson(data['data'] as Map<String, dynamic>);
        } else {
          final mapData = json.decode(data['data'].toString()) as Map<String, dynamic>;
          return Course.fromJson(mapData);
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to create course');
      }
    } catch (e) {
      // Provide more specific error messages
      if (e.toString().contains('401') || e.toString().contains('unauthorized') || e.toString().contains('invalid token')) {
        throw Exception('Authentication failed. Please log out and log back in.');
      } else if (e.toString().contains('403') || e.toString().contains('forbidden')) {
        throw Exception('You do not have permission to create courses.');
      } else {
        throw Exception('Error creating course: $e');
      }
    }
  }
}