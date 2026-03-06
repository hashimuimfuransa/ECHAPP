import 'package:shared_preferences/shared_preferences.dart';

class VideoProgressService {
  static const String _prefix = 'video_progress_';

  Future<void> saveProgress(String videoId, Duration position) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_prefix$videoId', position.inSeconds);
  }

  Future<Duration> getProgress(String videoId) async {
    final prefs = await SharedPreferences.getInstance();
    final seconds = prefs.getInt('$_prefix$videoId') ?? 0;
    return Duration(seconds: seconds);
  }

  Future<void> clearProgress(String videoId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$videoId');
  }
}

final videoProgressService = VideoProgressService();
