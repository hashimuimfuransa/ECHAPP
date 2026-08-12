import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../models/admin_recording.dart';
import '../infrastructure/api_client.dart';

/// Admin-only recordings library (`/api/admin/recordings`).
class AdminRecordingsService {
  final ApiClient _apiClient;

  AdminRecordingsService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  String get _base => '${ApiConfig.admin}/recordings';

  /// Typed so the `validateStatus` extension resolves — a `dynamic` receiver
  /// compiles and then fails at runtime.
  Map<String, dynamic> _unwrap(http.Response response) {
    response.validateStatus();
    final raw = response.body.trim();
    if (raw.isEmpty) return <String, dynamic>{};

    final Object? body;
    try {
      body = jsonDecode(raw);
    } catch (_) {
      throw ApiException('The server returned an unreadable response');
    }
    if (body is! Map<String, dynamic>) {
      throw ApiException('Unexpected response from the server');
    }
    if (body['success'] != true) {
      throw ApiException(body['message']?.toString() ?? 'Request failed');
    }
    final data = body['data'];
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  Future<AdminRecordingPage> list({
    String kind = 'all',
    String? courseId,
    String search = '',
    int page = 1,
    int limit = 30,
  }) async {
    final response = await _apiClient.get(
      _base,
      queryParams: {
        'kind': kind,
        if (courseId != null && courseId.isNotEmpty) 'courseId': courseId,
        if (search.isNotEmpty) 'search': search,
        'page': page,
        'limit': limit,
      },
    );
    return AdminRecordingPage.fromJson(_unwrap(response));
  }

  /// Re-asks BBB about one recording — for when processing finished after the
  /// last sweep, or the video format was installed later than the session.
  Future<bool> refresh(String kind, String sessionId) async {
    final data = _unwrap(await _apiClient.post(
      '$_base/$kind/$sessionId/refresh',
      body: const <String, dynamic>{},
    ));
    return data['processing'] != true;
  }

  Future<void> setPublished(String kind, String sessionId, bool isPublished) async {
    _unwrap(await _apiClient.patch(
      '$_base/$kind/$sessionId/published',
      body: {'isPublished': isPublished},
    ));
  }

  void dispose() => _apiClient.dispose();
}
