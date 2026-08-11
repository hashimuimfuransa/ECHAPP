import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/community.dart';
import '../../../providers/community_provider.dart';
import '../community_theme.dart';

/// Composer for everything that lands in the discussions feed: a discussion,
/// a question, a help request or (teachers only) an announcement.
///
/// Returns `true` when something was posted.
Future<bool> showCreatePostSheet(
  BuildContext context,
  WidgetRef ref,
  String courseId, {
  CommunityPostType initialType = CommunityPostType.discussion,
  HelpCategory? initialHelpCategory,
  bool isTeacher = false,
}) async {
  final result = await showCommunitySheet<bool>(
    context: context,
    title: switch (initialType) {
      CommunityPostType.question => 'Ask a question',
      CommunityPostType.announcement => 'Post an announcement',
      CommunityPostType.help => 'Get help',
      CommunityPostType.discussion => 'Start a discussion',
    },
    builder: (ctx, controller) => _CreatePostForm(
      courseId: courseId,
      scrollController: controller,
      initialType: initialType,
      initialHelpCategory: initialHelpCategory,
      isTeacher: isTeacher,
    ),
  );
  return result == true;
}

class _CreatePostForm extends ConsumerStatefulWidget {
  final String courseId;
  final ScrollController scrollController;
  final CommunityPostType initialType;
  final HelpCategory? initialHelpCategory;
  final bool isTeacher;

  const _CreatePostForm({
    required this.courseId,
    required this.scrollController,
    required this.initialType,
    this.initialHelpCategory,
    this.isTeacher = false,
  });

  @override
  ConsumerState<_CreatePostForm> createState() => _CreatePostFormState();
}

