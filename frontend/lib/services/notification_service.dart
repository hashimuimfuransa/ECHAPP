import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../models/notification.dart';
import '../services/infrastructure/token_manager.dart';

class NotificationService {
  final String _baseUrl = ApiConfig.baseUrl;

  Future<List<Notification>> getNotifications() async {
    try {
      final token = await TokenManager().getIdToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }
      
      final response = await http.get(
        Uri.parse('$_baseUrl/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final notificationsData = data['data']['notifications'] as List;
          return notificationsData.map((json) => Notification.fromJson(json)).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to load notifications');
        }
      } else {
        throw Exception('Failed to load notifications: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching notifications: $e');
      rethrow;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final token = await TokenManager().getIdToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }
      
      final response = await http.put(
        Uri.parse('$_baseUrl/notifications/$notificationId/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Failed to mark notification as read');
        }
      } else {
        throw Exception('Failed to mark notification as read: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final token = await TokenManager().getIdToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }
      
      final response = await http.put(
        Uri.parse('$_baseUrl/notifications/read-all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Failed to mark all notifications as read');
        }
      } else {
        throw Exception('Failed to mark all notifications as read: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error marking all notifications as read: $e');
      rethrow;
    }
  }


}
