import 'package:flutter/material.dart';
import 'package:excellence_coaching_hub/config/app_theme.dart';
import 'package:excellence_coaching_hub/services/api/exam_service.dart';

/// Screen to display detailed question results for a specific exam
class ExamQuestionDetailsScreen extends StatelessWidget {
  final ExamResult examResult;

  const ExamQuestionDetailsScreen({super.key, required this.examResult});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Question Details'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with exam info
            _buildExamHeader(),
            const SizedBox(height: 24),
            
            // Statistics summary
            _buildStatisticsCard(),
            const SizedBox(height: 24),
            
            // Question list
            const Text(
              'Question Review',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            ...examResult.questions.asMap().entries.map((entry) {
              final index = entry.key;
              final question = entry.value;
              return _buildQuestionCard(index + 1, question);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildExamHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            examResult.examDetails?.title ?? 'Unknown Exam',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: examResult.passed 
                  ? AppTheme.successColor.withOpacity(0.1)
                  : AppTheme.errorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              examResult.passed ? 'PASSED' : 'FAILED',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: examResult.passed 
                    ? AppTheme.successColor 
                    : AppTheme.errorColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatRow(
            'Total Questions', 
            '${examResult.statistics.totalQuestions}', 
            Icons.question_mark
          ),
          _buildStatRow(
            'Correct Answers', 
            '${examResult.statistics.correctAnswers}', 
            Icons.check_circle,
            AppTheme.successColor
          ),
          _buildStatRow(
            'Incorrect Answers', 
            '${examResult.statistics.incorrectAnswers}', 
            Icons.cancel,
            AppTheme.errorColor
          ),
          _buildStatRow(
            'Accuracy', 
            '${examResult.statistics.accuracy.toStringAsFixed(1)}%', 
            Icons.assessment
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, [Color? color]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.greyColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color ?? AppTheme.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(int questionNumber, QuestionResult question) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: question.isCorrect 
            ? AppTheme.successColor.withOpacity(0.05)
            : AppTheme.errorColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: question.isCorrect 
              ? AppTheme.successColor.withOpacity(0.3)
              : AppTheme.errorColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: question.isCorrect 
                      ? AppTheme.successColor 
                      : AppTheme.errorColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  question.isCorrect ? Icons.check : Icons.close,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Question $questionNumber',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${question.earnedPoints}/${question.points} points',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: question.isCorrect 
                      ? AppTheme.successColor 
                      : AppTheme.errorColor,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Question text
          Text(
            question.questionText,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Options
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Options:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.greyColor,
                ),
              ),
              const SizedBox(height: 8),
              ...question.options.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                final isSelected = index == question.selectedOption;
                final isCorrect = (question.correctAnswer is int && question.correctAnswer == index) ||
                                (question.correctAnswer is String && question.correctAnswer == option);
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? (question.isCorrect 
                            ? AppTheme.successColor.withOpacity(0.1)
                            : AppTheme.errorColor.withOpacity(0.1))
                        : (isCorrect 
                            ? AppTheme.successColor.withOpacity(0.1)
                            : Colors.transparent),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected 
                          ? (question.isCorrect 
                              ? AppTheme.successColor 
                              : AppTheme.errorColor)
                          : (isCorrect 
                              ? AppTheme.successColor 
                              : AppTheme.greyColor.withOpacity(0.3)),
                      width: isSelected || isCorrect ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (isSelected)
                        Icon(
                          question.isCorrect ? Icons.check_circle : Icons.cancel,
                          size: 18,
                          color: question.isCorrect 
                              ? AppTheme.successColor 
                              : AppTheme.errorColor,
                        )
                      else if (isCorrect)
                        const Icon(
                          Icons.check_circle,
                          size: 18,
                          color: AppTheme.successColor,
                        )
                      else
                        const SizedBox(width: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${String.fromCharCode(65 + index)}. $option',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected || isCorrect ? FontWeight.w500 : FontWeight.normal,
                            color: isSelected 
                                ? (question.isCorrect 
                                    ? AppTheme.successColor 
                                    : AppTheme.errorColor)
                                : (isCorrect 
                                    ? AppTheme.successColor 
                                    : Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }
}