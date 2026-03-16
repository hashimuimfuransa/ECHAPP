import '../../config/api_config.dart';
import '../../models/feedback.dart';
import '../infrastructure/api_client.dart';

class FeedbackService {
  final ApiClient _apiClient;

  FeedbackService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Submit feedback (Student)
  Future<bool> submitFeedback(String content) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.feedback}/submit',
        body: {'content': content},
      );

      response.validateStatus();
      final apiResponse = response.toApiResponse((json) => json);
      return apiResponse.success;
    } catch (e) {
      throw ApiException('Failed to submit feedback: $e');
    }
  }

  /// Get all feedback (Admin)
  Future<List<FeedbackModel>> getAllFeedback() async {
    try {
      final response = await _apiClient.get('${ApiConfig.feedback}/all');
      response.validateStatus();
      
      final apiResponse = response.toApiResponseList<FeedbackModel>((json) => FeedbackModel.fromJson(json));
      
      return apiResponse.data ?? [];
    } catch (e) {
      throw ApiException('Failed to fetch feedback: $e');
    }
  }

  /// Mark feedback as read (Admin)
  Future<bool> markAsRead(String feedbackId) async {
    try {
      final response = await _apiClient.patch('${ApiConfig.feedback}/$feedbackId/read');
      response.validateStatus();
      
      final apiResponse = response.toApiResponse((json) => json);
      return apiResponse.success;
    } catch (e) {
      throw ApiException('Failed to mark feedback as read: $e');
    }
  }

  /// Delete feedback (Admin)
  Future<bool> deleteFeedback(String feedbackId) async {
    try {
      final response = await _apiClient.delete('${ApiConfig.feedback}/$feedbackId');
      response.validateStatus();
      
      final apiResponse = response.toApiResponse((json) => json);
      return apiResponse.success;
    } catch (e) {
      throw ApiException('Failed to delete feedback: $e');
    }
  }

  void dispose() {
    _apiClient.dispose();
  }
}
