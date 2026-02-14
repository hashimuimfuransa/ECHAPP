import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:excellencecoachinghub/models/wishlist.dart';
import 'package:excellencecoachinghub/models/course.dart';

class WishlistService {
  static const String _baseUrl = 'http://localhost:3000/api';
  
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Wishlist?> getWishlist() async {
    try {
      final token = await _getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$_baseUrl/wishlist'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Wishlist.fromMap(data['wishlist']);
      } else if (response.statusCode == 404) {
        // Wishlist doesn't exist, create a new one
        return await createWishlist();
      }
      return null;
    } catch (e) {
      print('Error fetching wishlist: $e');
      return null;
    }
  }

  Future<Wishlist?> createWishlist() async {
    try {
      final token = await _getToken();
      if (token == null) return null;

      final response = await http.post(
        Uri.parse('$_baseUrl/wishlist'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'courseIds': [],
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Wishlist.fromMap(data['wishlist']);
      }
      return null;
    } catch (e) {
      print('Error creating wishlist: $e');
      return null;
    }
  }

  Future<bool> addCourseToWishlist(String courseId) async {
    try {
      final token = await _getToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$_baseUrl/wishlist/add'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'courseId': courseId,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error adding course to wishlist: $e');
      return false;
    }
  }

  Future<bool> removeCourseFromWishlist(String courseId) async {
    try {
      final token = await _getToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$_baseUrl/wishlist/remove'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'courseId': courseId,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error removing course from wishlist: $e');
      return false;
    }
  }

  Future<bool> isCourseInWishlist(String courseId) async {
    try {
      final wishlist = await getWishlist();
      if (wishlist == null) return false;
      
      return wishlist.courseIds.contains(courseId);
    } catch (e) {
      print('Error checking if course is in wishlist: $e');
      return false;
    }
  }

  Future<List<Course>> getWishlistCourses() async {
    try {
      final wishlist = await getWishlist();
      if (wishlist == null) return [];
      
      return wishlist.courses;
    } catch (e) {
      print('Error fetching wishlist courses: $e');
      return [];
    }
  }
}
