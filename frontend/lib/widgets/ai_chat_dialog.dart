import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:excellence_coaching_hub/config/app_theme.dart';
import 'package:excellence_coaching_hub/models/lesson.dart';
import 'package:excellence_coaching_hub/models/course.dart';
import 'package:excellence_coaching_hub/services/ai_chat_service.dart';
import 'package:excellence_coaching_hub/widgets/ai_chat_messages_list.dart';
import 'package:excellence_coaching_hub/widgets/ai_chat_input_widget.dart';
import 'package:excellence_coaching_hub/widgets/voice_chat_widget.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Modern AI Chat Dialog Widget with Glass Morphism Effect
class ModernAIChatDialog extends StatefulWidget {
  final Course? currentCourse;
  final Lesson? currentLesson;
  final AIChatService chatService;
  final String conversationId;
  final VoidCallback onClose;

  const ModernAIChatDialog({
    super.key,
    this.currentCourse,
    this.currentLesson,
    required this.chatService,
    required this.conversationId,
    required this.onClose,
  });

  @override
  State<ModernAIChatDialog> createState() => _ModernAIChatDialogState();
}

class _ModernAIChatDialogState extends State<ModernAIChatDialog> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late AnimationController _headerAnimationController;
  late Animation<double> _headerSlideAnimation;
  List<AIChatMessage> _messages = [];
  bool _isLoading = false;
  bool _showVoiceChat = false;
  bool _isTyping = false;
  late FlutterTts _flutterTts;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400), // Slightly shorter duration for better visibility
      vsync: this,
    );
    
    _headerSlideAnimation = Tween<double>(
      begin: -30.0, // Reduce starting offset to ensure header is visible
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOut, // Use simpler curve for more predictable movement
    ));

    _flutterTts = FlutterTts();
    _flutterTts.setLanguage("en-US");
    _flutterTts.setSpeechRate(0.5);
    _flutterTts.setVolume(1.0);
    _flutterTts.setPitch(1.0);
    
    _animationController.forward().then((_) {
      // Add a small delay before starting header animation for better visual effect
      Future.delayed(const Duration(milliseconds: 100), () {
        _headerAnimationController.forward();
      });
    });
    _loadInitialMessages();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _headerAnimationController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  void _speakMessage(String message) {
    // Speak the AI response from voice chat
    _flutterTts.speak(message);
  }

  Future<void> _loadInitialMessages() async {
    try {
      final messages = await widget.chatService.getConversation(widget.conversationId);
      setState(() {
        _messages = messages;
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

    // Speak the welcome message
    await _flutterTts.speak(aiMessage.message);
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
      _isTyping = true;
    });

    try {
      // Create context for AI
      final context = AIChatContext(
        currentCourse: widget.currentCourse,
        currentLesson: widget.currentLesson,
      );

      // Simulate typing delay for better UX
      await Future.delayed(const Duration(milliseconds: 500));

      // Send message to AI service
      final aiResponse = await widget.chatService.sendMessage(
        widget.conversationId,
        message.trim(),
        context,
      );

      setState(() {
        _messages.add(aiResponse);
        _isLoading = false;
        _isTyping = false;
      });

      // Speak the AI response
      await _flutterTts.speak(aiResponse.message);
    } catch (e) {
      print('Error sending message: $e');
      setState(() {
        _isLoading = false;
        _isTyping = false;
      });
      _showErrorMessage('Failed to send message');
    }
  }

  void _toggleVoiceChat() {
    setState(() {
      _showVoiceChat = !_showVoiceChat;
    });
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
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.7, // Further increase height for better header visibility
        margin: const EdgeInsets.fromLTRB(16, 24, 16, 16), // More top margin to ensure header is visible
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.95),
              Colors.white.withOpacity(0.85),
            ],
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // Modern Chat Header with Slide Animation
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -0.1), // Reduce offset so header starts slightly above but remains visible
                      end: Offset.zero,
                    ).animate(_headerSlideAnimation),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.primary,
                            AppTheme.primaryDark,
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'AI Learning Assistant',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (widget.currentCourse != null)
                                  Text(
                                    widget.currentCourse!.title,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _toggleVoiceChat,
                            icon: Icon(
                              _showVoiceChat ? Icons.chat : Icons.mic,
                              color: Colors.white,
                              size: 20,
                            ),
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          ),
                          IconButton(
                            onPressed: widget.onClose,
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Chat messages area or voice chat widget
                  if (_showVoiceChat)
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: VoiceChatWidget(
                            conversationId: widget.conversationId,
                            context: {
                              'courseTitle': widget.currentCourse?.title ?? '',
                              'lessonTitle': widget.currentLesson?.title ?? '',
                            },
                            onVoiceMessageReceived: (text) {
                              // Add the transcribed text to messages
                              final userMessage = AIChatMessage(
                                id: 'voice_user_${DateTime.now().millisecondsSinceEpoch}',
                                sender: 'user',
                                message: text,
                                timestamp: DateTime.now(),
                                isContextAware: false,
                              );
                              
                              setState(() {
                                _messages.add(userMessage);
                              });
                            },
                            onTextMessageReceived: (text) {
                              // Add the text response to messages
                              final aiMessage = AIChatMessage(
                                id: 'voice_ai_${DateTime.now().millisecondsSinceEpoch}',
                                sender: 'ai',
                                message: text,
                                timestamp: DateTime.now(),
                                isContextAware: true,
                              );
                              
                              setState(() {
                                _messages.add(aiMessage);
                              });

                              // Speak the AI response from voice chat
                              _speakMessage(aiMessage.message); // Call a helper method to handle the async operation
                            },
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: Stack(
                        children: [
                          AIChatMessagesList(
                            messages: _messages,
                            currentUserId: 'user',
                          ),
                          // Typing indicator overlay
                          if (_isTyping)
                            Positioned(
                              bottom: 16,
                              right: 16,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.auto_awesome,
                                      color: AppTheme.primary,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Thinking...',
                                      style: TextStyle(
                                        color: AppTheme.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  
                  // Modern Input area
                  if (!_showVoiceChat)
                    AIChatInputWidget(
                      onSendMessage: _handleSendMessage,
                      isLoading: _isLoading,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}