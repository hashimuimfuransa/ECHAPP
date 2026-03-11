import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/services/api/exam_service.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';
import 'package:excellencecoachinghub/presentation/providers/sidebar_provider.dart';
import 'package:intl/intl.dart';

class AdminExamsReviewScreen extends ConsumerStatefulWidget {
  const AdminExamsReviewScreen({super.key});

  @override
  ConsumerState<AdminExamsReviewScreen> createState() => _AdminExamsReviewScreenState();
}

class _AdminExamsReviewScreenState extends ConsumerState<AdminExamsReviewScreen> {
  final ExamService _examService = ExamService();
  final TextEditingController _searchController = TextEditingController();
  List<ExamResult>? _results;
  bool _isLoading = true;
  String? _error;
  String _selectedType = 'all';
  final List<String> _examTypes = ['all', 'quiz', 'midterm', 'final'];

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadResults() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await _examService.getAllExamResults(
        examType: _selectedType == 'all' ? null : _selectedType,
        search: _searchController.text.isNotEmpty ? _searchController.text : null,
      );
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    // Responsive sidebar auto-collapse
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool shouldBeCollapsed = screenWidth < 1100 && screenWidth >= 600;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isCurrentlyCollapsed = ref.read(sidebarProvider);
      if (shouldBeCollapsed && !isCurrentlyCollapsed) {
        ref.read(sidebarProvider.notifier).setCollapsed(true);
      }
    });

    final isCollapsed = ref.watch(sidebarProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: !isDesktop ? _buildDrawer(context) : null,
      body: Row(
        children: [
          if (isDesktop) _buildSidebar(context, isCollapsed),
          Expanded(
            child: Column(
              children: [
                _buildHeader(context, isDesktop),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? _buildErrorState()
                          : _buildContent(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, bool isCollapsed) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: isCollapsed ? 80 : 280,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(5, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(isCollapsed ? 12 : 24, 40, isCollapsed ? 12 : 24, 32),
            child: Row(
              mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.asset(
                    'assets/logo.png',
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                  ),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin Panel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.getTextColor(context),
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'EXCELLENCE HUB',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 0 : 16),
              children: [
                _buildSidebarItem(context, 'Dashboard', Icons.dashboard_rounded, '/admin', false, isCollapsed),
                _buildSidebarItem(context, 'Courses', Icons.school_rounded, '/admin/courses', false, isCollapsed),
                _buildSidebarItem(context, 'Students', Icons.people_rounded, '/admin/students', false, isCollapsed),
                _buildSidebarItem(context, 'Exams Review', Icons.quiz_rounded, '/admin/exams-review', true, isCollapsed),
                _buildSidebarItem(context, 'Analytics', Icons.analytics_rounded, '/admin/analytics', false, isCollapsed),
                _buildSidebarItem(context, 'Payments', Icons.payments_rounded, '/admin/payments', false, isCollapsed),
                _buildSidebarItem(context, 'Settings', Icons.settings_rounded, '/admin/settings', false, isCollapsed),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(BuildContext context, String title, IconData icon, String route, bool isActive, bool isCollapsed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isActive ? null : () => context.go(route),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 0 : 16, 
              vertical: 10
            ),
            alignment: isCollapsed ? Alignment.center : Alignment.centerLeft,
            decoration: isActive
                ? BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  )
                : null,
            child: isCollapsed
                ? Icon(
                    icon,
                    color: isActive ? AppTheme.primaryGreen : AppTheme.greyColor.withOpacity(0.7),
                    size: 22,
                  )
                : Row(
                    children: [
                      Icon(
                        icon,
                        color: isActive ? AppTheme.primaryGreen : AppTheme.greyColor.withOpacity(0.7),
                        size: 20,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: isActive ? AppTheme.primaryGreen : AppTheme.getTextColor(context).withOpacity(0.8),
                            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isActive)
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDesktop) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.05))),
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (!isDesktop)
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              Text(
                'Exams Performance Tracking',
                style: TextStyle(
                  fontSize: isDesktop ? 24 : 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              _buildFilterDropdown(),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _loadResults,
                tooltip: 'Refresh Results',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSearchBar(isDesktop),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDesktop) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: isDesktop ? 600 : double.infinity,
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by student name or email...',
          prefixIcon: const Icon(Icons.search, color: AppTheme.greyColor),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _loadResults();
                  },
                )
              : null,
          filled: true,
          fillColor: AppTheme.greyColor.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onSubmitted: (value) => _loadResults(),
        onChanged: (value) {
          if (value.isEmpty) {
            _loadResults();
          }
          setState(() {}); // Update to show/hide clear icon
        },
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedType,
          items: _examTypes.map((type) => DropdownMenuItem(
            value: type,
            child: Text(type.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
          )).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedType = value);
              _loadResults();
            }
          },
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: $_error'),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadResults, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_results == null || _results!.isEmpty) {
      return const Center(child: Text('No exam results found for this filter.'));
    }

    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _results!.length,
      itemBuilder: (context, index) {
        final result = _results![index];
        return _buildResultCard(context, result, isDesktop);
      },
    );
  }

  Widget _buildStatisticsCard(ExamResult result) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistics Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatRow(
                  'Total Questions', 
                  '${result.statistics.totalQuestions}', 
                  Icons.question_mark
                ),
              ),
              Expanded(
                child: _buildStatRow(
                  'Correct Answers', 
                  '${result.statistics.correctAnswers}', 
                  Icons.check_circle,
                  AppTheme.successColor
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatRow(
                  'Incorrect Answers', 
                  '${result.statistics.incorrectAnswers}', 
                  Icons.cancel,
                  AppTheme.errorColor
                ),
              ),
              Expanded(
                child: _buildStatRow(
                  'Accuracy', 
                  '${result.statistics.accuracy.toStringAsFixed(1)}%', 
                  Icons.assessment
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, [Color? color]) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.greyColor.withOpacity(0.7)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color ?? AppTheme.primaryGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(BuildContext context, ExamResult result, bool isDesktop) {
    final hasClaim = result.studentClaim != null && result.studentClaim!.isNotEmpty;
    final isPassed = result.passed;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: hasClaim ? Colors.orange.withOpacity(0.3) : Colors.black.withOpacity(0.05),
          width: hasClaim ? 2 : 1,
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: (isPassed ? Colors.green : Colors.red).withOpacity(0.1),
          child: Icon(
            isPassed ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: isPassed ? Colors.green : Colors.red,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.studentName ?? 'Unknown Student',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    result.examDetails?.title ?? 'Unknown Exam',
                    style: TextStyle(color: AppTheme.greyColor, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (hasClaim)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'CLAIM PENDING',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              _buildInfoBadge('Score: ${result.score}/${result.totalPoints}', Colors.blue),
              const SizedBox(width: 8),
              _buildInfoBadge(result.examDetails?.type.toUpperCase() ?? 'QUIZ', Colors.purple),
              const SizedBox(width: 8),
              Text(
                result.submittedAt != null ? DateFormat('MMM dd, yyyy HH:mm').format(result.submittedAt!) : '',
                style: const TextStyle(fontSize: 11, color: AppTheme.greyColor),
              ),
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasClaim) ...[
                  const Text('Student Claim:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.2)),
                    ),
                    child: Text(result.studentClaim!),
                  ),
                  const SizedBox(height: 24),
                ],
                if (result.adminComment != null) ...[
                  const Text('Admin Comment:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(result.adminComment!),
                  const SizedBox(height: 24),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showRegradeDialog(context, result),
                      icon: const Icon(Icons.edit_note_rounded),
                      label: const Text('Review & Regrade'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryGreen,
                        side: const BorderSide(color: AppTheme.primaryGreen),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),
                
                // Statistics Summary
                _buildStatisticsCard(result),
                
                const Text(
                  'Question Analysis:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 16),
                if (result.questions.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No question detail available for this exam.'),
                    ),
                  )
                else
                  ...result.questions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final q = entry.value;
                    return _buildQuestionResult(q, index + 1);
                  }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionResult(QuestionResult q, int questionNumber) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: q.isCorrect ? Colors.green.withOpacity(0.02) : Colors.red.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (q.isCorrect ? Colors.green : Colors.red).withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: q.isCorrect ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (q.isCorrect ? Colors.green : Colors.red).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  q.isCorrect ? Icons.check : Icons.close,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Question $questionNumber',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (q.isCorrect ? Colors.green : Colors.red).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${q.earnedPoints}/${q.points} pts',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: q.isCorrect ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            q.questionText,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.4),
          ),
          const SizedBox(height: 20),
          
          // Options for MCQ and True/False
          if (q.options.isNotEmpty && (q.type == 'mcq' || q.type == 'true_false')) ...[
            const Text(
              'Options:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.greyColor),
            ),
            const SizedBox(height: 8),
            ...q.options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final isSelected = index == q.selectedOption;
              final isCorrect = (q.correctAnswer is int && q.correctAnswer == index) ||
                                (q.correctAnswer is String && q.correctAnswer == option);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? (q.isCorrect ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1))
                      : (isCorrect ? Colors.green.withOpacity(0.1) : Colors.transparent),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected 
                        ? (q.isCorrect ? Colors.green : Colors.red)
                        : (isCorrect ? Colors.green : Colors.grey.withOpacity(0.2)),
                    width: isSelected || isCorrect ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      '${String.fromCharCode(65 + index)}.',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected || isCorrect ? (isCorrect ? Colors.green : Colors.red) : AppTheme.greyColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          color: isSelected || isCorrect ? (isCorrect ? Colors.green : Colors.red) : null,
                          fontWeight: isSelected || isCorrect ? FontWeight.bold : null,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        q.isCorrect ? Icons.check_circle : Icons.cancel,
                        size: 18,
                        color: q.isCorrect ? Colors.green : Colors.red,
                      )
                    else if (isCorrect)
                      const Icon(Icons.check_circle, size: 18, color: Colors.green),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
          ],

          // For other types or simple display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.greyColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person, size: 14, color: AppTheme.greyColor),
                    const SizedBox(width: 8),
                    Text(
                      'Student\'s Answer:',
                      style: TextStyle(fontSize: 12, color: AppTheme.greyColor, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  q.selectedOptionText,
                  style: TextStyle(
                    color: q.isCorrect ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.verified, size: 14, color: Colors.green),
                    const SizedBox(width: 8),
                    const Text(
                      'Correct Answer:',
                      style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  q.correctAnswerText,
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: AppTheme.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Image.asset(
                    'assets/logo.png',
                    width: 32,
                    height: 32,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Admin Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _buildMobileNavItem(context, 'Dashboard', Icons.dashboard_rounded, '/admin', false),
                _buildMobileNavItem(context, 'Courses', Icons.school_rounded, '/admin/courses', false),
                _buildMobileNavItem(context, 'Students', Icons.people_rounded, '/admin/students', false),
                _buildMobileNavItem(context, 'Exams Review', Icons.quiz_rounded, '/admin/exams-review', true),
                _buildMobileNavItem(context, 'Analytics', Icons.analytics_rounded, '/admin/analytics', false),
                _buildMobileNavItem(context, 'Payments', Icons.payments_rounded, '/admin/payments', false),
                _buildMobileNavItem(context, 'Settings', Icons.settings_rounded, '/admin/settings', false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileNavItem(BuildContext context, String title, IconData icon, String route, bool isActive) {
    return ListTile(
      leading: Icon(icon, color: isActive ? AppTheme.primaryGreen : Colors.grey),
      title: Text(title, style: TextStyle(color: isActive ? AppTheme.primaryGreen : null, fontWeight: isActive ? FontWeight.bold : null)),
      onTap: isActive ? null : () {
        Navigator.pop(context);
        context.go(route);
      },
      selected: isActive,
    );
  }

  void _showRegradeDialog(BuildContext context, ExamResult result) {
    final scoreController = TextEditingController(text: result.score.toString());
    final commentController = TextEditingController(text: result.adminComment ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Regrade: ${result.studentName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: scoreController,
              decoration: const InputDecoration(labelText: 'New Score'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(labelText: 'Admin Comment'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newScore = int.tryParse(scoreController.text);
              if (newScore == null) return;
              
              Navigator.pop(context);
              setState(() => _isLoading = true);
              
              try {
                await _examService.regradeExamResult(
                  resultId: result.resultId,
                  newScore: newScore,
                  adminComment: commentController.text,
                );
                _loadResults();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Exam regraded successfully'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                setState(() => _isLoading = false);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to regrade: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
}
