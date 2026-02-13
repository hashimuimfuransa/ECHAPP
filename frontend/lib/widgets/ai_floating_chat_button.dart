import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellence_coaching_hub/config/app_theme.dart';
import 'package:excellence_coaching_hub/models/lesson.dart';
import 'package:excellence_coaching_hub/models/course.dart';
import 'package:excellence_coaching_hub/services/ai_chat_service.dart';
import 'package:excellence_coaching_hub/widgets/ai_chat_dialog.dart';

/// Floating AI Chat Button that expands to full chat when clicked
class AIFloatingChatButton extends ConsumerStatefulWidget {
  final Course? currentCourse;
  final Lesson? currentLesson;
  final VoidCallback? onChatOpen;

  const AIFloatingChatButton({
    super.key,
    this.currentCourse,
    this.currentLesson,
    this.onChatOpen,
  });

  @override
  ConsumerState<AIFloatingChatButton> createState() => _AIFloatingChatButtonState();
}

class _AIFloatingChatButtonState extends ConsumerState<AIFloatingChatButton>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isExpanded = false;

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
    
    // Pulse animation for attention
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleChat() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    
    if (_isExpanded) {
      _animationController.forward();
      _pulseController.stop(); // Stop pulse when expanded
    } else {
      _animationController.reverse();
      _pulseController.repeat(reverse: true); // Resume pulse when closed
    }
    
    if (widget.onChatOpen != null) {
      widget.onChatOpen!();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the real AI service
    final aiChatService = RealAIChatService();
    final conversationId = 'conversation_${DateTime.now().millisecondsSinceEpoch}';

    return Stack(
      children: [
        // Attractive label above the button
        Positioned(
          right: 10,
          bottom: 90,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 16,
                ),
                SizedBox(width: 6),
                Text(
                  'Learning Support',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Floating chat button - Make it more visible with pulse animation
        Positioned(
          right: 20,
          bottom: 20,
          child: ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: _toggleChat,
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 12,
                mini: false, // Make it full size
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _isExpanded
                      ? const Icon(Icons.close, key: ValueKey('close'), size: 28)
                      : const Icon(Icons.auto_awesome, key: ValueKey('chat'), size: 28),
                ),
              ),
            ),
          ),
        ),
        
        // Chat overlay (appears when expanded)
        if (_isExpanded)
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleChat, // Close when tapping outside
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: GestureDetector(
                    onTap: () {}, // Prevent closing when tapping on dialog
                    child: AIChatDialog(
                      currentCourse: widget.currentCourse,
                      currentLesson: widget.currentLesson,
                      chatService: aiChatService,
                      conversationId: conversationId,
                      onClose: _toggleChat,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}