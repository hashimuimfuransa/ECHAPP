import 'package:excellencecoachinghub/models/lesson.dart';
import 'package:excellencecoachinghub/models/course.dart';
import 'package:excellencecoachinghub/config/api_config.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http_parser/http_parser.dart';

/// AI Chat Message model
class AIChatMessage {
  final String id;
  final String sender; // 'user' or 'ai'
  final String message;
  final DateTime timestamp;
  final bool isContextAware; // Whether this message uses learning context
  final String? audioUrl; // URL for audio response

  AIChatMessage({
    required this.id,
    required this.sender,
    required this.message,
    required this.timestamp,
    this.isContextAware = false,
    this.audioUrl,
  });

  AIChatMessage copyWith({
    String? id,
    String? sender,
    String? message,
    DateTime? timestamp,
    bool? isContextAware,
    String? audioUrl,
  }) {
    return AIChatMessage(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isContextAware: isContextAware ?? this.isContextAware,
      audioUrl: audioUrl ?? this.audioUrl,
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
  Future<AIChatMessage> sendVoiceMessage(String conversationId, File audioFile, AIChatContext context);
  Future<void> createConversation(AIChatContext context);
  Future<void> updateContext(String conversationId, AIChatContext context);
}

/// Real AI Chat Service that connects to backend Grok AI
class RealAIChatService implements AIChatService {
  static String get _baseUrl => ApiConfig.aiBaseUrl; // Use centralized API config
  static String get _voiceBaseUrl => ApiConfig.voiceBaseUrl; // Use centralized voice API config
  final http.Client _httpClient = http.Client();

  @override
  Future<List<AIChatMessage>> getConversation(String conversationId) async {
    try {
      // If conversationId is a temporary string ID, we need to create a real conversation first
      if (conversationId.startsWith('conversation_')) {
        // Create a new conversation
        await createConversation(AIChatContext());
        // The conversation ID should be updated after creation
        // For now, return empty list as the conversation will be created with proper ID
        return [];
      }
      
      final token = await _getAuthToken();
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/conversations/$conversationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        return responseData.map((item) => _fromMap(item)).toList();
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
      // If conversationId is a temporary string ID, create a real conversation first
      String actualConversationId = conversationId;
      if (conversationId.startsWith('conversation_')) {
        actualConversationId = await createConversation(context);
      }
      
      final requestBody = {
        'conversationId': actualConversationId,
        'message': message,
        'context': {
          'courseTitle': context.currentCourse?.title ?? '',
          'lessonTitle': context.currentLesson?.title ?? '',
          'studentName': context.studentName ?? '',
          'studentLevel': context.studentLevel ?? '',
        },
      };

      final token = await _getAuthToken();
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/chat/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return AIChatMessage(
          id: responseData['messages'][1]['id'] ?? 'ai_${DateTime.now().millisecondsSinceEpoch}',
          sender: 'ai',
          message: responseData['messages'][1]['message'] ?? 'Sorry, I couldn\'t process that request.',
          timestamp: DateTime.now(),
          isContextAware: true,
          audioUrl: responseData['audioUrl'],
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
  Future<AIChatMessage> sendVoiceMessage(String conversationId, File audioFile, AIChatContext context) async {
    try {
      final token = await _getAuthToken();
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_voiceBaseUrl/send'), // Use centralized voice API config
      );
      request.headers['Authorization'] = 'Bearer $token';
      
      request.fields['conversationId'] = conversationId;
      request.fields['context'] = jsonEncode({
        'courseTitle': context.currentCourse?.title ?? '',
        'lessonTitle': context.currentLesson?.title ?? '',
        'studentName': context.studentName ?? '',
        'studentLevel': context.studentLevel ?? '',
      });
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'audio',
          audioFile.path,
          contentType: MediaType('audio', 'mp4'), // Assuming M4A or MP4 audio
        ),
      );
      
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        var jsonData = jsonDecode(responseBody);
        return AIChatMessage(
          id: 'voice_ai_${DateTime.now().millisecondsSinceEpoch}',
          sender: 'ai',
          message: jsonData['textResponse'] ?? 'I processed your voice message.',
          timestamp: DateTime.now(),
          isContextAware: true,
          audioUrl: jsonData['audioResponse'],
        );
      } else {
        throw Exception('Failed to send voice message: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending voice message: $e');
      // Return a fallback message in case of error
      return AIChatMessage(
        id: 'error_voice_${DateTime.now().millisecondsSinceEpoch}',
        sender: 'ai',
        message: 'I\'m having trouble processing your voice message. Could you try again?',
        timestamp: DateTime.now(),
        isContextAware: false,
      );
    }
  }

  @override
  Future<String> createConversation(AIChatContext context) async {
    try {
      final requestBody = {
        'context': {
          'courseTitle': context.currentCourse?.title ?? '',
          'lessonTitle': context.currentLesson?.title ?? '',
          'studentName': context.studentName ?? '',
          'studentLevel': context.studentLevel ?? '',
        },
      };

      final token = await _getAuthToken();
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/conversations/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData['conversation']['id'].toString();
      } else {
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
      // If conversationId is a temporary string ID, we can't update context
      if (conversationId.startsWith('conversation_')) {
        print('Cannot update context for temporary conversation ID');
        return;
      }
      
      final requestBody = {
        'conversationId': conversationId,
        'context': {
          'courseTitle': context.currentCourse?.title ?? '',
          'lessonTitle': context.currentLesson?.title ?? '',
          'studentName': context.studentName ?? '',
          'studentLevel': context.studentLevel ?? '',
        },
      };

      final token = await _getAuthToken();
      final response = await _httpClient.put(
        Uri.parse('$_baseUrl/conversations/update-context'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
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
      timestamp: json['timestamp'] is String 
        ? DateTime.parse(json['timestamp']) 
        : DateTime.fromMillisecondsSinceEpoch(json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch),
      isContextAware: json['isContextAware'] ?? false,
      audioUrl: json['audioUrl'],
    );
  }

  // Helper method to get auth token (implement based on your auth system)
  Future<String> _getAuthToken() async {
    try {
      // Get the current user from Firebase
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Get the Firebase ID token
        final token = await user.getIdToken();
        if (token != null) {
          return token;
        } else {
          throw Exception('Failed to get ID token');
        }
      } else {
        throw Exception('No authenticated user found');
      }
    } catch (e) {
      print('Error getting auth token: $e');
      rethrow;
    }
  }
}
