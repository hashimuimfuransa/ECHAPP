import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:excellencecoachinghub/models/download.dart';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class DownloadService extends ChangeNotifier {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(minutes: 60),
    sendTimeout: const Duration(seconds: 30),
  ));

  /// Get authorization header with Firebase ID token
  Future<Map<String, String>> _getAuthHeaders() async {
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        // Force refresh to ensure we have a valid token
        final token = await user.getIdToken(true);
        if (token != null) {
          return {
            'Authorization': 'Bearer $token',
          };
        }
      }
    } catch (e) {
      print('DownloadService: Error getting auth token: $e');
    }
    
    // Return empty headers when no valid token is available
    return {};
  }
  final Map<String, Download> _downloads = {}; // Key: lessonId
  final Map<String, CancelToken> _cancelTokens = {}; // Key: lessonId
  static const String _downloadsKey = 'downloaded_videos';

  // Initialize the service and load persisted downloads
  Future<void> init() async {
    print('Initializing download service...');
    _dio.interceptors.add(LogInterceptor(
      requestBody: false,
      responseBody: false,
      error: true,
      logPrint: (obj) => print('Dio: $obj'),
    ));
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
            final fileName = p.basenameWithoutExtension(file.path);
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
                url: '', // Unknown URL for scanned files
                type: DownloadType.video, // Default to video type for scanned files
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
          notifyListeners();
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
            // Reset isDownloading status on load
            _downloads[download.lessonId] = download.copyWith(
              isDownloading: false,
              status: download.status == DownloadStatus.downloading 
                  ? DownloadStatus.paused 
                  : download.status,
            );
          } else {
            // File doesn't exist anymore, remove from storage
            await _removeDownloadFromStorage(download.lessonId);
          }
        }
        notifyListeners();
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
      notifyListeners();
    } catch (e) {
      print('Error removing download from storage: $e');
    }
  }

  // Get app documents directory
  Future<String> _getAppDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  // Download video with progress tracking and pause/resume support
  Future<String> downloadVideo({
    required String url,
    required String fileName,
    required String originalTitle,
    required String lessonId,
    Function(double)? onProgress,
    Function()? onSuccess,
    Function(String)? onError,
  }) async {
    print('Starting download video in service');
    print('URL: $url');
    print('Filename: $fileName');
    print('Lesson ID: $lessonId');
      
    int maxRetries = 3;
    int retryDelay = 2000; // 2 seconds

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        print('Download attempt ${attempt + 1} for lesson: $lessonId');
        
        final directory = await _getAppDirectory();
        print('Download directory: $directory (Attempt ${attempt + 1})');
        final filePath = p.join(directory, "$fileName.mp4");
        print('File path: $filePath');
    
        // Check if file already exists and is complete
        final file = File(filePath);
        if (await file.exists()) {
          final download = _downloads[lessonId];
          if (download != null && download.status == DownloadStatus.completed) {
            print('File already exists and is complete');
            onProgress?.call(1.0);
            onSuccess?.call();
            return filePath;
          }
        }

        // Check for partial download
        int downloadedBytes = 0;
        if (await file.exists()) {
          downloadedBytes = await file.length();
        }

        // Create/Update download record
        final download = Download(
          id: lessonId,
          lessonId: lessonId,
          fileName: fileName,
          originalTitle: originalTitle,
          localPath: filePath,
          url: url,
          type: DownloadType.video, // Default to video type
          downloadProgress: _downloads[lessonId]?.downloadProgress ?? (downloadedBytes > 0 ? -1.0 : 0.0), // -1 means unknown if we have file but no total
          isDownloading: true,
          status: DownloadStatus.downloading,
        );
        _downloads[lessonId] = download;
        notifyListeners();
        await _saveDownloadsToStorage();

        final cancelToken = CancelToken();
        _cancelTokens[lessonId] = cancelToken;

        print('Starting actual download with Dio. Range: bytes=$downloadedBytes-');
        
        try {
          // Get auth headers for the request
          final authHeaders = await _getAuthHeaders();
          
          final response = await _dio.get<ResponseBody>(
            url,
            options: Options(
              responseType: ResponseType.stream,
              followRedirects: true,
              validateStatus: (status) => status == 200 || status == 206,
              headers: {
                ...authHeaders,
                if (downloadedBytes > 0) 'range': 'bytes=$downloadedBytes-',
              },
            ),
            cancelToken: cancelToken,
          );

          final File file = File(filePath);
          
          // If we requested a range but got 200 (Full Content), it means the server 
          // doesn't support Range or the file changed. We must restart from 0.
          bool isResuming = downloadedBytes > 0 && response.statusCode == 206;
          int currentReceived = isResuming ? downloadedBytes : 0;
          
          final IOSink raf = file.openWrite(mode: isResuming ? FileMode.append : FileMode.write);

          try {
            int? contentLength = int.tryParse(response.headers.value('content-length') ?? '-1');
            int actualTotal = (contentLength != null && contentLength != -1) ? (contentLength + currentReceived) : -1;

            await response.data!.stream.listen(
              (List<int> chunk) {
                raf.add(chunk);
                currentReceived += chunk.length;

                if (actualTotal != -1) {
                  double progress = currentReceived / actualTotal;
                  
                  // Update progress more frequently for smoother UI (every 1% instead of 2%)
                  if (progress > (download.downloadProgress + 0.01) || progress >= 1.0 || progress < download.downloadProgress) {
                    download.downloadProgress = progress;
                    _downloads[lessonId] = download.copyWith(downloadProgress: progress);
                    onProgress?.call(progress);
                    notifyListeners();
                    
                    // Save to storage on major milestones (every 5%) or completion for better performance
                    if (progress >= 1.0 || (progress * 20).floor() > ((download.downloadProgress - 0.05) * 20).floor()) {
                      _saveDownloadsToStorage(); 
                    }
                  }
                } else {
                  // Indeterminate progress - use a pulsing pattern to show activity
                  if (download.downloadProgress != -1.0) {
                    download.downloadProgress = -1.0;
                    _downloads[lessonId] = download.copyWith(downloadProgress: -1.0);
                    onProgress?.call(-1.0);
                    notifyListeners();
                  }
                }
              },
              onError: (e) {
                if (CancelToken.isCancel(e)) return;
                throw e;
              },
              cancelOnError: true,
            ).asFuture();
          } finally {
            await raf.close();
          }
      
          print('Download completed successfully');
          _downloads[lessonId] = download.copyWith(
            isDownloading: false,
            downloadProgress: 1.0,
            status: DownloadStatus.completed,
          );
          _cancelTokens.remove(lessonId);
          notifyListeners();
          await _saveDownloadsToStorage();
          onSuccess?.call();

          return filePath;
        } on DioException catch (e) {
          if (CancelToken.isCancel(e)) {
            print('Download paused: $lessonId');
            _downloads[lessonId] = download.copyWith(
              isDownloading: false,
              status: DownloadStatus.paused,
            );
            notifyListeners();
            await _saveDownloadsToStorage();
            return filePath;
          }
          
          // Handle specific HTTP errors
          String errorMessage = 'Download failed';
          if (e.response?.statusCode == 403) {
            errorMessage = 'Access denied. Please check your subscription or login again.';
          } else if (e.response?.statusCode == 401) {
            errorMessage = 'Authentication failed. Please log in again.';
          } else if (e.response?.statusCode == 404) {
            errorMessage = 'Video not found. It may have been removed.';
          } else if (e.type == DioExceptionType.connectionTimeout) {
            errorMessage = 'Connection timeout. Please check your internet connection.';
          } else if (e.type == DioExceptionType.receiveTimeout) {
            errorMessage = 'Download timeout. Please try again.';
          } else if (e.type == DioExceptionType.connectionError) {
            errorMessage = 'Network error. Please check your internet connection.';
          }
          
          print('Download DioException: ${e.type}, Status: ${e.response?.statusCode}, Message: $errorMessage');
          throw Exception(errorMessage);
        }
      } catch (e) {
        print('Download attempt ${attempt + 1} failed: $e');
        
        // Don't retry if it was cancelled
        if (e is DioException && CancelToken.isCancel(e)) {
          rethrow;
        }

        if (attempt < maxRetries) {
          print('Retrying in ${retryDelay / 1000} seconds...');
          await Future.delayed(Duration(milliseconds: retryDelay));
          retryDelay *= 2; // Exponential backoff
          continue;
        }

        print('All download attempts failed.');
        if (_downloads.containsKey(lessonId)) {
          _downloads[lessonId] = _downloads[lessonId]!.copyWith(
            isDownloading: false,
            status: DownloadStatus.failed,
            error: e.toString(),
          );
          notifyListeners();
          await _saveDownloadsToStorage();
        }
        onError?.call(e.toString());
        rethrow;
      }
    }
    return ''; // Should never reach here due to rethrows and returns inside loop
  }

  // Pause a download
  void pauseDownload(String lessonId) {
    if (_cancelTokens.containsKey(lessonId)) {
      _cancelTokens[lessonId]!.cancel();
      _cancelTokens.remove(lessonId);
    }
  }

  // Resume a download
  Future<void> resumeDownload(String lessonId, {String? newUrl}) async {
    final download = _downloads[lessonId];
    if (download != null && (download.status == DownloadStatus.paused || download.status == DownloadStatus.failed)) {
      await downloadVideo(
        url: newUrl ?? download.url,
        fileName: download.fileName,
        originalTitle: download.originalTitle,
        lessonId: download.lessonId,
      );
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
      final filePath = p.join(directory, "$fileName.mp4");
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  // Get local file path for a downloaded video ONLY if it's fully completed
  Future<String?> getLocalVideoPathById(String lessonId) async {
    try {
      final download = _downloads[lessonId];
      if (download != null && download.status == DownloadStatus.completed) {
        final file = File(download.localPath);
        if (await file.exists()) {
          return download.localPath;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get local file path for a downloaded video by filename (legacy compatibility)
  Future<String?> getLocalVideoPath(String fileName) async {
    try {
      // Find download record by filename
      final download = _downloads.values.firstWhere(
        (d) => d.fileName == fileName && d.status == DownloadStatus.completed,
        orElse: () => throw Exception('Not found'),
      );
      
      final file = File(download.localPath);
      if (await file.exists()) {
        return download.localPath;
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
      pauseDownload(lessonId); // Ensure it's not downloading
      
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

  // Download notes or materials with organization metadata
  Future<String> downloadNotesOrMaterial({
    required String url,
    required String title,
    required String lessonId,
    required DownloadType type,
    String? lessonTitle,
    String? sectionTitle,
    Function(double)? onProgress,
    Function()? onSuccess,
    Function(String)? onError,
  }) async {
    try {
      // Generate a unique ID for this download
      final downloadId = '${type.name}_$lessonId';
      
      // Check if already downloaded
      if (_downloads.containsKey(downloadId) && _downloads[downloadId]!.status == DownloadStatus.completed) {
        onProgress?.call(1.0);
        onSuccess?.call();
        return _downloads[downloadId]!.localPath;
      }

      // Determine file extension from URL
      String fileExtension = '';
      if (url.toLowerCase().endsWith('.pdf')) {
        fileExtension = '.pdf';
      } else if (url.toLowerCase().endsWith('.doc') || url.toLowerCase().endsWith('.docx')) {
        fileExtension = '.docx';
      } else if (url.toLowerCase().endsWith('.txt')) {
        fileExtension = '.txt';
      } else if (url.toLowerCase().endsWith('.md')) {
        fileExtension = '.md';
      } else {
        fileExtension = '.pdf'; // Default to PDF
      }

      final directory = await _getAppDirectory();
      final fileName = '${type.name}_$lessonId$fileExtension';
      final filePath = p.join(directory, fileName);

      // Create download record
      final download = Download(
        id: downloadId,
        lessonId: lessonId,
        fileName: fileName,
        originalTitle: title,
        localPath: filePath,
        url: url,
        type: type,
        lessonTitle: lessonTitle,
        sectionTitle: sectionTitle,
        downloadProgress: 0.0,
        isDownloading: true,
        status: DownloadStatus.downloading,
      );
      
      _downloads[downloadId] = download;
      notifyListeners();
      await _saveDownloadsToStorage();

      // Get auth headers for request
      final authHeaders = await _getAuthHeaders();
      
      final response = await _dio.get<ResponseBody>(
        url,
        options: Options(
          responseType: ResponseType.stream,
          followRedirects: true,
          validateStatus: (status) => status == 200 || status == 206,
          headers: authHeaders,
        ),
      );

      final File file = File(filePath);
      final IOSink raf = file.openWrite();
      
      try {
        int currentReceived = 0;
        int? contentLength = int.tryParse(response.headers.value('content-length') ?? '-1');

        await response.data!.stream.listen(
          (List<int> chunk) {
            raf.add(chunk);
            currentReceived += chunk.length;

            if (contentLength != null && contentLength != -1) {
              double progress = currentReceived / contentLength;
              
              // Update progress more frequently for smoother UI
              if (progress > (download.downloadProgress + 0.01) || progress >= 1.0) {
                download.downloadProgress = progress;
                _downloads[downloadId] = download.copyWith(downloadProgress: progress);
                onProgress?.call(progress);
                notifyListeners();
                
                // Save to storage on major milestones for better performance
                if (progress >= 1.0 || (progress * 20).floor() > ((download.downloadProgress - 0.05) * 20).floor()) {
                  _saveDownloadsToStorage(); 
                }
              }
            } else {
              // Indeterminate progress
              if (download.downloadProgress != -1.0) {
                download.downloadProgress = -1.0;
                _downloads[downloadId] = download.copyWith(downloadProgress: -1.0);
                onProgress?.call(-1.0);
                notifyListeners();
              }
            }
          },
          onError: (e) {
            throw e;
          },
          cancelOnError: true,
        ).asFuture();
      } finally {
        await raf.close();
      }
      
      // Mark download as completed
      _downloads[downloadId] = download.copyWith(
        isDownloading: false,
        downloadProgress: 1.0,
        status: DownloadStatus.completed,
      );
      notifyListeners();
      await _saveDownloadsToStorage();
      onSuccess?.call();

      return filePath;
    } on DioException catch (e) {
      final downloadId = '${type.name}_$lessonId';
      
      // Handle specific HTTP errors
      String errorMessage = 'Download failed';
      if (e.response?.statusCode == 403) {
        errorMessage = 'Access denied. Please check your subscription or login again.';
      } else if (e.response?.statusCode == 401) {
        errorMessage = 'Authentication failed. Please log in again.';
      } else if (e.response?.statusCode == 404) {
        errorMessage = 'File not found. It may have been removed.';
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout. Please check your internet connection.';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Download timeout. Please try again.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'Network error. Please check your internet connection.';
      }
      
      print('Download DioException for notes/materials: ${e.type}, Status: ${e.response?.statusCode}, Message: $errorMessage');
      
      if (_downloads.containsKey(downloadId)) {
        _downloads[downloadId] = _downloads[downloadId]!.copyWith(
          isDownloading: false,
          status: DownloadStatus.failed,
          error: errorMessage,
        );
        notifyListeners();
        await _saveDownloadsToStorage();
      }
      
      onError?.call(errorMessage);
      rethrow;
    } catch (e) {
      final downloadId = '${type.name}_$lessonId';
      print('Download failed for notes/materials: $e');
      
      if (_downloads.containsKey(downloadId)) {
        _downloads[downloadId] = _downloads[downloadId]!.copyWith(
          isDownloading: false,
          status: DownloadStatus.failed,
          error: e.toString(),
        );
        notifyListeners();
        await _saveDownloadsToStorage();
      }
      
      onError?.call(e.toString());
      rethrow;
    }
  }

  // Get downloads by type
  List<Download> getDownloadsByType(DownloadType type) {
    return _downloads.values.where((download) => download.type == type).toList();
  }

  // Get downloads by lesson
  List<Download> getDownloadsByLesson(String lessonId) {
    return _downloads.values.where((download) => download.lessonId == lessonId).toList();
  }

  // Check if notes/materials are downloaded
  Future<bool> isContentDownloaded(String lessonId, DownloadType type) async {
    final downloadId = '${type.name}_$lessonId';
    final download = _downloads[downloadId];
    return download?.status == DownloadStatus.completed;
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
