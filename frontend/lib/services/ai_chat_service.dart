import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellence_coaching_hub/config/app_theme.dart';
import 'package:excellence_coaching_hub/models/lesson.dart';
import 'package:excellence_coaching_hub/models/course.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

/// AI Chat Message model
class AIChatMessage {
  final String id;
  final String sender; // 'user' or 'ai'
  final String message;
  final DateTime timestamp;
  final bool isContextAware; // Whether this message uses learning context

  AIChatMessage({
    required this.id,
    required this.sender,
    required this.message,
    required this.timestamp,
    this.isContextAware = false,
  });

  AIChatMessage copyWith({
    String? id,
    String? sender,
    String? message,
    DateTime? timestamp,
    bool? isContextAware,
  }) {
    return AIChatMessage(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isContextAware: isContextAware ?? this.isContextAware,
    );
  }
}

/// AI Chat Context containing current learning information
class AIChatContext {
  final Course? currentCourse;
  final Lesson? currentLesson;
  final String? studentName;
  final String? studentLevel;

  AIChatContext({
    this.currentCourse,
    this.currentLesson,
    this.studentName,
    this.studentLevel,
  });

  AIChatContext copyWith({
    Course? currentCourse,
    Lesson? currentLesson,
    String? studentName,
    String? studentLevel,
  }) {
    return AIChatContext(
      currentCourse: currentCourse ?? this.currentCourse,
      currentLesson: currentLesson ?? this.currentLesson,
      studentName: studentName ?? this.studentName,
      studentLevel: studentLevel ?? this.studentLevel,
    );
  }
}

/// AI Chat Service Interface for backend integration
abstract class AIChatService {
  Future<List<AIChatMessage>> getConversation(String conversationId);
  Future<AIChatMessage> sendMessage(String conversationId, String message, AIChatContext context);
  Future<void> createConversation(AIChatContext context);
  Future<void> updateContext(String conversationId, AIChatContext context);
}

/// Real AI Chat Service that connects to backend Grok AI
class RealAIChatService implements AIChatService {
  static const String _baseUrl = 'http://localhost:3000/api/ai'; // Adjust to your backend URL
  final http.Client _httpClient = http.Client();

  @override
  Future<List<AIChatMessage>> getConversation(String conversationId) async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/conversations/$conversationId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => _fromMap(json)).toList();
      } else {
        throw Exception('Failed to load conversation: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting conversation: $e');
      return []; // Return empty list on error
    }
  }

  @override
  Future<AIChatMessage> sendMessage(String conversationId, String message, AIChatContext context) async {
    try {
      final requestBody = {
        'conversationId': conversationId,
        'message': message,
        'context': {
          'courseTitle': context.currentCourse?.title ?? '',
          'lessonTitle': context.currentLesson?.title ?? '',
          'studentName': context.studentName ?? '',
          'studentLevel': context.studentLevel ?? '',
        },
      };

      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/chat/send'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = json.decode(response.body);
        return AIChatMessage(
          id: json['id'] ?? 'ai_${DateTime.now().millisecondsSinceEpoch}',
          sender: 'ai',
          message: json['message'] ?? 'Sorry, I couldn\'t process that request.',
          timestamp: DateTime.now(),
          isContextAware: true,
        );
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending message: $e');
      // Return a fallback message in case of error
      return AIChatMessage(
        id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        sender: 'ai',
        message: 'I\'m having trouble connecting to my AI brain. Could you try asking again?',
        timestamp: DateTime.now(),
        isContextAware: false,
      );
    }
  }

  @override
  Future<void> createConversation(AIChatContext context) async {
    try {
      final requestBody = {
        'context': {
          'courseTitle': context.currentCourse?.title ?? '',
          'lessonTitle': context.currentLesson?.title ?? '',
          'studentName': context.studentName ?? '',
          'studentLevel': context.studentLevel ?? '',
        },
      };

      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/conversations/create'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to create conversation: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating conversation: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateContext(String conversationId, AIChatContext context) async {
    try {
      final requestBody = {
        'conversationId': conversationId,
        'context': {
          'courseTitle': context.currentCourse?.title ?? '',
          'lessonTitle': context.currentLesson?.title ?? '',
          'studentName': context.studentName ?? '',
          'studentLevel': context.studentLevel ?? '',
        },
      };

      final response = await _httpClient.put(
        Uri.parse('$_baseUrl/conversations/update-context'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update context: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating context: $e');
      rethrow;
    }
  }

  AIChatMessage _fromMap(Map<String, dynamic> json) {
    return AIChatMessage(
      id: json['id'] ?? 'msg_${DateTime.now().millisecondsSinceEpoch}',
      sender: json['sender'] ?? 'ai',
      message: json['message'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch),
      isContextAware: json['isContextAware'] ?? false,
    );
  }
}