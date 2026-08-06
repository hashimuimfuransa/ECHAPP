import 'package:flutter/material.dart';
import 'package:excellencecoachinghub/models/question.dart';
import 'package:excellencecoachinghub/utils/media_proxy.dart';

class EssayQuestionWidget extends StatefulWidget {
  final Question question;
  final Function(String) onAnswerChanged;
  final String? currentAnswer;

  const EssayQuestionWidget({
    super.key,
    required this.question,
    required this.onAnswerChanged,
    this.currentAnswer,
  });

  @override
  State<EssayQuestionWidget> createState() => _EssayQuestionWidgetState();
}

class _EssayQuestionWidgetState extends State<EssayQuestionWidget> {
  late TextEditingController _textController;
  int _characterCount = 0;
  int _wordCount = 0;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.currentAnswer ?? '');
    _textController.addListener(_updateCounts);
    _updateCounts();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _updateCounts() {
    final text = _textController.text;
    setState(() {
      _characterCount = text.length;
      _wordCount = text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;
    });
    widget.onAnswerChanged(text);
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

        // Essay text area
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Text area header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Answer',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '$_wordCount words',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '$_characterCount characters',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Text input area
              TextField(
                controller: _textController,
                maxLines: 8,
                minLines: 6,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
                decoration: const InputDecoration(
                  hintText: 'Write your detailed answer here...\n\nProvide a comprehensive response that demonstrates your understanding of the topic.',
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
                onChanged: (value) => _updateCounts(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Writing tips
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Writing Tips',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...[
                '• Provide a clear introduction that addresses the question',
                '• Support your points with specific examples or evidence',
                '• Organize your thoughts into logical paragraphs',
                '• Conclude with a summary of your main points',
                '• Review your answer for clarity and completeness'
              ].map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  tip,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[600],
                    height: 1.4,
                  ),
                ),
              )),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Points and grading info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber[700], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This essay will be manually graded',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber[700],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Maximum points: ${widget.question.points} • Grading will be completed by your instructor',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.amber[600],
                      ),
                    ),
                  ],
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
