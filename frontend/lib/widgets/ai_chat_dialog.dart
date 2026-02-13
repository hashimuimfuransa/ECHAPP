import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellence_coaching_hub/config/app_theme.dart';
import 'package:excellence_coaching_hub/models/lesson.dart';
import 'package:excellence_coaching_hub/models/course.dart';
import 'package:excellence_coaching_hub/services/ai_chat_service.dart';
import 'package:excellence_coaching_hub/widgets/ai_chat_messages_list.dart';
import 'package:excellence_coaching_hub/widgets/ai_chat_input_widget.dart';

/// AI Chat Dialog Widget
class AIChatDialog extends StatefulWidget {
  final Course? currentCourse;
  final Lesson? currentLesson;
  final AIChatService chatService;
  final String conversationId;
  final VoidCallback onClose;

  const AIChatDialog({
    super.key,
    this.currentCourse,
    this.currentLesson,
    required this.chatService,
    required this.conversationId,
    required this.onClose,
  });

  @override
  State<AIChatDialog> createState() => _AIChatDialogState();
}

class _AIChatDialogState extends State<AIChatDialog> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  List<AIChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _animationController.forward();
    _loadInitialMessages();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialMessages() async {
    try {
      final messages = await widget.chatService.getConversation(widget.conversationId);
      setState(() {
        _messages = messages;
        _isInitialized = true;
      });
      
      // Add welcome message if no messages exist
      if (messages.isEmpty) {
        await _sendWelcomeMessage();
      }
    } catch (e) {
      print('Error loading initial messages: $e');
      _showErrorMessage('Failed to load chat history');
    }
  }

  Future<void> _sendWelcomeMessage() async {
    final context = AIChatContext(
      currentCourse: widget.currentCourse,
      currentLesson: widget.currentLesson,
    );

    final welcomeMessage = 'Hello! I\'m your AI Learning Assistant. ';
    String message = welcomeMessage;
    
    if (widget.currentCourse != null) {
      message += 'I see you\'re studying "${widget.currentCourse!.title}". ';
      
      if (widget.currentLesson != null) {
        message += 'Currently working on "${widget.currentLesson!.title}". ';
      }
    } else if (widget.currentLesson != null) {
      message += 'I see you\'re studying "${widget.currentLesson!.title}". ';
    }
    
    message += 'Ask me anything about your learning materials, and I\'ll help you understand concepts better!';

    final aiMessage = AIChatMessage(
      id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
      sender: 'ai',
      message: message,
      timestamp: DateTime.now(),
      isContextAware: true,
    );

    setState(() {
      _messages.add(aiMessage);
    });
  }

  Future<void> _handleSendMessage(String message) async {
    if (message.trim().isEmpty) return;

    // Add user message
    final userMessage = AIChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      sender: 'user',
      message: message.trim(),
      timestamp: DateTime.now(),
      isContextAware: false,
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    try {
      // Create context for AI
      final context = AIChatContext(
        currentCourse: widget.currentCourse,
        currentLesson: widget.currentLesson,
      );

      // Send message to AI service
      final aiResponse = await widget.chatService.sendMessage(
        widget.conversationId,
        message.trim(),
        context,
      );

      setState(() {
        _messages.add(aiResponse);
        _isLoading = false;
      });
    } catch (e) {
      print('Error sending message: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorMessage('Failed to send message');
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Chat header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI Learning Assistant',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.currentCourse != null)
                          Text(
                            widget.currentCourse!.title,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            // Chat messages area
            AIChatMessagesList(
              messages: _messages,
              currentUserId: 'user',
            ),
            
            // Input area
            AIChatInputWidget(
              onSendMessage: _handleSendMessage,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}