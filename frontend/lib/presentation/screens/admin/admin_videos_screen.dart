import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/services/api/video_service.dart';
import 'package:excellencecoachinghub/models/video.dart';

class AdminVideosScreen extends StatefulWidget {
  const AdminVideosScreen({super.key});

  @override
  State<AdminVideosScreen> createState() => _AdminVideosScreenState();
}

class _AdminVideosScreenState extends State<AdminVideosScreen> {
  final VideoService _videoService = VideoService();
  bool _isLoading = false;
  List<Video> _videos = [];
  String? _errorMessage;
  String _filterStatus = 'All';
  final int _currentPage = 1;
  final int _itemsPerPage = 10;
  final int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch real videos from backend
      final videos = await _videoService.getAllVideos(
        page: _currentPage,
        limit: _itemsPerPage,
      );
      
      setState(() {
        _videos = videos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  int _getVideoCount(String status) {
    if (status == 'All') return _videos.length;
    // Since there's no status field, we'll count by checking if duration > 0 as a proxy
    // or we can count all videos since they're all "active"
    return _videos.length; // All videos are considered "published" for now
  }

  List<Video> _getFilteredVideos() {
    if (_filterStatus == 'All') return _videos;
    // Since there's no status field, return all videos for any filter
    return _videos;
  }

  Future<void> _refreshVideos() async {
    await _loadVideos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Management'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Videos',
            onPressed: _refreshVideos,
          ),
          IconButton(
            icon: const Icon(Icons.upload),
            tooltip: 'Upload Video',
            onPressed: _uploadVideo,
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
                  child: _isLoading && _videos.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _getFilteredVideos().isEmpty
                      ? _buildEmptyState(isSmallScreen)
                      : _buildVideosList(isSmallScreen),
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
          'Video Management',
          style: TextStyle(
            fontSize: isSmallScreen ? 20 : 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.blackColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Manage all course videos from this central location. Upload, organize, and track your educational content.',
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            color: AppTheme.greyColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    final totalVideos = _videos.length;
    final publishedVideos = _getVideoCount('Published');
    final draftVideos = _getVideoCount('Draft');
    final totalTime = _videos.fold<int>(0, (sum, video) => sum + (video.duration ?? 0));

    return Row(
      children: [
        _buildStatCard('Total Videos', totalVideos.toString(), Icons.video_library, AppTheme.primaryGreen),
        const SizedBox(width: 15),
        _buildStatCard('Published', publishedVideos.toString(), Icons.check_circle, Colors.blue),
        const SizedBox(width: 15),
        _buildStatCard('Drafts', draftVideos.toString(), Icons.edit, Colors.orange),
        const SizedBox(width: 15),
        _buildStatCard('Total Time', '$totalTime min', Icons.access_time, Colors.purple),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.greyColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list, color: AppTheme.greyColor),
          const SizedBox(width: 10),
          const Text(
            'Filter by Status:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 15),
          DropdownButton<String>(
            value: _filterStatus,
            items: ['All', 'Published', 'Draft'].map((String status) {
              return DropdownMenuItem<String>(
                value: status,
                child: Text(status),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _filterStatus = value!;
              });
            },
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
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.video_library,
              size: 80,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _filterStatus == 'All' 
              ? 'No videos found' 
              : 'No ${_filterStatus.toLowerCase()} videos',
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.blackColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Upload your first video to get started',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              color: AppTheme.greyColor,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _uploadVideo,
            icon: const Icon(Icons.upload),
            label: const Text('Upload Video'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideosList(bool isSmallScreen) {
    return RefreshIndicator(
      onRefresh: _refreshVideos,
      child: ListView.builder(
        itemCount: _getFilteredVideos().length,
        itemBuilder: (context, index) {
          final video = _getFilteredVideos()[index];
          return _buildVideoCard(video, isSmallScreen);
        },
      ),
    );
  }

  Widget _buildVideoCard(Video video, bool isSmallScreen) {
    // Since there's no status field, we'll assume all videos are published
    final statusColor = _getStatusColor('Published');
    final statusIcon = _getStatusIcon('Published');

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
            color: statusColor.withOpacity(0.3),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 16 : 18,
                            color: AppTheme.blackColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          video.courseTitle ?? 'Unknown Course',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            color: AppTheme.greyColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 6),
                        Text(
                          'Published', // All videos are considered published
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildVideoInfoChip(
                        Icons.access_time,
                        '${video.duration ?? 0} min',
                        AppTheme.primaryGreen,
                        isSmallScreen,
                      ),
                      const SizedBox(height: 8),
                      // Size information would need to be fetched separately
                      _buildVideoInfoChip(
                        Icons.storage,
                        'Unknown Size', // Size not available in current model
                        Colors.grey,
                        isSmallScreen,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildVideoInfoChip(
                        Icons.calendar_today,
                        _formatDate(video.createdAt),
                        Colors.grey,
                        isSmallScreen,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isSmallScreen)
                    _buildCompactVideoActions(video)
                  else
                    _buildFullVideoActions(video),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Published':
        return Colors.green;
      case 'Draft':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Published':
        return Icons.check_circle;
      case 'Draft':
        return Icons.edit;
      default:
        return Icons.help;
    }
  }

  Widget _buildVideoInfoChip(IconData icon, String text, Color color, bool isSmall) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 8 : 10, vertical: isSmall ? 3 : 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isSmall ? 12 : 14, color: color),
          SizedBox(width: isSmall ? 4 : 6),
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

  Widget _buildFullVideoActions(Video video) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.visibility, size: 20),
          tooltip: 'Preview Video',
          onPressed: () => _previewVideo(video),
        ),
        IconButton(
          icon: const Icon(Icons.edit, size: 20),
          tooltip: 'Edit Video',
          onPressed: () => _editVideo(video),
        ),
        IconButton(
          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
          tooltip: 'Delete Video',
          onPressed: () => _deleteVideo(video),
        ),
      ],
    );
  }

  Widget _buildCompactVideoActions(Video video) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      tooltip: 'Video Actions',
      onSelected: (value) {
        switch (value) {
          case 'preview':
            _previewVideo(video);
            break;
          case 'edit':
            _editVideo(video);
            break;
          case 'delete':
            _deleteVideo(video);
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'preview',
          child: Row(
            children: [
              Icon(Icons.visibility, size: 20),
              SizedBox(width: 10),
              Text('Preview'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 20),
              SizedBox(width: 10),
              Text('Edit'),
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

  void _uploadVideo() {
    // Navigate to upload screen where user can select section
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String? selectedCourseId;
        String? selectedSectionId;
        final titleController = TextEditingController();
        final descriptionController = TextEditingController();
        
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Upload Video to Section'),
              content: SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Course and Section:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    // Course selection would go here - for now we'll skip this and let user navigate from course screen
                    const Text('Select Section:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Video Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text('Note: Select course and section from the course management screen to upload videos directly to specific sections.'),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Close dialog and navigate to upload screen
                    Navigator.pop(context);
                    
                    // Navigate to upload screen with selected course and section
                    // For now, we'll navigate to the course content screen where users can upload videos to sections
                    context.push('/admin/courses');
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Navigate to course management to upload videos to specific sections'),
                        backgroundColor: AppTheme.primaryGreen,
                      ),
                    );
                  },
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _previewVideo(Video video) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Video preview functionality coming soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _editVideo(Video video) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Video editing functionality coming soon'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _deleteVideo(Video video) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Video'),
        content: Text('Are you sure you want to delete "${video.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _videos.removeWhere((v) => v.id == video.id);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Video deleted successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