class _CreatePostFormState extends ConsumerState<_CreatePostForm> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();

  late CommunityPostType _type = widget.initialType;
  HelpCategory? _helpCategory;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _helpCategory = widget.initialHelpCategory;
    if (_type == CommunityPostType.help && _helpCategory == null) {
      _helpCategory = HelpCategory.concept;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      setState(() => _error = 'Write your message before posting.');
      return;
    }
    if (_type == CommunityPostType.announcement && _titleController.text.trim().isEmpty) {
      setState(() => _error = 'An announcement needs a title.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await ref.read(communityActionsProvider).createPost(
            widget.courseId,
            type: _type,
            title: _titleController.text.trim().isEmpty
                ? null
                : _titleController.text.trim(),
            content: content,
            helpCategory:
                _type == CommunityPostType.help && _helpCategory != null
                    ? helpCategoryToApi(_helpCategory!)
                    : null,
            tags: _tagsController.text
                .split(',')
                .map((t) => t.trim())
                .where((t) => t.isNotEmpty)
                .toList(),
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      communitySnack(context, 'Posted to the community');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final types = [
      CommunityPostType.discussion,
      CommunityPostType.question,
      CommunityPostType.help,
      if (widget.isTeacher) CommunityPostType.announcement,
    ];

    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: widget.scrollController,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            children: [
              Text(
                'Post type',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: CT.subTextOf(context),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: types.map((type) {
                  final selected = _type == type;
                  return ChoiceChip(
                    selected: selected,
                    onSelected: (_) => setState(() {
                      _type = type;
                      if (type == CommunityPostType.help && _helpCategory == null) {
                        _helpCategory = HelpCategory.concept;
                      }
                    }),
                    label: Text(switch (type) {
                      CommunityPostType.discussion => 'Discussion',
                      CommunityPostType.question => 'Question',
                      CommunityPostType.help => 'Need help',
                      CommunityPostType.announcement => 'Announcement',
                    }),
                    labelStyle: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : CT.textOf(context),
                    ),
                    selectedColor: CT.primary,
                    backgroundColor: CT.surfaceOf(context),
                    shape: const RoundedRectangleBorder(borderRadius: CT.r12),
                    side: BorderSide(color: CT.borderOf(context)),
                    showCheckmark: false,
                  );
                }).toList(),
              ),
              if (_type == CommunityPostType.help) ...[
                const SizedBox(height: 18),
                Text(
                  'What do you need help with?',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: CT.subTextOf(context),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: HelpCategory.values.map((category) {
                    final selected = _helpCategory == category;
                    return ChoiceChip(
                      selected: selected,
                      onSelected: (_) => setState(() => _helpCategory = category),
                      label: Text(helpCategoryLabel(helpCategoryToApi(category))),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : CT.textOf(context),
                      ),
                      selectedColor: CT.warn,
                      backgroundColor: CT.surfaceOf(context),
                      shape: const RoundedRectangleBorder(borderRadius: CT.r12),
                      side: BorderSide(color: CT.borderOf(context)),
                      showCheckmark: false,
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 18),
              _field(
                controller: _titleController,
                label: _type == CommunityPostType.announcement
                    ? 'Title'
                    : 'Title (optional)',
                hint: switch (_type) {
                  CommunityPostType.question => 'e.g. How do I calculate NPV?',
                  CommunityPostType.announcement => 'e.g. Exam moved to 25 August',
                  _ => 'Give your post a short headline',
                },
              ),
              const SizedBox(height: 14),
              _field(
                controller: _contentController,
                label: 'Message',
                hint: 'Explain what you are trying to understand, and what you '
                    'have already tried.',
                maxLines: 6,
              ),
              const SizedBox(height: 14),
              _field(
                controller: _tagsController,
                label: 'Tags (optional)',
                hint: 'npv, chapter 4, formulas',
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CT.danger.withOpacity(0.08),
                    borderRadius: CT.r12,
                    border: Border.all(color: CT.danger.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 16, color: CT.danger),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(fontSize: 12, color: CT.danger),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        _SheetFooter(
          isBusy: _isSubmitting,
          label: switch (_type) {
            CommunityPostType.question => 'Ask the community',
            CommunityPostType.announcement => 'Publish announcement',
            CommunityPostType.help => 'Request help',
            CommunityPostType.discussion => 'Post discussion',
          },
          onSubmit: _submit,
        ),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return communityTextField(
      context: context,
      controller: controller,
      label: label,
      hint: hint,
      maxLines: maxLines,
    );
  }
}

/// Shared labelled text field for every community composer.
Widget communityTextField({
  required BuildContext context,
  required TextEditingController controller,
  required String label,
  String? hint,
  int maxLines = 1,
  TextInputType? keyboardType,
  bool enabled = true,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: CT.subTextOf(context),
        ),
      ),
      const SizedBox(height: 7),
      TextField(
        controller: controller,
        maxLines: maxLines,
        enabled: enabled,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: 13.5, color: CT.textOf(context)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13, color: CT.textHint),
          filled: true,
          fillColor: CT.cardOf(context),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
    ],
  );
}

/// Sticky submit bar shared by the community sheets.
class _SheetFooter extends StatelessWidget {
  final bool isBusy;
  final String label;
  final VoidCallback onSubmit;

  const _SheetFooter({
    required this.isBusy,
    required this.label,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) => CommunitySheetFooter(
        isBusy: isBusy,
        label: label,
        onSubmit: onSubmit,
      );
}

class CommunitySheetFooter extends StatelessWidget {
  final bool isBusy;
  final String label;
  final VoidCallback onSubmit;

  const CommunitySheetFooter({
    super.key,
    required this.isBusy,
    required this.label,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.of(context).viewInsets.bottom * 0,
      ),
      decoration: BoxDecoration(
        color: CT.cardOf(context),
        border: Border(top: BorderSide(color: CT.borderOf(context))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isBusy ? null : onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: CT.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: CT.primary.withOpacity(0.5),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: const RoundedRectangleBorder(borderRadius: CT.r12),
            ),
            child: isBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
