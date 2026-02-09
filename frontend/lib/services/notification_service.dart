import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../models/notification.dart';

class NotificationService {
  final String _baseUrl = ApiConfig.baseUrl;

  Future<List<Notification>> getNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/notifications'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Notification.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } catch (e) {
      // Return mock notifications in case of error
      return _getMockNotifications();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/notifications/$notificationId/read'),
        headers: await _getHeaders(),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark notification as read: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/notifications/mark-all-read'),
        headers: await _getHeaders(),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark all notifications as read: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error marking all notifications as read: $e');
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    // In a real implementation, this would get the auth token
    // For now, return basic headers
    return {
      'Content-Type': 'application/json',
    };
  }

  List<Notification> _getMockNotifications() {
    final now = DateTime.now();
    return [
      Notification(
        id: '1',
        title: 'New Student Registration',
        message: 'John Doe has registered for your platform',
        type: 'info',
        timestamp: now.subtract(const Duration(minutes: 2)),
      ),
      Notification(
        id: '2',
        title: 'Payment Received',
        message: 'RWF 15,000 received from Jane Smith',
        type: 'success',
        timestamp: now.subtract(const Duration(hours: 1)),
      ),
      Notification(
        id: '3',
        title: 'Course Completed',
        message: 'Sam Wilson completed "Advanced Mathematics"',
        type: 'achievement',
        timestamp: now.subtract(const Duration(hours: 3)),
      ),
      Notification(
        id: '4',
        title: 'New Course Created',
        message: 'You created a new course: "Introduction to Physics"',
        type: 'info',
        timestamp: now.subtract(const Duration(days: 1)),
      ),
    ];
  }
}