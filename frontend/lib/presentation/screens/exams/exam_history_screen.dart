import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/services/api/exam_service.dart';
import 'package:excellencecoachinghub/data/repositories/exam_repository.dart';
import 'exam_question_details_screen.dart';

/// Screen to display user's exam history with detailed results
class ExamHistoryScreen extends ConsumerStatefulWidget {
  const ExamHistoryScreen({super.key});

  @override
  ConsumerState<ExamHistoryScreen> createState() => _ExamHistoryScreenState();
}

class _ExamHistoryScreenState extends ConsumerState<ExamHistoryScreen> {
  List<ExamResult> _examHistory = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadExamHistory();
  }

  Future<void> _loadExamHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final examService = ExamService();
      final history = await examService.getUserExamHistory();
      setState(() {
        _examHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: Text(
          'Exam History',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.getTextColor(context)
          ),
        ),
        backgroundColor: AppTheme.getCardColor(context),
        foregroundColor: AppTheme.getTextColor(context),
        elevation: 0,
        centerTitle: false,
        actions: [
          if (_examHistory.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.red),
              onPressed: _confirmDeleteAllExamResults,
              tooltip: 'Delete All History',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadExamHistory,
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  void _confirmDeleteAllExamResults() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete All Exam History'),
          content: Text(
            'Are you sure you want to delete all ${_examHistory.length} exam results? '
            'This action cannot be undone.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteAllExamResults();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete All'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAllExamResults() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final examService = ExamService();
      await examService.deleteAllExamResults();
      
      // Refresh the exam history to show empty state
      await _loadExamHistory();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All exam history deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete exam history: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryGreen),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.getTextColor(context),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load exam history',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppTheme.getTextColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.greyColor),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadExamHistory,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_examHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: AppTheme.greyColor,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Exam History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You haven\'t taken any exams yet.\nStart learning and take your first exam!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.greyColor),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadExamHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _examHistory.length,
        itemBuilder: (context, index) {
          final result = _examHistory[index];
          return _buildExamHistoryCard(result);
        },
      ),
    );
  }

  Widget _buildExamHistoryCard(ExamResult result) {
    final isPassed = result.passed;
    final percentage = (result.percentage ?? 0.0).toStringAsFixed(1);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () => _showExamDetails(result),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with exam title and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      result.examDetails?.title ?? 'Unknown Exam',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (String choice) {
                      if (choice == 'delete') {
                        _confirmDeleteExamResult(result);
                      } else if (choice == 'details') {
                        _showExamDetails(result);
                      } else if (choice == 'review') {
                        _showQuestionDetails(result);
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      return <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'details',
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 16),
                              SizedBox(width: 8),
                              Text('View Details'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'review',
                          child: Row(
                            children: [
                              Icon(Icons.quiz, size: 16),
                              SizedBox(width: 8),
                              Text('Question Review'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 16, color: Colors.red),
                              const SizedBox(width: 8),
                              const Text('Delete Result', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ];
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isPassed 
                            ? AppTheme.successColor.withOpacity(0.1)
                            : AppTheme.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPassed ? Icons.check_circle : Icons.cancel,
                            size: 16,
                            color: isPassed 
                                ? AppTheme.successColor 
                                : AppTheme.errorColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isPassed ? 'Passed' : 'Failed',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isPassed 
                                  ? AppTheme.successColor 
                                  : AppTheme.errorColor,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Course and section info
              if (result.examDetails?.courseId != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.school,
                      size: 16,
                      color: AppTheme.greyColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Course ID: ${result.examDetails!.courseId}',
                        style: TextStyle(
                          color: AppTheme.greyColor,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              
              if (result.examDetails?.sectionId != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.folder,
                      size: 16,
                      color: AppTheme.greyColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Section ID: ${result.examDetails!.sectionId}',
                        style: TextStyle(
                          color: AppTheme.greyColor,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              
              // Score and percentage
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Score',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.greyColor,
                          ),
                        ),
                        Text(
                          '${result.score ?? 0}/${result.totalPoints ?? 0}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Percentage',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.greyColor,
                          ),
                        ),
                        Text(
                          '$percentage%',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Submission date
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppTheme.greyColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Taken on ${_formatDate(result.submittedAt)}',
                    style: TextStyle(
                      color: AppTheme.greyColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showExamDetails(result),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('View Details'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showQuestionDetails(result),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Question Review'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteExamResult(ExamResult result) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Exam Result'),
          content: Text('Are you sure you want to delete the result for "${result.examDetails?.title ?? 'Unknown Exam'}"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteExamResult(result.resultId);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteExamResult(String resultId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final examService = ExamService();
      await examService.deleteExamResult(resultId);
      
      // Refresh the exam history to remove the deleted item
      await _loadExamHistory();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exam result deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete exam result: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showExamDetails(ExamResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ExamDetailsSheet(result: result),
    );
  }

  void _showQuestionDetails(ExamResult result) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExamQuestionDetailsScreen(examResult: result),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown date';
    try {
      return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }
}

/// Bottom sheet to show detailed exam results
class _ExamDetailsSheet extends StatelessWidget {
  final ExamResult result;

  const _ExamDetailsSheet({required this.result});

  @override
  Widget build(BuildContext context) {
    final isPassed = result.passed;
    final percentage = (result.percentage ?? 0.0).toStringAsFixed(1);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.greyColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Exam Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Exam title
                  Text(
                    result.examDetails?.title ?? 'Unknown Exam',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isPassed 
                          ? AppTheme.successColor.withOpacity(0.1)
                          : AppTheme.errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isPassed ? 'PASSED' : 'FAILED',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isPassed 
                            ? AppTheme.successColor 
                            : AppTheme.errorColor,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Score details
                  _buildDetailCard(
                    title: 'Score Details',
                    children: [
                      _buildScoreRow('Your Score', '${result.score ?? 0}', Icons.quiz),
                      _buildScoreRow('Total Points', '${result.totalPoints ?? 0}', Icons.score),
                      _buildScoreRow('Percentage', '$percentage%', Icons.percent),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Course info
                  if (result.examDetails != null) ...[
                    _buildDetailCard(
                      title: 'Course Information',
                      children: [
                        if (result.examDetails?.courseId != null)
                          _buildInfoRow('Course ID', result.examDetails!.courseId, Icons.school),
                        if (result.examDetails?.sectionId != null)
                          _buildInfoRow('Section ID', result.examDetails!.sectionId, Icons.folder),
                        if (result.examDetails?.type != null)
                          _buildInfoRow('Type', _getExamTypeLabel(result.examDetails!.type), Icons.category),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Submission date
                  _buildDetailCard(
                    title: 'Submission Information',
                    children: [
                      _buildInfoRow(
                        'Submitted At', 
                        _formatDate(result.submittedAt), 
                        Icons.access_time
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.greyColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildScoreRow(String label, String value, IconData icon) {
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
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.greyColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.greyColor,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getExamTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'quiz':
        return 'Quiz';
      case 'pastpaper':
        return 'Past Paper';
      case 'final':
        return 'Final Exam';
      default:
        return type;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown date';
    try {
      return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }
}
