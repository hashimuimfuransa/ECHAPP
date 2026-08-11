import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/community.dart';
import '../../providers/community_provider.dart';
import 'community_dashboard_view.dart' show DiscussionTile;
import 'community_theme.dart';
import 'post_detail_screen.dart';
import 'sheets/create_post_sheet.dart';

/// Discussions, questions, announcements and the Help area — one feed with
/// filters, because they are all conversations and students should not have
/// to guess which surface their question belongs on.
class CommunityDiscussionsView extends ConsumerStatefulWidget {
  final String courseId;
  final bool isTeacher;

  /// Opens straight onto the Help filter (used by the "Get help" action).
  final bool helpOnly;

  const CommunityDiscussionsView({
    super.key,
    required this.courseId,
    this.isTeacher = false,
    this.helpOnly = false,
  });

  @override
  ConsumerState<CommunityDiscussionsView> createState() =>
      _CommunityDiscussionsViewState();
}

class _CommunityDiscussionsViewState
    extends ConsumerState<CommunityDiscussionsView> {
  CommunityPostType? _type;
  String _search = '';
  bool _unansweredOnly = false;

  @override
  void initState() {
    super.initState();
    if (widget.helpOnly) _type = CommunityPostType.help;
  }

  @override
  Widget build(BuildContext context) {
    final query = PostQuery(
      widget.courseId,
      type: _type,
      search: _search,
      unansweredOnly: _unansweredOnly,
    );
    final postsAsync = ref.watch(communityPostsProvider(query));

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: TextField(
                onChanged: (value) => setState(() => _search = value),
                style: TextStyle(fontSize: 13.5, color: CT.textOf(context)),
                decoration: InputDecoration(
                  hintText: 'Search discussions',
                  hintStyle: const TextStyle(fontSize: 13, color: CT.textHint),
                  prefixIcon: const Icon(Icons.search_rounded, size: 19),
                  filled: true,
                  fillColor: CT.cardOf(context),
                  contentPadding: const EdgeInsets.symmetric(vertical: 6),
                  border: OutlineInputBorder(
                    borderRadius: CT.r12,
                    borderSide: BorderSide(color: CT.borderOf(context)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: CT.r12,
                    borderSide: BorderSide(color: CT.borderOf(context)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: CT.r12,
                    borderSide: BorderSide(color: CT.primary, width: 1.5),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _typeChip(null, 'All'),
                  _typeChip(CommunityPostType.question, 'Questions'),
                  _typeChip(CommunityPostType.help, 'Help'),
                  _typeChip(CommunityPostType.discussion, 'Discussions'),
                  _typeChip(CommunityPostType.announcement, 'Announcements'),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: _unansweredOnly,
                      onSelected: (value) =>
                          setState(() => _unansweredOnly = value),
                      label: const Text('Unanswered'),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _unansweredOnly ? Colors.white : CT.textOf(context),
                      ),
                      selectedColor: CT.warn,
                      checkmarkColor: Colors.white,
                      backgroundColor: CT.cardOf(context),
                      shape: const RoundedRectangleBorder(borderRadius: CT.r12),
                      side: BorderSide(color: CT.borderOf(context)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: postsAsync.when(
                loading: () => const Center(
                  child:
                      CircularProgressIndicator(strokeWidth: 2.4, color: CT.primary),
                ),
                error: (error, _) => CommunityErrorView(
                  error: error,
                  onRetry: () => ref.invalidate(communityPostsProvider(query)),
                ),
                data: (posts) {
                  if (posts.isEmpty) {
                    return CommunityEmpty(
                      icon: Icons.forum_rounded,
                      title: _search.isNotEmpty
                          ? 'Nothing matches that search'
                          : 'No posts here yet',
                      message: _search.isNotEmpty
                          ? 'Try different words, or start the discussion yourself.'
                          : 'Ask the first question — your classmates and teacher '
                              'will see it in their community feed.',
                      actionLabel: 'Start a post',
                      onAction: () => _compose(context),
                    );
                  }
                  return RefreshIndicator(
                    color: CT.primary,
                    onRefresh: () async =>
                        ref.invalidate(communityPostsProvider(query)),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: DiscussionTile(
                            post: post,
                            onTap: () => openPostDetail(
                                context, widget.courseId, post.id,
                                isTeacher: widget.isTeacher),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            heroTag: 'community-new-post',
            onPressed: () => _compose(context),
            backgroundColor: CT.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.edit_rounded),
            label: Text(_type == CommunityPostType.help ? 'Get help' : 'New post'),
          ),
        ),
      ],
    );
  }

  Widget _typeChip(CommunityPostType? type, String label) {
    final selected = _type == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        onSelected: (_) => setState(() => _type = type),
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : CT.textOf(context),
        ),
        selectedColor: CT.primary,
        backgroundColor: CT.cardOf(context),
        shape: const RoundedRectangleBorder(borderRadius: CT.r12),
        side: BorderSide(color: CT.borderOf(context)),
        showCheckmark: false,
      ),
    );
  }

  Future<void> _compose(BuildContext context) async {
    await showCreatePostSheet(
      context,
      ref,
      widget.courseId,
      initialType: _type ?? CommunityPostType.discussion,
      isTeacher: widget.isTeacher,
    );
  }
}
