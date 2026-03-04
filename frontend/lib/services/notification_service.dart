import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import '../config/api_config.dart';
import '../models/notification.dart';
import '../services/infrastructure/token_manager.dart';

class NotificationService {
  final String _baseUrl = ApiConfig.baseUrl;

  void _handleError(dynamic e, String defaultMessage) {
    if (e is SocketException) {
      throw Exception('Connection failed. Please check your internet connection and try again.');
    } else if (e is http.ClientException) {
      throw Exception('Network error occurred. Please check your network connection.');
    } else if (e is TimeoutException) {
      throw Exception('The request timed out. Please check your connection or try again later.');
    } else {
      throw Exception('$defaultMessage: ${e.toString()}');
    }
  }

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
      _handleError(e, 'Error fetching notifications');
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
      _handleError(e, 'Error marking notification as read');
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
      _handleError(e, 'Error marking all notifications as read');
      rethrow;
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      final token = await TokenManager().getIdToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }
      
      final response = await http.delete(
        Uri.parse('$_baseUrl/notifications/$notificationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Failed to delete notification');
        }
      } else {
        throw Exception('Failed to delete notification: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _handleError(e, 'Error deleting notification');
      rethrow;
    }
  }

  Future<void> deleteAllNotifications() async {
    try {
      final token = await TokenManager().getIdToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }
      
      final response = await http.delete(
        Uri.parse('$_baseUrl/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Failed to delete all notifications');
        }
      } else {
        throw Exception('Failed to delete all notifications: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _handleError(e, 'Error deleting all notifications');
      rethrow;
    }
  }
}
