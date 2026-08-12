import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/admin_recording.dart';
import '../../services/api/admin_recordings_service.dart';

final adminRecordingsServiceProvider = Provider<AdminRecordingsService>((ref) {
  final service = AdminRecordingsService();
  ref.onDispose(service.dispose);
  return service;
});

/// Filters for the admin recordings library.
class RecordingQuery {
  /// all | live | study
  final String kind;
  final String search;
  final String? courseId;

  const RecordingQuery({
    this.kind = 'all',
    this.search = '',
    this.courseId,
  });

  RecordingQuery copyWith({String? kind, String? search, String? courseId}) =>
      RecordingQuery(
        kind: kind ?? this.kind,
        search: search ?? this.search,
        courseId: courseId ?? this.courseId,
      );

  @override
  bool operator ==(Object other) =>
      other is RecordingQuery &&
      other.kind == kind &&
      other.search == search &&
      other.courseId == courseId;

  @override
  int get hashCode => Object.hash(kind, search, courseId);
}

final adminRecordingsProvider =
    FutureProvider.family<AdminRecordingPage, RecordingQuery>((ref, query) async {
  return ref.watch(adminRecordingsServiceProvider).list(
        kind: query.kind,
        courseId: query.courseId,
        search: query.search,
      );
});
