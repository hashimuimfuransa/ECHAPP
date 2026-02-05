import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellence_coaching_hub/presentation/widgets/beautiful_widgets.dart';
import 'package:excellence_coaching_hub/config/app_theme.dart';
import 'package:excellence_coaching_hub/models/course.dart';
import 'package:excellence_coaching_hub/presentation/providers/course_provider.dart';
import 'package:excellence_coaching_hub/presentation/providers/enrollment_provider.dart';
import 'package:excellence_coaching_hub/presentation/providers/payment_provider.dart';
import 'package:excellence_coaching_hub/presentation/screens/learning/student_learning_screen.dart';
import 'package:excellence_coaching_hub/presentation/screens/payments/payment_pending_screen.dart';
import 'package:share_plus/share_plus.dart';

class CourseDetailScreen extends ConsumerWidget {
  final String courseId;

  const CourseDetailScreen({super.key, required this.courseId});

  // Provider for fetching a single course by ID - this ensures the API call is cached per course ID
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
    print('Initiating payment for course: ${course.title} (ID: ${course.id})');
    print('Course price: ${course.price}');
    
    final paymentNotifier = ref.read(initiatePaymentProvider.notifier);
    print('Payment notifier obtained');
    
    try {
      await paymentNotifier.initiatePayment(
        courseId: course.id,
        paymentMethod: 'mtn_momo', // Changed to valid payment method
        contactInfo: 'Student initiated payment for ${course.title}',
      );
      print('Payment initiation completed');
    } catch (e) {
      print('Payment initiation failed: $e');
      // Show error to user
      if (ref.context.mounted) {
        String errorMessage = 'Payment initiation failed: $e';
        
        // Handle specific error cases
        if (e.toString().contains('already enrolled')) {
          errorMessage = 'You are already enrolled in this course!';
        } else if (e.toString().contains('pending')) {
          errorMessage = 'You have a pending payment for this course. Please check your payment status.';
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
    final String shareText = 'Check out this amazing course: ${course.title}\n'
        'Instructor: ${course.createdBy.fullName}\n'
        'Price: ${course.price == 0 ? 'Free' : 'RWF ${course.price.toStringAsFixed(0)}'}\n'
        'Level: ${course.level}\n'
        'Duration: ${course.duration} minutes\n\n'
        'Learn more at Excellence Coaching Hub!';
    
    await Share.share(shareText, subject: 'Course Recommendation: ${course.title}');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch the course data using a provider that's scoped to the widget instance
    final courseAsync = ref.watch(_courseProvider(courseId));
    final isEnrolledAsync = ref.watch(isEnrolledInCourseProvider(courseId));
    
    // Debug logging
    isEnrolledAsync.when(
      data: (isEnrolled) {
        print('Course Detail Screen - Course ID: $courseId, Is Enrolled: $isEnrolled');
      },
      loading: () => print('Course Detail Screen - Checking enrollment status...'),
      error: (error, stack) => print('Course Detail Screen - Enrollment check error: $error'),
    );

    return courseAsync.when(
      data: (course) {
        return Scaffold(
          body: GradientBackground(
            colors: AppTheme.oceanGradient,
            child: CustomScrollView(
              slivers: [
                // Header with back button
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.bookmark_border, color: Colors.white),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_outlined, color: Colors.white),
                      onPressed: () {
                        _handleShare(course);
                      },
                    ),
                  ],
                  expandedHeight: 300,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Course Image
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.greyColor.withOpacity(0.1),
                          ),
                          child: const Icon(
                            Icons.play_circle_outline,
                            color: AppTheme.greyColor,
                            size: 100,
                          ),
                        ),
                        // Gradient overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                        // Course Info Overlay
                        Positioned(
                          bottom: 20,
                          left: 20,
                          right: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                course.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'by ${course.createdBy.fullName}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Content
                SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Price and Actions
                          _buildPriceSection(course),
                          
                          const SizedBox(height: 25),
                          
                          // Course Stats
                          _buildCourseStats(course),
                          
                          const SizedBox(height: 25),
                          
                          // Description
                          _buildDescription(course),
                          
                          const SizedBox(height: 25),
                          
                          // Learning Objectives (only if provided)
                          if (course.learningObjectives != null && course.learningObjectives!.isNotEmpty)
                            _buildLearningObjectives(course),
                          
                          const SizedBox(height: 25),
                          
                          // Requirements (only if provided)
                          if (course.requirements != null && course.requirements!.isNotEmpty)
                            _buildRequirements(course),
                          
                          const SizedBox(height: 25),
                          
                          // Instructor Info
                          _buildInstructorInfo(course),
                          
                          const SizedBox(height: 30),
                          
                          // Enroll Button based on enrollment status
                          isEnrolledAsync.when(
                            data: (isEnrolled) {
                              return isEnrolled 
                                ? _buildContinueLearningButton(context, course) 
                                : Consumer(
                                    builder: (context, ref, child) {
                                      return LayoutBuilder(
                                        builder: (context, constraints) {
                                          final isWideScreen = constraints.maxWidth > 600;
                                          final paymentState = ref.watch(initiatePaymentProvider);
                                          final hasPendingPayment = ref.watch(hasPendingPaymentProvider(course.id));
                                          
                                          return Container(
                                            width: isWideScreen ? 300 : double.infinity,
                                            child: paymentState.when(
                                              data: (response) {
                                                if (response != null) {
                                                  return AnimatedButton(
                                                    text: 'Processing Payment...',
                                                    onPressed: () {},
                                                    color: Colors.grey,
                                                    isLoading: true,
                                                  );
                                                }
                                                return hasPendingPayment.when(
                                                  data: (hasPending) {
                                                    if (hasPending) {
                                                      return AnimatedButton(
                                                        text: 'Payment Pending Approval',
                                                        onPressed: () {
                                                          // Navigate to payment pending screen or show payment details
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
                                                    return _buildEnrollButton(context, course, ref);
                                                  },
                                                  loading: () => AnimatedButton(
                                                    text: 'Checking Payment Status...',
                                                    onPressed: () {},
                                                    color: Colors.grey,
                                                  ),
                                                  error: (error, stack) => _buildEnrollButton(context, course, ref),
                                                );
                                              },
                                              loading: () => AnimatedButton(
                                                text: 'Processing Payment...',
                                                onPressed: () {},
                                                color: Colors.grey,
                                                isLoading: true,
                                              ),
                                              error: (error, stack) => hasPendingPayment.when(
                                                data: (hasPending) {
                                                  if (hasPending) {
                                                    return AnimatedButton(
                                                      text: 'Payment Pending Approval',
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
                                                  return _buildEnrollButton(context, course, ref);
                                                },
                                                loading: () => AnimatedButton(
                                                  text: 'Checking Payment Status...',
                                                  onPressed: () {},
                                                  color: Colors.grey,
                                                ),
                                                error: (error, stack) => _buildEnrollButton(context, course, ref),
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  );
                            },
                            loading: () => AnimatedButton(
                              text: 'Loading...',
                              onPressed: () {}, // Empty function to satisfy non-null requirement
                              color: Colors.grey,
                              isLoading: true,
                            ),
                            error: (error, stack) => Consumer(
                              builder: (context, ref, child) {
                                return AnimatedButton(
                                  text: 'Enroll Now',
                                  onPressed: () {
                                    _handleEnrollment(ref, courseId);
                                  },
                                  color: Colors.blue,
                                );
                              },
                            ),
                          ),
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
                        builder: (context) => CourseDetailScreen(courseId: courseId),
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

  Widget _buildPurchaseButton(Course course) {
    return Consumer(
      builder: (context, ref, child) {
        final paymentState = ref.watch(initiatePaymentProvider);
        final hasPendingPayment = ref.watch(hasPendingPaymentProvider(course.id));
        
        return paymentState.when(
          data: (response) {
            if (response != null) {
              return AnimatedButton(
                text: 'Processing...',
                onPressed: () {},
                color: Colors.grey,
                isLoading: true,
              );
            }
            
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
              },
            );
          },
          loading: () => AnimatedButton(
            text: 'Processing...',
            onPressed: () {},
            color: Colors.grey,
            isLoading: true,
          ),
          error: (error, stack) {
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
                return _buildEnrollButtonFallback(course);
              },
              loading: () => AnimatedButton(
                text: 'Checking...',
                onPressed: () {},
                color: Colors.grey,
              ),
              error: (error, stack) => _buildEnrollButtonFallback(course),
            );
          },
        );
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
                      if (course.createdBy.email?.isNotEmpty == true) ...[
                        const SizedBox(height: 3),
                        Text(
                          course.createdBy.email!,
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
          _handleEnrollment(ref, courseId);
        },
        color: Colors.green,
      );
    } else {
      final paymentState = ref.watch(initiatePaymentProvider);
      
      return paymentState.when(
        data: (response) {
          if (response != null) {
            // Payment initiated successfully, show pending screen
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentPendingScreen(
                    course: course,
                    transactionId: response.transactionId,
                    amount: response.amount,
                  ),
                ),
              );
            });
            return AnimatedButton(
              text: 'Processing...',
              onPressed: () {}, // Empty function to satisfy non-null requirement
              color: Colors.grey,
            );
          }
          return AnimatedButton(
            text: 'Buy Course - RWF ${course.price.toStringAsFixed(0)}',
            onPressed: () {
              _handlePayment(ref, course);
            },
            color: const Color(0xFF4facfe),
          );
        },
        loading: () => AnimatedButton(
          text: 'Processing Payment...',
          onPressed: () {}, // Empty function to satisfy non-null requirement
          color: Colors.grey,
        ),
        error: (error, stack) => AnimatedButton(
          text: 'Buy Course - RWF ${course.price.toStringAsFixed(0)}',
          onPressed: () {
            _handlePayment(ref, course);
          },
          color: const Color(0xFF4facfe),
        ),
      );
    }
  }

  Widget _buildContinueLearningButton(BuildContext context, Course course) {
    return AnimatedButton(
      text: 'Continue Learning',
      onPressed: () {
        // Navigate to the learning screen for this course
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StudentLearningScreen(courseId: course.id),
          ),
        );
      },
      color: Colors.orange,
    );
  }
}