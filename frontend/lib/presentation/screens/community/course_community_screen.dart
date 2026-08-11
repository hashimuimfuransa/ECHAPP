import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/community_provider.dart';
import 'community_chat_view.dart';
import 'community_dashboard_view.dart';
import 'community_discussions_view.dart';
import 'community_groups_view.dart';
import 'community_people_view.dart';
import 'community_resources_view.dart';
import 'community_section.dart';
import 'community_theme.dart';
import 'community_work_view.dart';

/// Opens the full course community, optionally on a specific section.
void openCourseCommunity(
  BuildContext context,
  String courseId, {
  CommunitySection section = CommunitySection.home,
}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => CourseCommunityScreen(
        courseId: courseId,
        initialSection: section,
      ),
    ),
  );
}

/// Full-screen course community with every section in one tab bar.
///
/// The learning screen embeds [CourseCommunityView] instead, which shows the
/// dashboard and pushes this screen when a student drills into a section.
class CourseCommunityScreen extends ConsumerStatefulWidget {
  final String courseId;
  final CommunitySection initialSection;

  const CourseCommunityScreen({
    super.key,
    required this.courseId,
    this.initialSection = CommunitySection.home,
  });

  @override
  ConsumerState<CourseCommunityScreen> createState() =>
      _CourseCommunityScreenState();
}

class _CourseCommunityScreenState extends ConsumerState<CourseCommunityScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: CommunitySection.values.length,
    vsync: this,
    initialIndex: widget.initialSection.index,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(communityPresenceProvider(widget.courseId)).start();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openSection(CommunitySection section) {
    _tabController.animateTo(section.index);
  }

  @override
  Widget build(BuildContext context) {
    final overview = ref.watch(communityOverviewProvider(widget.courseId));
    final isTeacher = overview.valueOrNull?.isTeacher ?? false;

    return Scaffold(
      backgroundColor: CT.bgOf(context),
      appBar: AppBar(
        backgroundColor: CT.cardOf(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Community',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: CT.textOf(context),
              ),
            ),
            if (overview.valueOrNull != null)
              Text(
                overview.value!.courseTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: CT.subTextOf(context)),
              ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () =>
                ref.invalidate(communityOverviewProvider(widget.courseId)),
            icon: const Icon(Icons.refresh_rounded, size: 21),
            color: CT.subTextOf(context),
            tooltip: 'Refresh',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: CT.cardOf(context),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: CT.primary,
              unselectedLabelColor: CT.subTextOf(context),
              indicatorColor: CT.primary,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle:
                  const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
              tabs: CommunitySection.values
                  .map((section) => Tab(
                        height: 46,
                        icon: Icon(section.icon, size: 17),
                        iconMargin: const EdgeInsets.only(bottom: 2),
                        text: section.label,
                      ))
                  .toList(),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          CommunityDashboardView(
            courseId: widget.courseId,
            onOpenSection: _openSection,
          ),
          CommunityPeopleView(courseId: widget.courseId),
          CommunityDiscussionsView(
            courseId: widget.courseId,
            isTeacher: isTeacher,
          ),
          CommunityChatView(courseId: widget.courseId),
          CommunityGroupsView(courseId: widget.courseId),
          CommunityWorkView(courseId: widget.courseId, isTeacher: isTeacher),
          CommunityResourcesView(
            courseId: widget.courseId,
            isTeacher: isTeacher,
          ),
        ],
      ),
    );
  }
}

/// The embeddable community view used by the professional learning screen's
/// Community tab: the dashboard, with every "view all" pushing the full
/// [CourseCommunityScreen] on the right section.
class CourseCommunityView extends StatelessWidget {
  final String courseId;

  const CourseCommunityView({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    return CommunityDashboardView(
      courseId: courseId,
      embedded: true,
      onOpenSection: (section) =>
          openCourseCommunity(context, courseId, section: section),
    );
  }
}
