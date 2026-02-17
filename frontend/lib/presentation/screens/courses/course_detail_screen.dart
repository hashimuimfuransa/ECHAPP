import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/models/course.dart';
import 'package:excellencecoachinghub/presentation/providers/course_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/enrollment_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/course_payment_providers.dart';
import 'package:excellencecoachinghub/presentation/providers/payment_riverpod_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/wishlist_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/course_stats_provider.dart';
import 'package:excellencecoachinghub/presentation/screens/payments/payment_pending_screen.dart';
import 'package:excellencecoachinghub/presentation/widgets/beautiful_widgets.dart';
import 'package:excellencecoachinghub/widgets/countdown_timer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

class CourseDetailScreen extends ConsumerStatefulWidget {
  final String courseId;

  const CourseDetailScreen({super.key, required this.courseId});

  @override
  _CourseDetailScreenState createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen> {
  bool _hasRedirected = false;

  // Provider for fetching course information
  static final _courseProvider = FutureProvider.family<Course, String>((ref, courseId) async {
    final repository = ref.watch(courseRepositoryProvider);
    return await repository.getCourseById(courseId);
  });

  // Method to handle enrollment
  void _handleEnrollment(WidgetRef ref, String courseId) async {
    final enrollmentNotifier = ref.read(enrollmentNotifierProvider.notifier);
    await enrollmentNotifier.enrollInCourse(courseId);
  }

  // Method to handle payment
  void _handlePayment(WidgetRef ref, Course course) async {
    print('Initiating payment for course: \${course.title} (ID: \${course.id})');
    print('Course price: ${course.price}');
    
    final paymentNotifier = ref.read(paymentProvider.notifier);
    print('Payment notifier obtained');
    
    try {
      final paymentResponse = await paymentNotifier.initiatePayment(
        courseId: course.id,
        paymentMethod: 'mtn_momo',
        contactInfo: 'Student initiated payment for ${course.title}',
      );
      print('Payment initiation completed');
          
      // Show success message
      if (ref.context.mounted) {
        ScaffoldMessenger.of(ref.context).showSnackBar(
          SnackBar(
            content: Text('Payment initiated successfully! Refreshing course status...'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Refresh the pending payment status to show updated UI
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Refresh the payment data to trigger UI update
        ref.refresh(hasPendingPaymentProvider(course.id));
        
        // Allow UI to update to show 'Payment Pending' status
        await Future.delayed(const Duration(milliseconds: 1000));
        
        // Now navigate to the payment pending screen
        if (ref.context.mounted) {
          Navigator.pushReplacement(
            ref.context,
            MaterialPageRoute(
              builder: (context) => PaymentPendingScreen(
                course: course,
                transactionId: paymentResponse.transactionId,
                amount: paymentResponse.amount,
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('Payment initiation failed: $e');
      // Show error to user
      if (ref.context.mounted) {
        String errorMessage = 'Payment initiation failed: $e';
        
        // Handle specific error cases
        if (e.toString().contains('already enrolled')) {
          errorMessage = 'You are already enrolled in this course!';
        } else if (e.toString().contains('pending')) {
          errorMessage = 'You have a pending payment for this course. Redirecting to payment status...';
          
          // Show snackbar and navigate to payment pending screen
          ScaffoldMessenger.of(ref.context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
          
          // Navigate to payment pending screen after a short delay
          Future.delayed(const Duration(seconds: 2)).then((_) {
            // Navigate to payment pending screen
            if (ref.context.mounted) {
              Navigator.push(
                ref.context,
                MaterialPageRoute(
                  builder: (context) => PaymentPendingScreen(
                    course: course,
                    transactionId: 'pending',
                    amount: course.price,
                  ),
                ),
              );
            }
          });
          return; // Exit early since we're navigating
        }
        
        ScaffoldMessenger.of(ref.context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // Method to handle sharing
  void _handleShare(Course course) async {
    final String shareText = 'Check out this amazing course: \${course.title}\n'
        'Instructor: ${course.createdBy.fullName}\n'
        'Price: ${course.price == 0 ? 'Free' : 'RWF ${course.price.toStringAsFixed(0)}'}\n'
        'Level: ${course.level}\n'
        'Duration: ${course.duration} minutes\n\n'
        'Learn more at Excellence Coaching Hub!';
    
    await Share.share(shareText, subject: 'Course Recommendation: \${course.title}');
  }

  @override
  Widget build(BuildContext context) {
    final ref = context as WidgetRef;
    // Fetch the course data using a provider that's scoped to the widget instance
    final courseAsync = ref.watch(_courseProvider(widget.courseId));
    final isEnrolledAsync = ref.watch(isEnrolledInCourseProvider(widget.courseId));
    
    // Automatic redirect to learning screen if already enrolled
    isEnrolledAsync.when(
      data: (isEnrolled) {
        print('Course Detail Screen - Course ID: ${widget.courseId}, Is Enrolled: $isEnrolled');
        if (isEnrolled && context.mounted && !_hasRedirected) {
          print('User is already enrolled - redirecting to learning screen');
          setState(() {
            _hasRedirected = true;
          });
          // Show a brief message before redirecting
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('You are already enrolled! Redirecting to learning...'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
              // Navigate to learning screen
              context.push('/learning/${widget.courseId}');
            }
          });
        }
      },
      loading: () => print('Course Detail Screen - Checking enrollment status...'),
      error: (error, stack) => print('Course Detail Screen - Enrollment check error: $error'),
    );
    
    // Manual pending payment check and refresh user payments
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      print('🕒 Manual pending payment check triggered');
      try {
        // Refresh user payments before checking pending status
        await ref.read(paymentProvider.notifier).loadUserPayments();
        
        final hasPending = await ref.read(hasPendingPaymentProvider(widget.courseId).future);
        print('🕒 Manual pending payment check result: $hasPending');
        
        // If there's a pending payment, consider auto-navigating to payment pending screen
        if (hasPending && context.mounted && !_hasRedirected) {
          print('🟡 Pending payment detected - should show payment pending button');
        }
      } catch (e) {
        print('❌ Manual pending payment check error: $e');
      }
    });

    return courseAsync.when(
      data: (course) {
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF667eea),
                  Color(0xFF764ba2),
                  Color(0xFFf093fb),
                  Color(0xFFf5576c),
                ],
                stops: [0.0, 0.4, 0.7, 1.0],
              ),
            ),
            child: CustomScrollView(
              slivers: [
                // Enhanced Header with back button
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                      onPressed: () => context.pop(),
                    ),
                  ),
                  actions: [
                    Consumer(
                      builder: (context, ref, child) {
                        final isBookmarkedAsync = ref.watch(isCourseInWishlistProvider(widget.courseId));
                        
                        return Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: isBookmarkedAsync.when(
                              data: (isBookmarked) => Icon(
                                isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                color: isBookmarked ? Colors.yellow : Colors.white,
                                size: 20,
                              ),
                              loading: () => const Icon(
                                Icons.bookmark_border,
                                color: Colors.white,
                                size: 20,
                              ),
                              error: (error, stack) => const Icon(
                                Icons.bookmark_border,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            onPressed: () {
                              final wishlistNotifier = ref.read(wishlistNotifierProvider.notifier);
                              wishlistNotifier.toggleCourse(widget.courseId, course);
                            },
                          ),
                        );
                      },
                    ),
                    // Refresh button
                    Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                        onPressed: () {
                          // Refresh the course detail screen
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => CourseDetailScreen(courseId: widget.courseId),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.share_outlined, color: Colors.white, size: 20),
                        onPressed: () {
                          _handleShare(course);
                        },
                      ),
                    ),
                  ],
                  expandedHeight: 320,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Enhanced Course Image with better loading
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            image: course.thumbnail != null && course.thumbnail!.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(course.thumbnail!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: course.thumbnail == null || course.thumbnail!.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.play_circle_outline,
                                        color: Colors.white.withOpacity(0.7),
                                        size: 80,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No thumbnail available',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : null,
                        ),
                        // Enhanced gradient overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.3),
                                Colors.black.withOpacity(0.8),
                              ],
                              stops: const [0.3, 0.7, 1.0],
                            ),
                          ),
                        ),
                        // Enhanced Course Info Overlay
                        Positioned(
                          bottom: 25,
                          left: 25,
                          right: 25,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Course category badge
                              if (course.category != null && course.category!['name'] != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    course.category!['name'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                              // Course title
                              Text(
                                course.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(0, 2),
                                      blurRadius: 4,
                                      color: Colors.black26,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),

                              const SizedBox(height: 6),
                              // Rating and students (if available)
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    '4.8',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '(1,248 ratings)',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Enhanced Content Section
                SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, -10),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Enhanced Price and Actions
                          _buildEnhancedPriceSection(course),
                          
                          const SizedBox(height: 30),
                          
                          // Enhanced Course Stats
                          _buildEnhancedCourseStats(course),
                          
                          const SizedBox(height: 30),
                          
                          // Enhanced Description
                          _buildEnhancedDescription(course),
                          
                          const SizedBox(height: 30),
                          
                          // Enhanced Learning Objectives
                          if (course.learningObjectives != null && course.learningObjectives!.isNotEmpty)
                            _buildEnhancedLearningObjectives(course),
                          
                          const SizedBox(height: 30),
                          
                          // Enhanced Requirements
                          if (course.requirements != null && course.requirements!.isNotEmpty)
                            _buildEnhancedRequirements(course),
                          
                          const SizedBox(height: 30),
                          
                          // Enhanced Enroll Button
                          _buildEnhancedEnrollSection(context, course, ref, isEnrolledAsync),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: GradientBackground(
          colors: AppTheme.oceanGradient,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: GradientBackground(
          colors: AppTheme.oceanGradient,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 60,
                ),
                const SizedBox(height: 20),
                Text(
                  'Error loading course: $error',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // Refresh by rebuilding the widget
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => CourseDetailScreen(courseId: widget.courseId),
                      ),
                    );
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedPriceSection(Course course) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWideScreen = constraints.maxWidth > 600;
            
            return isWideScreen
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildEnhancedPriceInfo(course),
                      _buildEnhancedPurchaseButton(course),
                    ],
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildEnhancedPriceInfo(course),
                        const SizedBox(height: 20),
                        _buildEnhancedPurchaseButton(course),
                      ],
                    ),
                  );
          },
        ),
      ),
    );
  }

  Widget _buildPriceSection(Course course) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 600;
        
        return GlassContainer(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: isWideScreen
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildPriceInfo(course),
                      _buildPurchaseButton(course),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildPriceInfo(course),
                      const SizedBox(height: 20),
                      _buildPurchaseButton(course),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedPriceInfo(Course course) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'COURSE PRICE',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              course.price == 0 ? 'FREE' : 'RWF ${course.price.toStringAsFixed(0)}',
              style: TextStyle(
                color: course.price == 0 ? Colors.white : Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                    color: Colors.black.withOpacity(0.2),
                  ),
                ],
              ),
            ),
            if (course.price != 0) ...[
              const SizedBox(width: 12),
              Text(
                'RWF ${(course.price * 1.2).toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 20,
                  decoration: TextDecoration.lineThrough,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Limited time offer • 30-day money back guarantee',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceInfo(Course course) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Price',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Text(
              course.price == 0 ? 'Free' : 'RWF ${course.price.toStringAsFixed(0)}',
              style: TextStyle(
                color: course.price == 0 ? Colors.green : Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (course.price != 0) ...[
              const SizedBox(width: 10),
              Text(
                'RWF ${(course.price * 1.2).toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 18,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildEnhancedPurchaseButton(Course course) {
    print('🔨 Building purchase button for course: ${course.id} - ${course.title}');
    print('🆔 Course ID type: ${course.id.runtimeType}, value: ${course.id}');
    
    // Force refresh the pending payment provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🔄 Forcing refresh of pending payment provider');
    });
    
    return Consumer(
      builder: (context, ref, child) {
        print('👀 Consumer rebuilding...');
        final paymentState = ref.watch(initiatePaymentProvider);
        final hasPendingPayment = ref.watch(hasPendingPaymentProvider(course.id));
        
        print('💳 Payment state: ${paymentState.runtimeType}');
        print('⏰ Pending payment state: ${hasPendingPayment.runtimeType}');
        print('🆔 Watching courseId: ${course.id}');
        
        return SizedBox(
          height: 60,
          child: hasPendingPayment.when(
            data: (hasPending) {
              print('🎯 Has pending payment result: $hasPending');
              if (hasPending) {
                print('🟠 Showing Payment Pending button');
                return Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.orange, Colors.deepOrange],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentPendingScreen(
                            course: course,
                            transactionId: 'pending',
                            amount: course.price,
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'Payment Pending',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }
              
              // Show regular payment button
              return ElevatedButton(
                onPressed: () {
                  print('💳 Initiating payment for course: ${course.id}');
                  _handlePayment(ref, course);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Pay ${course.price.toStringAsFixed(0)} RWF',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
            loading: () => Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text(
                  'Checking...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            error: (error, stack) {
              print('⚠️ Pending payment check error: $error');
              // Show regular payment button as fallback
              return ElevatedButton(
                onPressed: () {
                  print('💳 Initiating payment for course: ${course.id}');
                  _handlePayment(ref, course);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Pay ${course.price.toStringAsFixed(0)} RWF',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEnhancedEnrollButton(Course course, WidgetRef ref) {
    if (course.price == 0) {
      return Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.green, Colors.lightGreen],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextButton(
          onPressed: () {
            // Handle free enrollment
          },
          child: const Text(
            'Enroll For Free',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4facfe).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextButton(
          onPressed: () {
            _handlePayment(ref, course);
          },
          child: Text(
            'Buy Now - RWF ${course.price.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildPurchaseButton(Course course) {
    return Consumer(
      builder: (context, ref, child) {
        final paymentState = ref.watch(initiatePaymentProvider);
        final hasPendingPayment = ref.watch(hasPendingPaymentProvider(course.id));
        
        if (paymentState.response != null) {
          return AnimatedButton(
            text: 'Processing...',
            onPressed: () {},
            color: Colors.grey,
            isLoading: true,
          );
        } else if (paymentState.isLoading) {
          return AnimatedButton(
            text: 'Processing...',
            onPressed: () {},
            color: Colors.grey,
            isLoading: true,
          );
        } else {
          return hasPendingPayment.when(
            data: (hasPending) {
                if (hasPending) {
                  return AnimatedButton(
                    text: 'Payment Pending',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentPendingScreen(
                            course: course,
                            transactionId: 'pending',
                            amount: course.price,
                          ),
                        ),
                      );
                    },
                    color: Colors.orange,
                  );
                }
                
                if (course.price == 0) {
                  return AnimatedButton(
                    text: 'Enroll Now',
                    onPressed: () {
                      // Handle free enrollment
                    },
                    color: Colors.green,
                  );
                } else {
                  return AnimatedButton(
                    text: 'Buy Now',
                    onPressed: () {
                      _handlePayment(ref, course);
                    },
                    color: const Color(0xFF4facfe),
                  );
                }
              },
              loading: () => AnimatedButton(
                text: 'Checking...',
                onPressed: () {},
                color: Colors.grey,
              ),
              error: (error, stack) {
                if (course.price == 0) {
                  return AnimatedButton(
                    text: 'Enroll Now',
                    onPressed: () {
                      // Handle free enrollment
                    },
                    color: Colors.green,
                  );
                } else {
                  return AnimatedButton(
                    text: 'Buy Now',
                    onPressed: () {
                      _handlePayment(ref, course);
                    },
                    color: const Color(0xFF4facfe),
                  );
                }
              }
            );
          }
        },
      );
  }

  Widget _buildEnrollButtonFallback(Course course) {
    if (course.price == 0) {
      return AnimatedButton(
        text: 'Enroll Now',
        onPressed: () {
          // Handle free enrollment
        },
        color: Colors.green,
      );
    } else {
      return AnimatedButton(
        text: 'Buy Now',
        onPressed: () {
          // Handle paid enrollment
        },
        color: const Color(0xFF4facfe),
      );
    }
  }

  Widget _buildEnhancedCourseStats(Course course) {
    return Consumer(
      builder: (context, ref, child) {
        final enrollmentCountAsync = ref.watch(courseStatsProvider(course.id));
        
        return enrollmentCountAsync.when(
          data: (enrollmentCount) {
            final stats = [
              {
                'icon': Icons.access_time_outlined,
                'value': '${course.duration} mins',
                'label': 'Duration',
                'color': const Color(0xFF667eea)
              },
              {
                'icon': Icons.speed_outlined,
                'value': course.level,
                'label': 'Level',
                'color': const Color(0xFF764ba2)
              },
              {
                'icon': Icons.people_outline,
                'value': enrollmentCount.toString(),
                'label': 'Students',
                'color': const Color(0xFFf093fb)
              },
            ];

            // Only add category if it's provided in the course data
            if (course.category != null && course.category!['name'] != null) {
              stats.add({
                'icon': Icons.category_outlined,
                'value': course.category!['name'],
                'label': 'Category',
                'color': const Color(0xFFf5576c)
              });
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Course Overview',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: stats.map((stat) => _buildEnhancedStatItem(stat)).toList(),
                ),
              ],
            );
          },
          loading: () {
            // Show skeleton loading while fetching enrollment count
            final stats = [
              {
                'icon': Icons.access_time_outlined,
                'value': '${course.duration} mins',
                'label': 'Duration',
                'color': const Color(0xFF667eea)
              },
              {
                'icon': Icons.speed_outlined,
                'value': course.level,
                'label': 'Level',
                'color': const Color(0xFF764ba2)
              },
              {
                'icon': Icons.people_outline,
                'value': 'Loading...',
                'label': 'Students',
                'color': const Color(0xFFf093fb)
              },
            ];

            if (course.category != null && course.category!['name'] != null) {
              stats.add({
                'icon': Icons.category_outlined,
                'value': course.category!['name'],
                'label': 'Category',
                'color': const Color(0xFFf5576c)
              });
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Course Overview',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: stats.map((stat) => _buildEnhancedStatItem(stat)).toList(),
                ),
              ],
            );
          },
          error: (error, stack) {
            // Fallback to showing 0 students if there's an error
            final stats = [
              {
                'icon': Icons.access_time_outlined,
                'value': '${course.duration} mins',
                'label': 'Duration',
                'color': const Color(0xFF667eea)
              },
              {
                'icon': Icons.speed_outlined,
                'value': course.level,
                'label': 'Level',
                'color': const Color(0xFF764ba2)
              },
              {
                'icon': Icons.people_outline,
                'value': '0',
                'label': 'Students',
                'color': const Color(0xFFf093fb)
              },
            ];

            if (course.category != null && course.category!['name'] != null) {
              stats.add({
                'icon': Icons.category_outlined,
                'value': course.category!['name'],
                'label': 'Category',
                'color': const Color(0xFFf5576c)
              });
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Course Overview',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: stats.map((stat) => _buildEnhancedStatItem(stat)).toList(),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEnhancedStatItem(Map<String, dynamic> stat) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            stat['color'],
            stat['color'].withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: stat['color'].withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(stat['icon'], color: Colors.white, size: 28),
          const SizedBox(height: 10),
          Text(
            stat['value'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            stat['label'],
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCourseStats(Course course) {
    final stats = [
      {
        'icon': Icons.access_time_outlined,
        'value': '${course.duration} mins',
        'label': 'Duration'
      },
      {
        'icon': Icons.speed_outlined,
        'value': course.level,
        'label': 'Level'
      },
    ];

    // Only add language if it's provided in the course data
    if (course.category != null && course.category!['name'] != null) {
      stats.add({
        'icon': Icons.category_outlined,
        'value': course.category!['name'],
        'label': 'Category'
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Course Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        Wrap(
          spacing: 15,
          runSpacing: 15,
          children: stats.map((stat) => _buildStatItem(stat)).toList(),
        ),
      ],
    );
  }

  Widget _buildStatItem(Map<String, dynamic> stat) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(stat['icon'], color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            stat['value'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            stat['label'],
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedDescription(Course course) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About This Course',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: Text(
            course.description,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 16,
              height: 1.7,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(Course course) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            course.description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedLearningObjectives(Course course) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What You Will Learn',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: course.learningObjectives!.asMap().entries.map((entry) {
              final index = entry.key;
              final objective = entry.value;
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: index == course.learningObjectives!.length - 1 
                    ? null 
                    : Border(
                        bottom: BorderSide(
                          color: Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        objective,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLearningObjectives(Course course) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What You Will Learn',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: course.learningObjectives!.asMap().entries.map((entry) {
              final index = entry.key;
              final objective = entry.value;
              return Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  border: index == course.learningObjectives!.length - 1 
                    ? null 
                    : Border(
                        bottom: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        objective,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedRequirements(Course course) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Requirements',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: course.requirements!.asMap().entries.map((entry) {
              final index = entry.key;
              final requirement = entry.value;
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: index == course.requirements!.length - 1 
                    ? null 
                    : Border(
                        bottom: BorderSide(
                          color: Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.info,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        requirement,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRequirements(Course course) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Requirements',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: course.requirements!.asMap().entries.map((entry) {
              final index = entry.key;
              final requirement = entry.value;
              return Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  border: index == course.requirements!.length - 1 
                    ? null 
                    : Border(
                        bottom: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        requirement,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCurriculumPreview() {
    final curriculum = [
      {'title': 'Introduction to Flutter', 'duration': '15 mins', 'isCompleted': true},
      {'title': 'Setting up Development Environment', 'duration': '25 mins', 'isCompleted': true},
      {'title': 'Dart Basics', 'duration': '45 mins', 'isCompleted': false},
      {'title': 'Widgets and Layouts', 'duration': '1 hour', 'isCompleted': false},
      {'title': 'State Management', 'duration': '1.5 hours', 'isCompleted': false},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Curriculum Preview',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: curriculum.asMap().entries.map((entry) {
              final index = entry.key;
              final lesson = entry.value;
              return _buildLessonItem(index, lesson, index == curriculum.length - 1);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLessonItem(int index, Map<String, dynamic> lesson, bool isLast) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        border: isLast ? null : Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: lesson['isCompleted'] 
                  ? Colors.green.withOpacity(0.3) 
                  : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              lesson['isCompleted'] ? Icons.check : Icons.play_arrow_outlined,
              color: lesson['isCompleted'] ? Colors.green : Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson['title'],
                  style: TextStyle(
                    color: lesson['isCompleted'] ? Colors.white60 : Colors.white,
                    fontSize: 16,
                    fontWeight: lesson['isCompleted'] ? FontWeight.normal : FontWeight.w500,
                  ),
                ),
                Text(
                  lesson['duration'],
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.lock_outline,
            color: lesson['isCompleted'] ? Colors.green : Colors.white54,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedInstructorInfo(Course course) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Meet Your Instructor',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF667eea).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      course.createdBy.fullName.split(' ').map((n) => n[0]).join('').toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.createdBy.fullName,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Lead Instructor & Course Creator',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                        ),
                      ),
                      if (course.createdBy.email.isNotEmpty == true) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.email_outlined,
                              color: Colors.grey,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              course.createdBy.email,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      const Text(
                        'With 5+ years of teaching experience and expertise in modern development practices, our instructor brings real-world knowledge to help you succeed.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructorInfo(Course course) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Instructor',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        GlassContainer(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(
                    course.createdBy.fullName.split(' ').map((n) => n[0]).join('').toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.createdBy.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Course Creator',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                        ),
                      ),
                      if (course.createdBy.email.isNotEmpty == true) ...[
                        const SizedBox(height: 3),
                        Text(
                          course.createdBy.email,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnrollButton(BuildContext context, Course course, WidgetRef ref) {
    if (course.price == 0) {
      return AnimatedButton(
        text: 'Enroll for Free',
        onPressed: () async {
          _handleEnrollment(ref, widget.courseId);
        },
        color: Colors.green,
      );
    } else {
      return AnimatedButton(
        text: 'Buy Course - RWF ${course.price.toStringAsFixed(0)}',
        onPressed: () {
          _handlePayment(ref, course);
        },
        color: const Color(0xFF4facfe),
      );
    }
  }

  Widget _buildEnhancedEnrollSection(BuildContext context, Course course, WidgetRef ref, AsyncValue<bool> isEnrolledAsync) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Ready to Start Learning?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Join thousands of students who have already transformed their skills',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            isEnrolledAsync.when(
              data: (isEnrolled) {
                return isEnrolled 
                  ? _buildEnhancedContinueLearningButton(context, course) 
                  : _buildEnhancedEnrollButton(course, ref);
              },
              loading: () => Container(
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    'Checking enrollment status...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              error: (error, stack) => _buildEnhancedEnrollButton(course, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedContinueLearningButton(BuildContext context, Course course) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.orange, Colors.deepOrange],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextButton(
        onPressed: () {
          // Navigate directly to the learning screen using GoRouter
          context.push('/learning/${course.id}');
        },
        child: const Text(
          'Continue Learning',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildContinueLearningButton(BuildContext context, Course course) {
    return AnimatedButton(
      text: 'Continue Learning',
      onPressed: () {
        // Navigate directly to the learning screen using GoRouter
        context.push('/learning/${course.id}');
      },
      color: Colors.orange,
    );
  }
}
