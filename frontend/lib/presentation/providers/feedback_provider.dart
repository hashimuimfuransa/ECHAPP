import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api/feedback_service.dart';
import '../../models/feedback.dart';

final feedbackServiceProvider = Provider<FeedbackService>((ref) {
  final service = FeedbackService();
  ref.onDispose(() => service.dispose());
  return service;
});

final allFeedbackProvider = FutureProvider<List<FeedbackModel>>((ref) async {
  final service = ref.watch(feedbackServiceProvider);
  return await service.getAllFeedback();
});

class FeedbackNotifier extends StateNotifier<AsyncValue<void>> {
  final FeedbackService _service;
  final Ref _ref;

  FeedbackNotifier(this._service, this._ref) : super(const AsyncValue.data(null));

  Future<bool> submitFeedback(String content) async {
    state = const AsyncValue.loading();
    try {
      final success = await _service.submitFeedback(content);
      state = const AsyncValue.data(null);
      return success;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> markAsRead(String feedbackId) async {
    try {
      final success = await _service.markAsRead(feedbackId);
      if (success) {
        _ref.invalidate(allFeedbackProvider);
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteFeedback(String feedbackId) async {
    try {
      final success = await _service.deleteFeedback(feedbackId);
      if (success) {
        _ref.invalidate(allFeedbackProvider);
      }
      return success;
    } catch (e) {
      return false;
    }
  }
}

final feedbackNotifierProvider = StateNotifierProvider<FeedbackNotifier, AsyncValue<void>>((ref) {
  final service = ref.watch(feedbackServiceProvider);
  return FeedbackNotifier(service, ref);
});
