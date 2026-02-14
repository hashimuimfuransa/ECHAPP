import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/models/lesson.dart';
import 'package:excellencecoachinghub/models/course.dart';
import 'package:excellencecoachinghub/services/ai_chat_service.dart';
import 'package:excellencecoachinghub/widgets/ai_chat_dialog.dart';

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
        // Modern theme-aware label with animation
        Positioned(
          right: 12,
          bottom: 85,
          child: AnimatedOpacity(
            opacity: _isExpanded ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppTheme.primary.withOpacity(0.95),
                    AppTheme.accent.withOpacity(0.95),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'AI Assistant',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Theme-aware floating chat button with enhanced micro-interactions
        Positioned(
          right: 12,
          bottom: 12,
          child: ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primary,
                    AppTheme.primaryDark,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: AppTheme.accent.withOpacity(0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: _toggleChat,
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                hoverElevation: 0,
                focusElevation: 0,
                highlightElevation: 0,
                mini: true,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: RotationTransition(
                        turns: Tween<double>(
                          begin: 0.0,
                          end: 0.25,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: _isExpanded
                      ? const Icon(Icons.close, key: ValueKey('close'), size: 22)
                      : const Icon(Icons.auto_awesome, key: ValueKey('chat'), size: 22),
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
                    child: ModernAIChatDialog(
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
