import 'package:flutter/material.dart';
import 'package:excellencecoachinghub/models/question.dart';
import 'package:excellencecoachinghub/utils/media_proxy.dart';

class MultipleChoiceQuestionWidget extends StatefulWidget {
  final Question question;
  final Function(String?) onAnswerChanged;
  final String? currentAnswer;

  const MultipleChoiceQuestionWidget({
    super.key,
    required this.question,
    required this.onAnswerChanged,
    this.currentAnswer,
  });

  @override
  State<MultipleChoiceQuestionWidget> createState() => _MultipleChoiceQuestionWidgetState();
}

class _MultipleChoiceQuestionWidgetState extends State<MultipleChoiceQuestionWidget> {
  String? selectedOptionId;

  @override
  void initState() {
    super.initState();
    selectedOptionId = widget.currentAnswer;
  }

  void _selectOption(String optionId) {
    setState(() {
      selectedOptionId = optionId;
      widget.onAnswerChanged(optionId);
    });
  }

  Widget _buildOption(String optionId, String text, String? image) {
    final isSelected = selectedOptionId == optionId;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectOption(optionId),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected 
                ? Colors.blue[50] 
                : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected 
                  ? Colors.blue 
                  : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                // Radio button
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey[400]!,
                      width: 2,
                    ),
                    color: isSelected ? Colors.blue : Colors.transparent,
                  ),
                  child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
                ),
                
                const SizedBox(width: 12),
                
                // Option content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text option
                      Text(
                        text,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? Colors.blue[800] : Colors.black87,
                        ),
                      ),
                      
                      // Image option (if present)
                      if (image != null && image.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
child: Image.network(
                            mediaProxyUrl(image),
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 120,
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(Icons.image_not_supported, color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question text with media support
        if (widget.question.questionImage != null && widget.question.questionImage!.isNotEmpty)
          Container(
            width: double.infinity,
            height: 200,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
child: Image.network(
                mediaProxyUrl(widget.question.questionImage),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ),

        // Audio support (if present)
        if (widget.question.questionAudio != null && widget.question.questionAudio!.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.audiotrack, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Audio question available',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    // TODO: Implement audio playback
                  },
                  icon: Icon(Icons.play_arrow, color: Colors.blue[600]),
                ),
              ],
            ),
          ),

        Text(
          widget.question.question,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),

        const SizedBox(height: 24),

        // Options
        if (widget.question.options != null)
          ...widget.question.options!.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final optionId = option.id?.toString() ?? index.toString();
            
            return _buildOption(
              optionId,
              option.text ?? '',
              option.image,
            );
          }),

        const SizedBox(height: 16),

        // Instructions
        if (widget.question.randomizeOptions == true)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Select one correct answer from the options below.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Points indicator
        Container(
          margin: const EdgeInsets.only(top: 16),
          child: Row(
            children: [
              Icon(Icons.star, color: Colors.amber[600], size: 16),
              const SizedBox(width: 4),
              Text(
                '${widget.question.points} point${widget.question.points != 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (widget.question.difficulty != null) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(widget.question.difficulty!),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    widget.question.difficulty!.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
