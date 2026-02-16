import 'package:flutter/material.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/services/ai_chat_service.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Modern Widget to display individual chat messages with avatars and animations
class AIChatMessageWidget extends StatefulWidget {
  final AIChatMessage message;
  final bool isCurrentUser;

  const AIChatMessageWidget({
    super.key,
    required this.message,
    required this.isCurrentUser,
  });

  @override
  State<AIChatMessageWidget> createState() => _AIChatMessageWidgetState();
}

class _AIChatMessageWidgetState extends State<AIChatMessageWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late FlutterTts _flutterTts;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: widget.isCurrentUser ? const Offset(0.5, 0) : const Offset(-0.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _flutterTts = FlutterTts();
    _flutterTts.setLanguage("en-US");
    _flutterTts.setSpeechRate(0.5);
    _flutterTts.setVolume(1.0);
    _flutterTts.setPitch(1.0);

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _speak() async {
    if (widget.message.sender == 'ai' && !_isSpeaking) {
      setState(() {
        _isSpeaking = true;
      });
      
      await _flutterTts.speak(widget.message.message);
      
      setState(() {
        _isSpeaking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
          child: Row(
            mainAxisAlignment:
                widget.isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              // Avatar for AI messages
              if (!widget.isCurrentUser)
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primary,
                          AppTheme.primaryDark,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),

              // Message bubble
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.isCurrentUser
                        ? AppTheme.primary
                        : (isDarkMode ? AppTheme.darkCard : AppTheme.card),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: widget.isCurrentUser
                          ? const Radius.circular(20)
                          : const Radius.circular(4),
                      bottomRight: widget.isCurrentUser
                          ? const Radius.circular(4)
                          : const Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.isCurrentUser
                            ? AppTheme.primary.withOpacity(0.3)
                            : (isDarkMode 
                                ? Colors.black.withOpacity(0.3)
                                : Colors.grey.withOpacity(0.15)),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    border: Border.all(
                      color: widget.isCurrentUser
                          ? Colors.transparent
                          : (isDarkMode
                              ? AppTheme.darkTextSecondary.withOpacity(0.3)
                              : Colors.grey[300]!),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Message content
                      Text(
                        widget.message.message,
                        style: TextStyle(
                          color: widget.isCurrentUser
                              ? Colors.white
                              : (isDarkMode ? AppTheme.darkTextPrimary : AppTheme.blackColor),
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Timestamp and context indicator
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(widget.message.timestamp),
                            style: TextStyle(
                              color: widget.isCurrentUser
                                  ? Colors.white70
                                  : (isDarkMode ? AppTheme.darkTextSecondary : Colors.grey[600]),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (widget.message.isContextAware) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: widget.isCurrentUser
                                    ? Colors.white24
                                    : (isDarkMode 
                                        ? AppTheme.primary.withOpacity(0.2)
                                        : AppTheme.primary.withOpacity(0.1)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.auto_awesome,
                                size: 12,
                                color: widget.isCurrentUser
                                    ? Colors.white70
                                    : AppTheme.primary,
                              ),
                            ),
                          ],
                          // Speaker icon for AI messages
                          if (!widget.isCurrentUser) ...[
                            const SizedBox(width: 6),
                            IconButton(
                              iconSize: 16,
                              onPressed: _speak,
                              icon: Icon(
                                _isSpeaking ? Icons.volume_up : Icons.volume_up_outlined,
                                color: widget.isCurrentUser
                                    ? Colors.white70
                                    : AppTheme.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Avatar for user messages
              if (widget.isCurrentUser)
                Container(
                  margin: const EdgeInsets.only(left: 12),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.blue,
                          Colors.purple,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
