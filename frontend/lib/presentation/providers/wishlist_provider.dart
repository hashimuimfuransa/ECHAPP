import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellence_coaching_hub/models/course.dart';
import 'package:excellence_coaching_hub/services/wishlist_service.dart';

final wishlistServiceProvider = Provider<WishlistService>((ref) {
  return WishlistService();
});

final wishlistProvider = FutureProvider<List<Course>>((ref) async {
  final service = ref.watch(wishlistServiceProvider);
  return await service.getWishlistCourses();
});

final isCourseInWishlistProvider = FutureProvider.family<bool, String>((ref, courseId) async {
  final service = ref.watch(wishlistServiceProvider);
  return await service.isCourseInWishlist(courseId);
});

class WishlistNotifier extends StateNotifier<AsyncValue<List<Course>>> {
  final WishlistService _service;
  
  WishlistNotifier(this._service) : super(const AsyncValue.loading()) {
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    try {
      state = const AsyncValue.loading();
      final courses = await _service.getWishlistCourses();
      state = AsyncValue.data(courses);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addCourse(String courseId, Course course) async {
    try {
      final result = await _service.addCourseToWishlist(courseId);
      if (result) {
        // Refresh the wishlist
        await _loadWishlist();
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> removeCourse(String courseId) async {
    try {
      final result = await _service.removeCourseFromWishlist(courseId);
      if (result) {
        // Refresh the wishlist
        await _loadWishlist();
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> toggleCourse(String courseId, Course course) async {
    try {
      final isInWishlist = await _service.isCourseInWishlist(courseId);
      if (isInWishlist) {
        await removeCourse(courseId);
      } else {
        await addCourse(courseId, course);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final wishlistNotifierProvider = StateNotifierProvider<WishlistNotifier, AsyncValue<List<Course>>>((ref) {
  final service = ref.watch(wishlistServiceProvider);
  return WishlistNotifier(service);
});