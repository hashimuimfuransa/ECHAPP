import 'package:flutter/material.dart';

/// The sections of a course community, in the order they appear in the tab bar.
enum CommunitySection {
  home,
  people,
  discussions,
  chat,
  groups,
  work,
  resources,
}

extension CommunitySectionInfo on CommunitySection {
  String get label => switch (this) {
        CommunitySection.home => 'Home',
        CommunitySection.people => 'Students',
        CommunitySection.discussions => 'Discussions',
        CommunitySection.chat => 'Chat',
        CommunitySection.groups => 'Groups',
        CommunitySection.work => 'Work',
        CommunitySection.resources => 'Resources',
      };

  IconData get icon => switch (this) {
        CommunitySection.home => Icons.dashboard_rounded,
        CommunitySection.people => Icons.people_alt_rounded,
        CommunitySection.discussions => Icons.forum_rounded,
        CommunitySection.chat => Icons.chat_rounded,
        CommunitySection.groups => Icons.workspaces_rounded,
        CommunitySection.work => Icons.assignment_rounded,
        CommunitySection.resources => Icons.folder_shared_rounded,
      };

  /// Slug used in deep links (`/community/:courseId?section=groups`).
  String get slug => name;

  static CommunitySection fromSlug(String? slug) {
    return CommunitySection.values.firstWhere(
      (s) => s.slug == slug,
      orElse: () => CommunitySection.home,
    );
  }
}
