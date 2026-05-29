import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellencecoachinghub/models/course.dart';
import 'package:excellencecoachinghub/utils/course_navigation_utils.dart';
import 'package:excellencecoachinghub/utils/navigation_optimizer.dart';
import 'package:excellencecoachinghub/utils/navigation_performance_monitor.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';

/// Enhanced course navigation widget with immediate feedback and loading indicators
class EnhancedCourseNavigation extends ConsumerStatefulWidget {
  final Course course;
  final Widget child;
  final bool showRipple;
  final bool enableHapticFeedback;

  const EnhancedCourseNavigation({
    super.key,
    required this.course,
    required this.child,
    this.showRipple = true,
    this.enableHapticFeedback = true,
  });

  @override
  ConsumerState<EnhancedCourseNavigation> createState() => _EnhancedCourseNavigationState();
}

class _EnhancedCourseNavigationState extends ConsumerState<EnhancedCourseNavigation>
    with TickerProviderStateMixin {
  bool _isNavigating = false;
  bool _isPressed = false;
  late AnimationController _rippleController;
  late Animation<double> _rippleAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _rippleController.dispose();
    super.dispose();
  }

  Future<void> _handleCourseTap() async {
    if (_isNavigating || !mounted) return;

    // Immediate visual feedback
    if (mounted) {
      setState(() {
        _isPressed = true;
        _isNavigating = true;
      });
    }

    // Haptic feedback
    if (widget.enableHapticFeedback) {
      _triggerHapticFeedback();
    }

    // Start ripple animation
    if (widget.showRipple) {
      _rippleController.forward();
    }

    try {
      // Optimized navigation with preloading
      await _navigateWithOptimization();
    } catch (e) {
      // Handle navigation error
      if (mounted) {
        _showErrorSnackBar();
      }
    }
  }

  Future<void> _navigateWithOptimization() async {
    // Preload navigation state
    NavigationPerformanceMonitor.startNavigation('course_${widget.course.id}');

    // Don't show dialog overlay - use inline loading indicator instead
    // The inline indicator is already shown via _isNavigating state

    // Set a fallback timer to reset navigation state after 3 seconds
    _dismissTimer?.cancel();
    _dismissTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isNavigating = false;
          _isPressed = false;
        });
        _rippleController.reset();
      }
    });

    try {
      // Execute optimized course navigation
      await CourseNavigationUtils.navigateToCourse(
        context,
        ref,
        widget.course,
      );
    } catch (e) {
      print('Navigation error: $e');
    } finally {
      NavigationPerformanceMonitor.endNavigation('course_${widget.course.id}');

      // Cancel the fallback timer
      _dismissTimer?.cancel();

      // Reset navigation state
      if (mounted) {
        setState(() {
          _isNavigating = false;
          _isPressed = false;
        });
        _rippleController.reset();
      }
    }
  }

  void _triggerHapticFeedback() {
    // Light haptic feedback for immediate response
    // Note: You can add haptic feedback package if needed
  }

  void _showErrorSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to navigate to "${widget.course.title}"'),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _handleCourseTap,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isNavigating ? null : _handleCourseTap,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: Stack(
        children: [
          // Main content
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            transform: Matrix4.identity()
              ..scale(_isPressed ? 0.98 : 1.0),
            child: widget.child,
          ),
          
          // Ripple effect
          if (widget.showRipple)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AnimatedBuilder(
                  animation: _rippleAnimation,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryGreen.withOpacity(
                            _rippleAnimation.value * 0.5,
                          ),
                          width: 2,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          
          // Loading indicator overlay
          if (_isNavigating)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Quick course navigation button for course cards
class QuickCourseNavButton extends StatelessWidget {
  final Course course;
  final String? heroTag;

  const QuickCourseNavButton({
    super.key,
    required this.course,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: heroTag ?? 'course_${course.id}',
      child: EnhancedCourseNavigation(
        course: course,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryGreen,
                AppTheme.primaryGreen.withOpacity(0.8),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGreen.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'View Course',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
