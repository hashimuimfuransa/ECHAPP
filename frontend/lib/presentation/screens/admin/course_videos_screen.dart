import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:excellence_coaching_hub/config/app_theme.dart';
import 'package:excellence_coaching_hub/services/api/video_service.dart';
import 'package:excellence_coaching_hub/models/video.dart';

class CourseVideosScreen extends StatefulWidget {
  final String courseId;
  
  const CourseVideosScreen({super.key, required this.courseId});

  @override
  State<CourseVideosScreen> createState() => _CourseVideosScreenState();
}

class _CourseVideosScreenState extends State<CourseVideosScreen> {
  final VideoService _videoService = VideoService();
  bool _isLoading = false;
  List<Video> _videos = [];
  String? _errorMessage;

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
      final videos = await _videoService.getVideosByCourse(widget.courseId);
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

  Future<void> _pickAndUploadVideo() async {
    final picker = ImagePicker();
    
    try {
      final XFile? videoFile = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 30), // 30 minute limit
      );

      if (videoFile != null) {
        await _uploadVideo(videoFile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick video: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadVideo(XFile videoFile) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Show upload progress
      final video = await _videoService.uploadVideo(
        videoFile: videoFile,
        courseId: widget.courseId,
        onProgress: (progress) {
          // Update UI with progress if needed
        },
      );

      setState(() {
        _videos.add(video);
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteVideo(String videoId) async {
    final videoToDelete = _videos.firstWhere((video) => video.id == videoId);
    
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Video'),
        content: Text('Are you sure you want to delete "${videoToDelete.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await _videoService.deleteVideo(videoId);
        
        setState(() {
          _videos.removeWhere((video) => video.id == videoId);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Video deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete video: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Videos'),
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
            onPressed: _loadVideos,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Video Guidelines',
            onPressed: _showVideoGuidelines,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 768;
          final isMediumScreen = constraints.maxWidth >= 768 && constraints.maxWidth < 1024;
          
          return Padding(
            padding: EdgeInsets.all(isSmallScreen ? 15 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderSection(isSmallScreen),
                const SizedBox(height: 20),
                _buildUploadSection(isSmallScreen),
                const SizedBox(height: 20),
                _buildErrorMessage(),
                const SizedBox(height: 20),
                Expanded(
                  child: _isLoading && _videos.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _videos.isEmpty
                      ? _buildVideosEmptyState(isSmallScreen)
                      : _buildVideosListView(isSmallScreen, isMediumScreen),
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
          'Upload and manage videos for this course. Supported formats: MP4, MOV, AVI. Maximum file size: 500MB.',
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            color: AppTheme.greyColor,
          ),
        ),
      ],
    );
  }

  Widget _buildUploadSection(bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.upload,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ready to upload?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.blackColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select a video file from your device to upload',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.greyColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isSmallScreen)
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _pickAndUploadVideo,
                  icon: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.cloud_upload),
                  label: Text(_isLoading ? 'Uploading...' : 'Upload Video'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            ],
          ),
          if (isSmallScreen) ...[
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _pickAndUploadVideo,
                icon: _isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.cloud_upload),
                label: Text(_isLoading ? 'Uploading...' : 'Upload Video'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
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



  Widget _buildVideoCard(Video video, bool isSmallScreen, bool isMediumScreen) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: isSmallScreen ? 45 : 50,
              height: isSmallScreen ? 45 : 50,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.play_circle_fill,
                color: AppTheme.primaryGreen,
                size: isSmallScreen ? 25 : 30,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 16 : 18,
                    ),
                  ),
                  const SizedBox(height: 5),
                  if (video.description != null && video.description!.isNotEmpty)
                    Text(
                      video.description!,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 13 : 14,
                        color: AppTheme.greyColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildVideoInfoChip(
                        Icons.access_time,
                        '${video.duration} mins',
                        AppTheme.primaryGreen,
                        isSmallScreen,
                      ),
                      const SizedBox(width: 10),
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
            ),
            if (isSmallScreen)
              _buildCompactVideoActions(video)
            else
              _buildFullVideoActions(video),
          ],
        ),
      ),
    );
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
          onPressed: () {
            // TODO: Implement video preview
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Video preview coming soon')),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.edit, size: 20),
          tooltip: 'Edit Video Details',
          onPressed: () {
            // TODO: Implement video editing
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Edit video details coming soon')),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
          tooltip: 'Delete Video',
          onPressed: () => _deleteVideo(video.id),
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Video preview coming soon')),
            );
            break;
          case 'edit':
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Edit video details coming soon')),
            );
            break;
          case 'delete':
            _deleteVideo(video.id);
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
              Text('Preview Video'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 20),
              SizedBox(width: 10),
              Text('Edit Details'),
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
              Text('Delete Video', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  void _showVideoGuidelines() {
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
                    'Video Upload Guidelines',
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
                'Recommended Specifications:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _buildGuidelineItem('Format', 'MP4, MOV, AVI (MP4 recommended)'),
              _buildGuidelineItem('Resolution', '1920x1080 (Full HD) or higher'),
              _buildGuidelineItem('Aspect Ratio', '16:9 recommended'),
              _buildGuidelineItem('Bitrate', '5-10 Mbps for HD quality'),
              _buildGuidelineItem('Duration', 'Maximum 30 minutes per video'),
              _buildGuidelineItem('File Size', 'Maximum 500MB per file'),
              const SizedBox(height: 20),
              const Text(
                'Best Practices:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _buildGuidelineItem('Audio Quality', 'Clear audio, minimum 44.1kHz sample rate'),
              _buildGuidelineItem('Lighting', 'Ensure good lighting for clear visuals'),
              _buildGuidelineItem('Content', 'Break long content into multiple shorter videos'),
              _buildGuidelineItem('Naming', 'Use descriptive, SEO-friendly titles'),
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
              color: AppTheme.primaryGreen,
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildVideosEmptyState(bool isSmallScreen) {
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
            'No videos uploaded yet',
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.blackColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Upload your first video to get started. Students will be able to access these videos once enrolled in the course.',
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

  Widget _buildVideosListView(bool isSmallScreen, bool isMediumScreen) {
    return RefreshIndicator(
      onRefresh: _loadVideos,
      child: ListView.builder(
        itemCount: _videos.length,
        itemBuilder: (context, index) {
          final video = _videos[index];
          return _buildVideoCard(video, isSmallScreen, isMediumScreen);
        },
      ),
    );
  }

  @override
  void dispose() {
    _videoService.dispose();
    super.dispose();
  }
}