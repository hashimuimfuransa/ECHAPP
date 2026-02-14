import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/models/exam.dart' as exam_model;
import 'package:excellencecoachinghub/services/api/exam_service.dart';
import 'package:excellencecoachinghub/data/repositories/exam_repository.dart';

class CourseExamsScreen extends StatefulWidget {
  final String courseId;
  
  const CourseExamsScreen({super.key, required this.courseId});

  @override
  State<CourseExamsScreen> createState() => _CourseExamsScreenState();
}

class _CourseExamsScreenState extends State<CourseExamsScreen> {
  final ExamService _examService = ExamService();
  bool _isLoading = false;
  List<exam_model.Exam> _exams = [];
  String? _errorMessage;
  String _filterStatus = 'All';
  final int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _examService.getAllExams(
        courseId: widget.courseId,
        page: _currentPage,
      );
      
      setState(() {
        _exams = response.exams;
        _totalPages = response.totalPages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _createNewExam() async {
    // Navigate to course content page to create exam within a section
    if (widget.courseId == 'all') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a specific course to create an exam'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    
    // Navigate to course content page where exams can be created within sections
    context.push('/admin/courses/${widget.courseId}/content');
  }

  Future<void> _toggleExamStatus(String examId) async {
    final examIndex = _exams.indexWhere((exam) => exam.id == examId);
    if (examIndex != -1) {
      try {
        final updatedExam = await _examService.updateExam(
          id: examId,
          isPublished: !_exams[examIndex].isPublished,
        );
        
        setState(() {
          _exams[examIndex] = updatedExam;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Exam ${updatedExam.isPublished ? 'activated' : 'deactivated'} successfully'
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update exam: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteExam(String examId) async {
    final examToDelete = _exams.firstWhere((exam) => exam.id == examId);
    
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exam'),
        content: Text('Are you sure you want to delete "${examToDelete.title}"? All student results will be permanently lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await _examService.deleteExam(examId);
        
        setState(() {
          _exams.removeWhere((exam) => exam.id == examId);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Exam deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete exam: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showEditExamDialog(exam_model.Exam exam) {
    final titleController = TextEditingController(text: exam.title);
    final passingScoreController = TextEditingController(text: exam.passingScore.toString());
    final timeLimitController = TextEditingController(text: exam.timeLimit.toString());
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Exam'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Exam Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passingScoreController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Passing Score (%)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: timeLimitController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Time Limit (minutes)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Validation
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Exam title is required')),
                  );
                  return;
                }
                
                final passingScore = int.tryParse(passingScoreController.text);
                if (passingScore == null || passingScore < 0 || passingScore > 100) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Passing score must be between 0 and 100')),
                  );
                  return;
                }
                
                final timeLimit = int.tryParse(timeLimitController.text);
                if (timeLimit == null || timeLimit <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Time limit must be a positive number')),
                  );
                  return;
                }
                
                Navigator.pop(context);
                
                try {
                  final examRepo = ExamRepository();
                  final updatedExam = await examRepo.updateExam(
                    examId: exam.id,
                    title: titleController.text.trim(),
                    passingScore: passingScore,
                    timeLimit: timeLimit,
                  );
                  
                  // Update the local state
                  setState(() {
                    final index = _exams.indexWhere((e) => e.id == exam.id);
                    if (index != -1) {
                      _exams[index] = updatedExam;
                    }
                  });
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Exam updated successfully'),
                        backgroundColor: AppTheme.primaryGreen,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update exam: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  List<exam_model.Exam> _getFilteredExams() {
    if (_filterStatus == 'All') return _exams;
    final isActive = _filterStatus == 'Active';
    return _exams.where((exam) => exam.isPublished == isActive).toList();
  }

  int _getExamCount(String status) {
    if (status == 'All') return _exams.length;
    final isActive = status == 'Active';
    return _exams.where((exam) => exam.isPublished == isActive).length;
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}h ${remainingMinutes}min';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _refreshExams() async {
    await _loadExams();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Management'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Exams',
            onPressed: _refreshExams,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create New Exam',
            onPressed: _createNewExam,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 768;
          
          return Padding(
            padding: EdgeInsets.all(isSmallScreen ? 15 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderSection(isSmallScreen),
                const SizedBox(height: 20),
                _buildStatsSection(),
                const SizedBox(height: 20),
                _buildFilterSection(),
                const SizedBox(height: 20),
                _buildErrorMessage(),
                const SizedBox(height: 20),
                Expanded(
                  child: _isLoading && _exams.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _getFilteredExams().isEmpty
                      ? _buildEmptyState(isSmallScreen)
                      : _buildExamsList(isSmallScreen),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Exam Management',
          style: TextStyle(
            fontSize: isSmallScreen ? 20 : 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.blackColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Create quizzes, set time limits, configure question types, and track student performance. Monitor exam analytics and results.',
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            color: AppTheme.greyColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Total Exams: ${_getExamCount('All')}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.blackColor,
          ),
        ),
        Text(
          'Active Exams: ${_getExamCount('Active')}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.blackColor,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Filter by Status',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.blackColor,
            ),
          ),
          DropdownButton<String>(
            value: _filterStatus,
            onChanged: (value) {
              setState(() {
                _filterStatus = value!;
              });
            },
            items: const [
              DropdownMenuItem(
                value: 'All',
                child: Text('All'),
              ),
              DropdownMenuItem(
                value: 'Active',
                child: Text('Active'),
              ),
              DropdownMenuItem(
                value: 'Inactive',
                child: Text('Inactive'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    if (_errorMessage == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () => setState(() => _errorMessage = null),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isSmallScreen) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.quiz,
              size: 80,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No exams created yet',
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.blackColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Create your first assessment to evaluate student understanding. Track performance and provide feedback.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              color: AppTheme.greyColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamsList(bool isSmallScreen) {
    return RefreshIndicator(
      onRefresh: _loadExams,
      child: ListView.builder(
        itemCount: _getFilteredExams().length,
        itemBuilder: (context, index) {
          final exam = _getFilteredExams()[index];
          return _buildExamCard(exam, isSmallScreen);
        },
      ),
    );
  }

  Widget _buildExamCard(exam_model.Exam exam, bool isSmallScreen) {
    final isActive = exam.isPublished;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      exam.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 16 : 18,
                        color: AppTheme.blackColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isActive ? Icons.check_circle : Icons.pause_circle,
                          size: 16,
                          color: isActive ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: isActive ? Colors.green : Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildExamStatChip(
                    Icons.question_answer,
                    '${exam.questions} questions',
                    Colors.blue,
                    isSmallScreen,
                  ),
                  _buildExamStatChip(
                    Icons.access_time,
                    _formatDuration(exam.duration),
                    AppTheme.primaryGreen,
                    isSmallScreen,
                  ),
                  _buildExamStatChip(
                    Icons.check,
                    '${exam.passingScore}% to pass',
                    Colors.orange,
                    isSmallScreen,
                  ),
                  _buildExamStatChip(
                    Icons.people,
                    '${exam.attempts} attempts',
                    Colors.purple,
                    isSmallScreen,
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Created: ${_formatDate(exam.createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.greyColor,
                    ),
                  ),
                  if (isSmallScreen)
                    _buildCompactExamActions(exam)
                  else
                    _buildFullExamActions(exam),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExamStatChip(IconData icon, String text, Color color, bool isSmall) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 10 : 12, vertical: isSmall ? 4 : 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isSmall ? 14 : 16, color: color),
          SizedBox(width: isSmall ? 5 : 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: isSmall ? 11 : 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullExamActions(exam_model.Exam exam) {
    final isActive = exam.isPublished;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(isActive ? Icons.pause : Icons.play_arrow, size: 20),
          tooltip: isActive ? 'Deactivate Exam' : 'Activate Exam',
          onPressed: () => _toggleExamStatus(exam.id),
        ),
        IconButton(
          icon: const Icon(Icons.bar_chart, size: 20),
          tooltip: 'View Results',
          onPressed: () => _viewResults(exam.id),
        ),
        IconButton(
          icon: const Icon(Icons.edit, size: 20),
          tooltip: 'Edit Exam',
          onPressed: () {
            // TODO: Implement exam editing
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Edit exam functionality coming soon')),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 20),
          tooltip: 'Duplicate Exam',
          onPressed: () {
            // TODO: Implement exam duplication
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Duplicate exam functionality coming soon')),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
          tooltip: 'Delete Exam',
          onPressed: () => _deleteExam(exam.id),
        ),
      ],
    );
  }

  Widget _buildCompactExamActions(exam_model.Exam exam) {
    final isActive = exam.isPublished;
    
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      tooltip: 'Exam Actions',
      onSelected: (value) {
        switch (value) {
          case 'toggle':
            _toggleExamStatus(exam.id);
            break;
          case 'results':
            _viewResults(exam.id);
            break;
          case 'edit':
            _showEditExamDialog(exam);
            break;
          case 'duplicate':
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Duplicate exam functionality coming soon')),
            );
            break;
          case 'delete':
            _deleteExam(exam.id);
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'toggle',
          child: Row(
            children: [
              Icon(isActive ? Icons.pause : Icons.play_arrow, size: 20),
              const SizedBox(width: 10),
              Text(isActive ? 'Deactivate' : 'Activate'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'results',
          child: Row(
            children: [
              Icon(Icons.bar_chart, size: 20),
              SizedBox(width: 10),
              Text('View Results'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 20),
              SizedBox(width: 10),
              Text('Edit Exam'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'duplicate',
          child: Row(
            children: [
              Icon(Icons.copy, size: 20),
              SizedBox(width: 10),
              Text('Duplicate'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 20, color: Colors.red),
              SizedBox(width: 10),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _viewResults(String examId) async {
    // Navigate to exam results screen
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exam results dashboard coming soon'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  void _showExamGuidelines() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Exam Creation Guidelines',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              const Text(
                'Best Practices:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _buildGuidelineItem('Question Types', 'Mix multiple choice, true/false, and short answer questions'),
              _buildGuidelineItem('Difficulty Levels', 'Include easy, medium, and hard questions for balanced assessment'),
              _buildGuidelineItem('Time Management', 'Allow 1-2 minutes per question on average'),
              _buildGuidelineItem('Passing Score', 'Set between 70-80% for most assessments'),
              _buildGuidelineItem('Feedback', 'Provide explanations for correct/incorrect answers'),
              _buildGuidelineItem('Attempts', 'Allow 1-3 attempts depending on exam importance'),
              const SizedBox(height: 20),
              const Text(
                'Technical Requirements:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _buildGuidelineItem('Randomization', 'Shuffle questions and answers for academic integrity'),
              _buildGuidelineItem('Auto-grading', 'Configure automatic scoring for objective questions'),
              _buildGuidelineItem('Manual Review', 'Set up manual review for subjective questions'),
              _buildGuidelineItem('Timer', 'Enable timer with warning notifications'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuidelineItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6, right: 10),
            decoration: const BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.blackColor,
                    ),
                  ),
                  TextSpan(
                    text: description,
                    style: const TextStyle(
                      color: AppTheme.greyColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _showEditExamDialog {
  _showEditExamDialog(exam_model.Exam exam);
}
