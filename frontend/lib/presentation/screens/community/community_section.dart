import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

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
  /// Tab label in the reader's language.
  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return switch (this) {
      CommunitySection.home => l10n.communitySectionHome,
      CommunitySection.people => l10n.communitySectionStudents,
      CommunitySection.discussions => l10n.communitySectionDiscussions,
      CommunitySection.chat => l10n.communitySectionChat,
      CommunitySection.groups => l10n.communitySectionGroups,
      CommunitySection.work => l10n.communitySectionWork,
      CommunitySection.resources => l10n.communitySectionResources,
    };
  }

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
