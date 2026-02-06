import 'package:image_picker/image_picker.dart';
import '../../models/video.dart';
import '../../services/api/video_service.dart';

class VideoRepository {
  final VideoService _videoService;

  VideoRepository({VideoService? videoService}) 
      : _videoService = videoService ?? VideoService();

  /// Get all videos
  Future<List<Video>> getAllVideos() async {
    try {
      return await _videoService.getAllVideos();
    } catch (e) {
      print('Video Repository: Error getting all videos: $e');
      // Return empty list instead of crashing
      return [];
    }
  }

  /// Get videos by course
  Future<List<Video>> getVideosByCourse(String courseId) async {
    try {
      return await _videoService.getVideosByCourse(courseId);
    } catch (e) {
      print('Video Repository: Error getting videos by course: $e');
      // Return empty list instead of crashing
      return [];
    }
  }

  /// Upload video
  Future<Video> uploadVideo({
    required XFile videoFile,
    required String courseId,
    String? sectionId,
    String? title,
    String? description,
    Function(double)? onProgress,
  }) async {
    return await _videoService.uploadVideo(
      videoFile: videoFile,
      courseId: courseId,
      sectionId: sectionId,
      title: title,
      description: description,
      onProgress: onProgress,
    );
  }

  /// Delete video
  Future<void> deleteVideo(String videoId) async {
    return await _videoService.deleteVideo(videoId);
  }
}