import 'package:flutter/material.dart';
import 'package:excellence_coaching_hub/widgets/ai_chat_message_widget.dart';
import 'package:excellence_coaching_hub/services/ai_chat_service.dart';

/// Widget to display the list of chat messages
class AIChatMessagesList extends StatefulWidget {
  final List<AIChatMessage> messages;
  final String currentUserId;

  const AIChatMessagesList({
    super.key,
    required this.messages,
    required this.currentUserId,
  });

  @override
  State<AIChatMessagesList> createState() => _AIChatMessagesListState();
}

class _AIChatMessagesListState extends State<AIChatMessagesList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void didUpdateWidget(AIChatMessagesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length != oldWidget.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        controller: _scrollController,
        itemCount: widget.messages.length,
        itemBuilder: (context, index) {
          final message = widget.messages[index];
          final isCurrentUser = message.sender == widget.currentUserId;
          
          return AIChatMessageWidget(
            message: message,
            isCurrentUser: isCurrentUser,
          );
        },
      ),
    );
  }
}