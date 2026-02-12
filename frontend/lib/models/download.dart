enum DownloadStatus { pending, downloading, paused, completed, failed }

class Download {
  final String id;
  final String lessonId;
  final String fileName;
  final String localPath;
  final String? error;
  double downloadProgress;
  bool isDownloading;
  DownloadStatus status;

  Download({
    required this.id,
    required this.lessonId,
    required this.fileName,
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
      localPath: localPath ?? this.localPath,
      error: error ?? this.error,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      isDownloading: isDownloading ?? this.isDownloading,
      status: status ?? this.status,
    );
  }
}