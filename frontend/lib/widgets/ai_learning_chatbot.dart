import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellence_coaching_hub/config/app_theme.dart';
import 'package:excellence_coaching_hub/models/lesson.dart';
import 'package:excellence_coaching_hub/models/course.dart';

/// AI Learning Chatbot that provides intelligent tutoring support
/// Knows what the student is learning and offers contextual assistance
class AILearningChatbot extends ConsumerStatefulWidget {
  final Course? currentCourse;
  final Lesson? currentLesson;
  final String? sectionTitle;
  final VoidCallback? onToggle;
  final bool isVisible;

  const AILearningChatbot({
    super.key,
    this.currentCourse,
    this.currentLesson,
    this.sectionTitle,
    this.onToggle,
    this.isVisible = true,
  });

  @override
  ConsumerState<AILearningChatbot> createState() => _AILearningChatbotState();
}

class _AILearningChatbotState extends ConsumerState<AILearningChatbot>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isSending = false;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // Start with welcome message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addWelcomeMessage();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _messageController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    String welcomeText = 'Hello! 👋 I\'m your AI learning assistant. ';
    
    if (widget.currentCourse != null) {
      welcomeText += 'I can help you with "${widget.currentCourse!.title}"';
      if (widget.currentLesson != null) {
        welcomeText += ', specifically the lesson "${widget.currentLesson!.title}".';
      } else {
        welcomeText += '.';
      }
    } else {
      welcomeText += 'I\'m here to help you with your studies!';
    }
    
    welcomeText += ' What would you like to learn about?';
    
    setState(() {
      _messages.add(ChatMessage(
        text: welcomeText,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    final messageText = _messageController.text.trim();
    
    // Add user message
    setState(() {
      _messages.add(ChatMessage(
        text: messageText,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isSending = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      // Simulate AI processing
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Generate AI response based on context
      final response = await _generateAIResponse(messageText);
      
      setState(() {
        _messages.add(ChatMessage(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isSending = false;
      });
      
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Sorry, I encountered an error. Please try again.',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isSending = false;
      });
      _scrollToBottom();
    }
  }

  Future<String> _generateAIResponse(String userMessage) async {
    // This would connect to a real AI service in production
    // For now, we'll provide contextual responses based on the learning context
    
    final normalizedMessage = userMessage.toLowerCase();
    
    // Context-aware responses
    if (widget.currentLesson != null) {
      if (normalizedMessage.contains('explain') || 
          normalizedMessage.contains('what is') ||
          normalizedMessage.contains('help me understand')) {
        return 'Based on "${widget.currentLesson!.title}", I can help explain the key concepts. '
            'Could you be more specific about what you\'d like me to explain?';
      }
      
      if (normalizedMessage.contains('question') || 
          normalizedMessage.contains('quiz') ||
          normalizedMessage.contains('test')) {
        return 'I can help you practice with questions related to "${widget.currentLesson!.title}". '
            'What type of questions would you like to work on?';
      }
    }
    
    if (widget.currentCourse != null) {
      if (normalizedMessage.contains('course') || 
          normalizedMessage.contains('curriculum') ||
          normalizedMessage.contains('syllabus')) {
        return 'This course "${widget.currentCourse!.title}" covers comprehensive topics in '
            '${widget.currentCourse!.category ?? 'the subject area'}. '
            'I can help you understand any specific concepts or provide additional resources.';
      }
    }
    
    // General educational responses
    if (normalizedMessage.contains('math') || 
        normalizedMessage.contains('mathematics') ||
        normalizedMessage.contains('calculate')) {
      return 'I\'d be happy to help with math concepts! I can explain formulas, work through problems, '
          'or help you understand mathematical principles. What specific area of math are you working on?';
    }
    
    if (normalizedMessage.contains('science') || 
        normalizedMessage.contains('biology') ||
        normalizedMessage.contains('chemistry') ||
        normalizedMessage.contains('physics')) {
      return 'I can help with science topics! Whether it\'s biology, chemistry, physics, or general science '
          'concepts, I\'m here to assist with explanations and examples.';
    }
    
    if (normalizedMessage.contains('history') || 
        normalizedMessage.contains('social studies')) {
      return 'I can help with historical concepts, timelines, and social studies topics. '
          'What specific historical period or concept would you like to explore?';
    }
    
    // Default helpful response
    return 'I\'m here to help you learn! I can explain concepts, answer questions, '
        'provide examples, or help you practice problems. What would you like to focus on today? '
        'You can ask me about specific topics, request explanations, or ask for practice questions.';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    if (widget.onToggle != null) {
      widget.onToggle!();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Chat header
              _buildChatHeader(),
              
              // Chat messages
              if (_isExpanded) _buildChatMessages(),
              
              // Input area
              if (_isExpanded) _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatHeader() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.vertical(
          top: const Radius.circular(16),
          bottom: _isExpanded ? Radius.zero : const Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggleExpanded,
          borderRadius: BorderRadius.vertical(
            top: const Radius.circular(16),
            bottom: _isExpanded ? Radius.zero : const Radius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.currentCourse != null)
                        Text(
                          widget.currentCourse!.title,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Icon(
                  _isExpanded ? Icons.expand_more : Icons.expand_less,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatMessages() {
    return Expanded(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 300),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            left: BorderSide(color: AppTheme.borderGrey),
            right: BorderSide(color: AppTheme.borderGrey),
          ),
        ),
        child: ListView.builder(
          controller: _chatScrollController,
          padding: const EdgeInsets.all(16),
          itemCount: _messages.length,
          itemBuilder: (context, index) {
            return _buildMessageBubble(_messages[index]);
          },
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: AppTheme.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser 
                    ? AppTheme.primary 
                    : AppTheme.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser ? Colors.white : AppTheme.getTextColor(context),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),
          
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.person,
                color: AppTheme.primary,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border(
          left: BorderSide(color: AppTheme.borderGrey),
          right: BorderSide(color: AppTheme.borderGrey),
          bottom: BorderSide(color: AppTheme.borderGrey),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Ask me anything about your learning...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppTheme.surface,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
                textInputAction: TextInputAction.send,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: _isSending ? AppTheme.grey : AppTheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                onPressed: _isSending ? null : _sendMessage,
                icon: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}