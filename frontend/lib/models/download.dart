enum DownloadStatus { pending, downloading, paused, completed, failed }

class Download {
  final String id;
  final String lessonId;
  final String fileName;
  final String originalTitle;
  final String localPath;
  final String? error;
  double downloadProgress;
  bool isDownloading;
  DownloadStatus status;

  Download({
    required this.id,
    required this.lessonId,
    required this.fileName,
    required this.originalTitle,
    required this.localPath,
    this.error,
    required this.downloadProgress,
    required this.isDownloading,
    required this.status,
  });

  Download copyWith({
    String? id,
    String? lessonId,
    String? fileName,
    String? originalTitle,
    String? localPath,
    String? error,
    double? downloadProgress,
    bool? isDownloading,
    DownloadStatus? status,
  }) {
    return Download(
      id: id ?? this.id,
      lessonId: lessonId ?? this.lessonId,
      fileName: fileName ?? this.fileName,
      originalTitle: originalTitle ?? this.originalTitle,
      localPath: localPath ?? this.localPath,
      error: error ?? this.error,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      isDownloading: isDownloading ?? this.isDownloading,
      status: status ?? this.status,
    );
  }

  factory Download.fromJson(Map<String, dynamic> json) {
    return Download(
      id: json['id'] as String,
      lessonId: json['lessonId'] as String,
      fileName: json['fileName'] as String,
      originalTitle: json['originalTitle'] as String,
      localPath: json['localPath'] as String,
      error: json['error'] as String?,
      downloadProgress: (json['downloadProgress'] as num).toDouble(),
      isDownloading: json['isDownloading'] as bool,
      status: _downloadStatusFromString(json['status'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lessonId': lessonId,
      'fileName': fileName,
      'originalTitle': originalTitle,
      'localPath': localPath,
      'error': error,
      'downloadProgress': downloadProgress,
      'isDownloading': isDownloading,
      'status': _downloadStatusToString(status),
    };
  }

  static DownloadStatus _downloadStatusFromString(String status) {
    switch (status) {
      case 'pending':
        return DownloadStatus.pending;
      case 'downloading':
        return DownloadStatus.downloading;
      case 'paused':
        return DownloadStatus.paused;
      case 'completed':
        return DownloadStatus.completed;
      case 'failed':
        return DownloadStatus.failed;
      default:
        return DownloadStatus.pending;
    }
  }

  static String _downloadStatusToString(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.pending:
        return 'pending';
      case DownloadStatus.downloading:
        return 'downloading';
      case DownloadStatus.paused:
        return 'paused';
      case DownloadStatus.completed:
        return 'completed';
      case DownloadStatus.failed:
        return 'failed';
    }
  }
}