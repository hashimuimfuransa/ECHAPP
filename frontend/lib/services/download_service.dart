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
    print('Initializing download service...');
    await _loadDownloadsFromStorage();
    print('Loaded ${_downloads.length} downloads from storage');
    await _scanForExistingDownloads();
    print('Scan complete. Total downloads now: ${_downloads.length}');
  }

  // Scan for existing downloaded files and create records for them
  Future<void> _scanForExistingDownloads() async {
    try {
      print('Scanning for existing downloads...');
      final directory = await _getAppDirectory();
      final dir = Directory(directory);
      
      if (await dir.exists()) {
        final files = dir.listSync();
        print('Found ${files.length} files in download directory');
        
        for (final file in files) {
          if (file is File && file.path.endsWith('.mp4')) {
            final fileName = file.path.split('/').last.replaceAll('.mp4', '');
            print('Processing file: $fileName');
            final lessonId = _extractLessonIdFromFilename(fileName);
            print('Extracted lesson ID: $lessonId');
            
            if (lessonId != null && !_downloads.containsKey(lessonId)) {
              print('Found existing download: $fileName for lesson: $lessonId');
              // Create download record for existing file
              final download = Download(
                id: lessonId,
                lessonId: lessonId,
                fileName: fileName,
                originalTitle: fileName, // We don't have the original title
                localPath: file.path,
                downloadProgress: 1.0,
                isDownloading: false,
                status: DownloadStatus.completed,
              );
              _downloads[lessonId] = download;
            }
          }
        }
        
        if (_downloads.isNotEmpty) {
          await _saveDownloadsToStorage();
          print('Created records for ${_downloads.length} existing downloads');
        }
      }
    } catch (e) {
      print('Error scanning for existing downloads: $e');
    }
  }

  // Extract lesson ID from filename (simple heuristic)
  String? _extractLessonIdFromFilename(String filename) {
    print('Extracting lesson ID from filename: $filename');
    // If filename looks like a lesson ID (hex string), use it
    if (RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(filename)) {
      print('Found lesson ID pattern: $filename');
      return filename;
    }
    // If filename starts with "lesson_", extract the ID part
    if (filename.startsWith('lesson_')) {
      final idPart = filename.substring(7); // Remove "lesson_" prefix
      if (RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(idPart)) {
        print('Found lesson ID in lesson_ prefix: $idPart');
        return idPart;
      }
    }
    // For other filenames (like sanitized titles), we can't extract lesson ID
    // In this case, we might need a different approach - perhaps maintain a mapping
    print('Could not extract lesson ID from filename: $filename');
    return null;
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
    print('Starting download video in service');
    print('URL: $url');
    print('Filename: $fileName');
    print('Lesson ID: $lessonId');
      
    try {
      final directory = await _getAppDirectory();
      print('Download directory: $directory');
      final filePath = "$directory/$fileName.mp4";
      print('File path: $filePath');
  
      // Check if file already exists
      final file = File(filePath);
      print('Checking if file exists: ${await file.exists()}');
      if (await file.exists()) {
        print('File already exists, creating/updating download record');
        // File exists, create/update download record
        final download = Download(
          id: lessonId,
          lessonId: lessonId,
          fileName: fileName,
          originalTitle: originalTitle,
          localPath: filePath,
          downloadProgress: 1.0,
          isDownloading: false,
          status: DownloadStatus.completed,
        );
        _downloads[lessonId] = download;
        await _saveDownloadsToStorage();
        // Simulate progress callbacks for UI consistency
        onProgress(0.0);
        await Future.delayed(const Duration(milliseconds: 100));
        onProgress(0.5);
        await Future.delayed(const Duration(milliseconds: 100));
        onProgress(1.0);
        onSuccess?.call();
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
      print('Created download record');
      await _saveDownloadsToStorage(); // Save to persistent storage
      print('Saved download record to storage');
  
      print('Starting actual download with Dio');
      await _dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) async {
          print('Dio progress callback called: received=$received, total=$total');
          if (total != -1) {
            double progress = received / total;
            print('Download service progress: ${(progress * 100).round()}%');
            download.downloadProgress = progress;
            onProgress(progress);
              
            // Update download record with current progress
            _downloads[lessonId] = download.copyWith(
              downloadProgress: progress,
            );
            // Save progress to persistent storage
            await _saveDownloadsToStorage();
          }
        },
      );
        
      print('Download completed successfully');
      // Update download status
      _downloads[lessonId] = download.copyWith(
        isDownloading: false,
        status: DownloadStatus.completed,
      );
      await _saveDownloadsToStorage(); // Save to persistent storage
      onSuccess?.call();
  
      return filePath;
    } catch (e) {
      print('Download failed with error: $e');
      _downloads[lessonId] = _downloads[lessonId]!.copyWith(
        isDownloading: false,
        status: DownloadStatus.failed,
        error: e.toString(),
      );
      await _saveDownloadsToStorage(); // Save error state to persistent storage
      onError?.call(e.toString());
      rethrow;
    }
  }

  // Check if video is downloaded locally by lesson ID
  Future<bool> isVideoDownloadedByLessonId(String lessonId) async {
    try {
      final download = _downloads[lessonId];
      if (download != null) {
        return download.status == DownloadStatus.completed;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  // Check if video is downloaded locally by filename
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