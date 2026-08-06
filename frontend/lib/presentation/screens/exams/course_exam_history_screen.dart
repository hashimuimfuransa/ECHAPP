import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/services/api/quiz_service.dart';
import 'package:excellencecoachinghub/presentation/screens/exams/exam_question_details_screen.dart';

/// A quiz belonging to a course, with the lesson/chapter it lives under.
class CourseQuizRef {
  final String quizId;
  final String lessonTitle;
  final String chapterTitle;

  const CourseQuizRef({
    required this.quizId,
    required this.lessonTitle,
    required this.chapterTitle,
  });
}

/// Attempt history for every quiz in a single course.
///
/// The API only exposes attempts per quiz (`/quizzes/:examId/my-attempts`),
/// so the history is assembled by fetching each quiz in the course.
class CourseExamHistoryScreen extends StatefulWidget {
  final String courseTitle;
  final List<CourseQuizRef> quizzes;

  const CourseExamHistoryScreen({
    super.key,
    required this.courseTitle,
    required this.quizzes,
  });

  @override
  State<CourseExamHistoryScreen> createState() =>
      _CourseExamHistoryScreenState();
}

typedef _QuizHistory = ({
  CourseQuizRef quiz,
  List<Map<String, dynamic>> attempts,
});

class _CourseExamHistoryScreenState extends State<CourseExamHistoryScreen> {
  List<_QuizHistory> _history = const [];
  bool _isLoading = true;
  bool _failedToLoad = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _isLoading = true);

    int failures = 0;
    final results = <_QuizHistory>[];

    // Fetched a few at a time: every request refreshes the auth token, so a
    // course with many quizzes shouldn't fire them all at once.
    const batchSize = 4;
    for (int i = 0; i < widget.quizzes.length; i += batchSize) {
      final batch = widget.quizzes.skip(i).take(batchSize);
      results.addAll(await Future.wait(
        batch.map((q) async {
          try {
            final attempts = await QuizService.getStudentQuizAttempts(q.quizId);
            return (quiz: q, attempts: attempts);
          } catch (e) {
            failures++;
            debugPrint('Exam history: failed to load ${q.quizId}: $e');
            return (quiz: q, attempts: <Map<String, dynamic>>[]);
          }
        }),
      ));
      if (!mounted) return;
    }
    if (!mounted) return;

    setState(() {
      // Quizzes that were never attempted stay out of the way at the bottom
      _history = results
        ..sort((a, b) {
          if (a.attempts.isEmpty != b.attempts.isEmpty) {
            return a.attempts.isEmpty ? 1 : -1;
          }
          return 0;
        });
      // Only treat it as an error when nothing at all could be fetched
      _failedToLoad = failures == widget.quizzes.length && failures > 0;
      _isLoading = false;
    });
  }

  int get _attemptCount =>
      _history.fold(0, (sum, h) => sum + h.attempts.length);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('Exam history'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _load,
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (_failedToLoad) {
      return _buildMessage(
        context,
        icon: Icons.wifi_off_rounded,
        title: 'Could not load your exam history',
        subtitle: 'Check your connection and try again.',
        action: ElevatedButton(
          onPressed: _load,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Retry'),
        ),
      );
    }

    if (_attemptCount == 0) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            _buildMessage(
              context,
              icon: Icons.quiz_outlined,
              title: 'No attempts yet',
              subtitle: widget.quizzes.isEmpty
                  ? 'This course has no quizzes yet.'
                  : 'Quizzes you take in ${widget.courseTitle} will show up here.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: _history.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) return _buildSummary(context);
          return _buildQuizCard(context, _history[index - 1]);
        },
      ),
    );
  }

  Widget _buildSummary(BuildContext context) {
    final passedQuizzes = _history
        .where((h) => h.attempts.any((a) => _isPassed(a)))
        .length;
    final attempted = _history.where((h) => h.attempts.isNotEmpty).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.courseTitle,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildStat(context, '$_attemptCount', 'Attempts'),
              _buildStat(context, '$attempted/${_history.length}', 'Quizzes taken'),
              _buildStat(context, '$passedQuizzes', 'Passed'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(BuildContext context, String value, String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.primary,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.getSecondaryTextColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizCard(BuildContext context, _QuizHistory history) {
    final attempts = history.attempts;
    final best = _bestPercentage(attempts);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        history.quiz.lessonTitle,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.getTextColor(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        history.quiz.chapterTitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.getSecondaryTextColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
                if (best != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _scoreColor(attempts).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Best ${best.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _scoreColor(attempts),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (attempts.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text(
                'Not attempted yet',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.getSecondaryTextColor(context),
                ),
              ),
            )
          else
            ...attempts.asMap().entries.map((e) {
              // Attempts arrive newest first, so number them backwards
              final number = attempts.length - e.key;
              return _buildAttemptRow(context, e.value, number);
            }),
        ],
      ),
    );
  }

  Widget _buildAttemptRow(
      BuildContext context, Map<String, dynamic> attempt, int number) {
    final passed = _isPassed(attempt);
    final percentage = _percentage(attempt);
    final score = attempt['totalScore'];
    final maxScore = attempt['maxScore'];
    final color = passed ? AppTheme.primary : Colors.orange.shade700;
    final questionCount = _questionCount(attempt);

    return InkWell(
      onTap: () => _openAttemptReview(attempt),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: AppTheme.getBorderColor(context), width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              passed ? Icons.check_circle_rounded : Icons.cancel_rounded,
              size: 18,
              color: color,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Attempt $number • ${passed ? 'Passed' : 'Not passed'}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.getTextColor(context),
                    ),
                  ),
                  Text(
                    _formatDate(attempt['submittedAt']),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.getSecondaryTextColor(context),
                    ),
                  ),
                  if (questionCount > 0)
                    Text(
                      'Tap to review $questionCount '
                      '${questionCount == 1 ? 'question' : 'questions'}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                if (score != null && maxScore != null)
                  Text(
                    '$score/$maxScore',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.getSecondaryTextColor(context),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppTheme.getSecondaryTextColor(context),
            ),
          ],
        ),
      ),
    );
  }

  /// Opens the question-by-question breakdown of a single attempt. The
  /// per-question results are stored on the submission itself, so no extra
  /// request is needed.
  void _openAttemptReview(Map<String, dynamic> attempt) {
    if (_questionCount(attempt) == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This attempt has no saved answers to review'),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExamQuestionDetailsScreen(examResult: attempt),
      ),
    );
  }

  Widget _buildMessage(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppTheme.getSecondaryTextColor(context)),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.getTextColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.getSecondaryTextColor(context),
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 20),
              action,
            ],
          ],
        ),
      ),
    );
  }

  // ── Attempt helpers ───────────────────────────────────────────────────────

  bool _isPassed(Map<String, dynamic> attempt) => attempt['passed'] == true;

  int _questionCount(Map<String, dynamic> attempt) =>
      (attempt['results'] as List?)?.length ?? 0;

  num _percentage(Map<String, dynamic> attempt) =>
      (attempt['percentage'] as num?) ?? (attempt['score'] as num?) ?? 0;

  num? _bestPercentage(List<Map<String, dynamic>> attempts) {
    num? best;
    for (final a in attempts) {
      final value = _percentage(a);
      if (best == null || value > best) best = value;
    }
    return best;
  }

  Color _scoreColor(List<Map<String, dynamic>> attempts) =>
      attempts.any(_isPassed) ? AppTheme.primary : Colors.orange.shade700;

  String _formatDate(dynamic submittedAt) {
    final parsed = DateTime.tryParse(submittedAt?.toString() ?? '');
    if (parsed == null) return 'Date unavailable';
    return DateFormat('MMM d, y • HH:mm').format(parsed.toLocal());
  }
}
