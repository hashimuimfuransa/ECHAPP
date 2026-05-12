// Fixed version of _buildQuizHero method with corrected final exam detection

Widget _buildQuizHero() {
  final quizTitle = _exam?['title'] ?? 'Lesson Quiz';
  final quizType = _exam?['type'] ?? _lesson?.lessonType ?? 'Quiz';
  final quizInstructions = _exam?['instructions'] ?? 'Test your understanding of this lesson';
  final isFinalExam = (quizTitle.toLowerCase().contains('final') ||
                         quizType.toLowerCase().contains('final') || 
                         (_exam?['isFinal'] == true) || 
                         (_lesson?.lessonType?.toLowerCase().contains('final') == true));
  
    
  final hasAttempts = _quizAttempts.isNotEmpty;
  final latestAttempt = hasAttempts ? _quizAttempts.first : null;
  final score = latestAttempt?['totalScore'] ?? 0;
  final maxScore = latestAttempt?['maxScore'] ?? _exam?['totalPoints'] ?? _exam?['maxScore'] ?? 100;
  
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: _T.greenLight,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _T.greenMid),
    ),
    child: Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: _T.green,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _T.green.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.quiz_outlined,
              color: Colors.white, size: 32),
        ),
        const SizedBox(height: 16),
        Text(
          quizTitle,
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _textColor),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _T.green,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            quizType,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          quizInstructions,
          style: TextStyle(fontSize: 13, color: _mutedColor),
          textAlign: TextAlign.center,
        ),
        // Certificate notification for final exams
        if (isFinalExam) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3CD),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFD700)),
            ),
            child: Row(
              children: [
                Icon(Icons.workspace_premium_outlined, 
                    color: const Color(0xFF856404), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Certificate Available! Pass this final exam to earn your completion certificate.',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF856404),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (hasAttempts) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _T.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.scoreboard_outlined, 
                    color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Latest: $score/$maxScore',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _exam != null ? _showQuizInstructions : null,
                icon: const Icon(Icons.info_outline, size: 16),
                label: const Text('Instructions'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _T.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  textStyle: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _exam != null ? _startQuiz : null,
                icon: const Icon(Icons.play_arrow_outlined, size: 18),
                label: Text(hasAttempts ? 'Retake quiz' : 'Start quiz'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _T.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  textStyle: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
