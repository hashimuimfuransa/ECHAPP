enum DownloadStatus { pending, downloading, paused, completed, failed }
enum DownloadType { video, notes, material }

class Download {
  final String id;
  final String lessonId;
  final String fileName;
  final String originalTitle;
  final String localPath;
  final String url;
  final String? error;
  final DownloadType type;
  final String? lessonTitle;
  final String? sectionTitle;
  double downloadProgress;
  bool isDownloading;
  DownloadStatus status;

  Download({
    required this.id,
    required this.lessonId,
    required this.fileName,
    required this.originalTitle,
    required this.localPath,
    required this.url,
    this.error,
    required this.type,
    this.lessonTitle,
    this.sectionTitle,
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
    String? url,
    String? error,
    DownloadType? type,
    String? lessonTitle,
    String? sectionTitle,
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
      url: url ?? this.url,
      error: error ?? this.error,
      type: type ?? this.type,
      lessonTitle: lessonTitle ?? this.lessonTitle,
      sectionTitle: sectionTitle ?? this.sectionTitle,
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
      url: json['url'] as String? ?? '',
      error: json['error'] as String?,
      type: _downloadTypeFromString(json['type'] as String? ?? 'video'),
      lessonTitle: json['lessonTitle'] as String?,
      sectionTitle: json['sectionTitle'] as String?,
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
      'url': url,
      'error': error,
      'type': _downloadTypeToString(type),
      'lessonTitle': lessonTitle,
      'sectionTitle': sectionTitle,
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

  static DownloadType _downloadTypeFromString(String type) {
    switch (type) {
      case 'video':
        return DownloadType.video;
      case 'notes':
        return DownloadType.notes;
      case 'material':
        return DownloadType.material;
      default:
        return DownloadType.video;
    }
  }

  static String _downloadTypeToString(DownloadType type) {
    switch (type) {
      case DownloadType.video:
        return 'video';
      case DownloadType.notes:
        return 'notes';
      case DownloadType.material:
        return 'material';
    }
  }
}
