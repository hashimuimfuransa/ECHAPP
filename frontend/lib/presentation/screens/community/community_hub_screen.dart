import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/course.dart';
import '../../providers/enrollment_provider.dart';
import '../../providers/teacher_provider.dart';
import '../../providers/auth_provider.dart';
import 'community_theme.dart';
import 'course_community_screen.dart';

/// Landing screen for the sidebar "Community" entry.
///
/// A community always belongs to a course, so this asks which one first —
/// listing the courses the user is enrolled in (or, for teachers, assigned to).
class CommunityHubScreen extends ConsumerWidget {
  const CommunityHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authProvider).user?.role;
    final isTeacher = role == 'instructor' || role == 'admin';

    return Scaffold(
      backgroundColor: CT.bgOf(context),
      appBar: AppBar(
        backgroundColor: CT.cardOf(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Community',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: CT.textOf(context),
          ),
        ),
      ),
      body: isTeacher
          ? const _TeacherCourseList()
          : const _StudentCourseList(),
    );
  }
}

class _Intro extends StatelessWidget {
  final String subtitle;
  const _Intro({required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: CT.heroGrad,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: CT.r20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: CT.r12,
                ),
                child: const Icon(Icons.groups_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'ECH Course Community',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentCourseList extends ConsumerWidget {
  const _StudentCourseList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(enrolledCoursesProvider);

    return coursesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(strokeWidth: 2.4, color: CT.primary),
      ),
      error: (error, _) => CommunityErrorView(
        error: error,
        onRetry: () => ref.invalidate(enrolledCoursesProvider),
      ),
      data: (courses) {
        if (courses.isEmpty) {
          return CommunityEmpty(
            icon: Icons.school_rounded,
            title: 'No course communities yet',
            message: 'Every course you enrol in comes with its own community — '
                'classmates, study groups and discussions.',
            actionLabel: 'Browse courses',
            onAction: () => context.go('/courses'),
          );
        }
        return RefreshIndicator(
          color: CT.primary,
          onRefresh: () async => ref.invalidate(enrolledCoursesProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [
              const _Intro(
                subtitle: 'Pick a course to meet the students learning it with '
                    'you, join a study group, and get help.',
              ),
              const SizedBox(height: 20),
              ...courses.map((course) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _CourseCommunityTile(course: course),
                  )),
            ],
          ),
        );
      },
    );
  }
}

class _TeacherCourseList extends ConsumerStatefulWidget {
  const _TeacherCourseList();

  @override
  ConsumerState<_TeacherCourseList> createState() => _TeacherCourseListState();
}

class _TeacherCourseListState extends ConsumerState<_TeacherCourseList> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(teacherProvider.notifier).loadCourses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(teacherProvider);

    if (state.isLoading && state.courses.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2.4, color: CT.primary),
      );
    }
    if (state.error != null && state.courses.isEmpty) {
      return CommunityErrorView(
        error: state.error!,
        onRetry: () => ref.read(teacherProvider.notifier).loadCourses(),
      );
    }
    if (state.courses.isEmpty) {
      return const CommunityEmpty(
        icon: Icons.school_rounded,
        title: 'No courses assigned to you',
        message: 'Once you are assigned to a course, its community appears '
            'here with your teacher tools.',
      );
    }

    return RefreshIndicator(
      color: CT.primary,
      onRefresh: () => ref.read(teacherProvider.notifier).loadCourses(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          const _Intro(
            subtitle: 'Post announcements, publish assignments, answer '
                'questions and grade group work — all inside the course your '
                'students already study in.',
          ),
          const SizedBox(height: 20),
          ...state.courses.map((assignment) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CourseCommunityTile(
                  course: assignment.course,
                  subtitle: '${assignment.enrollmentCount} students · '
                      '${assignment.activeStudents} active',
                ),
              )),
        ],
      ),
    );
  }
}

class _CourseCommunityTile extends StatelessWidget {
  final Course? course;
  final String? subtitle;

  const _CourseCommunityTile({this.course, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final id = course?.id ?? '';
    final title = course?.title ?? 'Course';

    return CommunityCard(
      onTap: id.isEmpty ? null : () => openCourseCommunity(context, id),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  CT.avatarColor(id.isEmpty ? title : id),
                  CT.avatarColor(id.isEmpty ? title : id).withOpacity(0.7),
                ],
              ),
              borderRadius: CT.r12,
            ),
            child: const Icon(Icons.groups_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                    color: CT.textOf(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle ?? 'Open the course community',
                  style: TextStyle(fontSize: 11.5, color: CT.subTextOf(context)),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 20, color: CT.subTextOf(context)),
        ],
      ),
    );
  }
}
