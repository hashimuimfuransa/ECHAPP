import 'package:flutter/material.dart';
import 'package:excellencecoachinghub/widgets/ai_chat_message_widget.dart';
import 'package:excellencecoachinghub/services/ai_chat_service.dart';

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
  int _previousMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _previousMessageCount = widget.messages.length;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _jumpToBottom();
    });
  }

  @override
  void didUpdateWidget(AIChatMessagesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length != _previousMessageCount) {
      _previousMessageCount = widget.messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _animateToBottom();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _jumpToBottom() {
    if (_scrollController.hasClients &&
        _scrollController.position.maxScrollExtent > 0) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  void _animateToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: widget.messages.length,
      itemBuilder: (context, index) {
        final message = widget.messages[index];
        final isCurrentUser = message.sender == widget.currentUserId;
        
        return AIChatMessageWidget(
          message: message,
          isCurrentUser: isCurrentUser,
        );
      },
    );
  }
}
