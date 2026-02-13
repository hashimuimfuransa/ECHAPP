import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:excellence_coaching_hub/models/download.dart';
import 'dart:convert';

class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  final Dio _dio = Dio();
  final Map<String, Download> _downloads = {}; // Key: lessonId
  static const String _downloadsKey = 'downloaded_videos';

  // Initialize the service and load persisted downloads
  Future<void> init() async {
    await _loadDownloadsFromStorage();
  }

  // Load downloads from shared preferences
  Future<void> _loadDownloadsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final downloadsJson = prefs.getString(_downloadsKey);
      
      if (downloadsJson != null) {
        final List<dynamic> downloadsList = json.decode(downloadsJson);
        for (final downloadJson in downloadsList) {
          final download = Download.fromJson(downloadJson);
          // Verify the file still exists before adding to memory
          final file = File(download.localPath);
          if (await file.exists()) {
            _downloads[download.lessonId] = download;
          } else {
            // File doesn't exist anymore, remove from storage
            await _removeDownloadFromStorage(download.lessonId);
          }
        }
      }
    } catch (e) {
      print('Error loading downloads from storage: $e');
      // Clear the downloads map if there's an error
      _downloads.clear();
    }
  }

  // Save downloads to shared preferences
  Future<void> _saveDownloadsToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final downloadsList = _downloads.values
          .map((download) => download.toJson())
          .toList();
      await prefs.setString(_downloadsKey, json.encode(downloadsList));
    } catch (e) {
      print('Error saving downloads to storage: $e');
    }
  }

  // Remove a specific download from storage
  Future<void> _removeDownloadFromStorage(String lessonId) async {
    try {
      _downloads.remove(lessonId);
      await _saveDownloadsToStorage();
    } catch (e) {
      print('Error removing download from storage: $e');
    }
  }

  // Get app documents directory
  Future<String> _getAppDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  // Download video with progress tracking
  Future<String> downloadVideo({
    required String url,
    required String fileName,
    required String originalTitle,
    required String lessonId,
    required Function(double) onProgress,
    Function()? onSuccess,
    Function(String)? onError,
  }) async {
    try {
      final directory = await _getAppDirectory();
      final filePath = "$directory/$fileName.mp4";

      // Check if file already exists
      final file = File(filePath);
      if (await file.exists()) {
        // Return existing file path if already downloaded
        // Update download record if it exists
        if (_downloads.containsKey(lessonId)) {
          _downloads[lessonId] = _downloads[lessonId]!.copyWith(
            status: DownloadStatus.completed,
            isDownloading: false,
            downloadProgress: 1.0,
          );
        }
        return filePath;
      }

      // Create download record
      final download = Download(
        id: lessonId,
        lessonId: lessonId,
        fileName: fileName,
        originalTitle: originalTitle,
        localPath: filePath,
        downloadProgress: 0.0,
        isDownloading: true,
        status: DownloadStatus.downloading,
      );
      _downloads[lessonId] = download;
      await _saveDownloadsToStorage(); // Save to persistent storage

      await _dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            double progress = received / total;
            download.downloadProgress = progress;
            onProgress(progress);
            
            // Update download record with current progress
            _downloads[lessonId] = download.copyWith(
              downloadProgress: progress,
            );
          }
        },
      );

      // Update download status
      _downloads[lessonId] = download.copyWith(
        isDownloading: false,
        status: DownloadStatus.completed,
      );
      await _saveDownloadsToStorage(); // Save to persistent storage
      onSuccess?.call();

      return filePath;
    } catch (e) {
      _downloads[lessonId] = _downloads[lessonId]!.copyWith(
        isDownloading: false,
        status: DownloadStatus.failed,
        error: e.toString(),
      );
      onError?.call(e.toString());
      rethrow;
    }
  }

  // Check if video is downloaded locally
  Future<bool> isVideoDownloaded(String fileName) async {
    try {
      final directory = await _getAppDirectory();
      final filePath = "$directory/$fileName.mp4";
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  // Get local file path for a downloaded video
  Future<String?> getLocalVideoPath(String fileName) async {
    try {
      final directory = await _getAppDirectory();
      final filePath = "$directory/$fileName.mp4";
      final file = File(filePath);
      if (await file.exists()) {
        return filePath;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get download status for a specific lesson
  Download? getDownloadStatus(String lessonId) {
    return _downloads[lessonId];
  }

  // Get all downloads
  List<Download> getAllDownloads() {
    return _downloads.values.toList();
  }

  // Delete a downloaded video
  Future<bool> deleteDownload(String lessonId) async {
    try {
      final download = _downloads[lessonId];
      if (download != null) {
        final file = File(download.localPath);
        
        if (await file.exists()) {
          await file.delete();
        }
        
        // Remove from downloads map and storage
        await _removeDownloadFromStorage(lessonId);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Get total storage used by downloads
  Future<int> getTotalDownloadedSize() async {
    int totalSize = 0;
    
    for (final download in _downloads.values) {
      final file = File(download.localPath);
      if (await file.exists()) {
        totalSize += await file.length();
      }
    }
    
    return totalSize;
  }
}