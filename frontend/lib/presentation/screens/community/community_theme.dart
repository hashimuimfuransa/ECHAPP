import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';

import '../../../models/community.dart';

/// Design tokens and small shared widgets for the Course Community.
///
/// The palette intentionally mirrors the professional learning screen so the
/// Community tab does not read as a bolted-on module.
class CT {
  // Brand
  static const primary = Color(0xFF00C853);
  static const primaryDim = Color(0xFF00A846);
  static const accent = Color(0xFF7C4DFF);
  static const info = Color(0xFF3B82F6);
  static const warn = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const teacher = Color(0xFF7C4DFF);

  static const List<Color> heroGrad = [Color(0xFF00C853), Color(0xFF00897B)];
  static const List<Color> purpleGrad = [Color(0xFF7C4DFF), Color(0xFF5C35E0)];

  // Surfaces
  static const bg = Color(0xFFF7F8FC);
  static const bgDark = Color(0xFF111522);
  static const card = Colors.white;
  static const cardDark = Color(0xFF1C2333);
  static const surface = Color(0xFFF0F2F8);
  static const surfaceDark = Color(0xFF242C42);

  // Text
  static const textPrimary = Color(0xFF0D1117);
  static const textSecondary = Color(0xFF6B7280);
  static const textHint = Color(0xFFADB5BD);

  // Borders
  static const border = Color(0xFFE5E9F2);
  static const borderDark = Color(0xFF2D3748);

  static const r8 = BorderRadius.all(Radius.circular(8));
  static const r12 = BorderRadius.all(Radius.circular(12));
  static const r16 = BorderRadius.all(Radius.circular(16));
  static const r20 = BorderRadius.all(Radius.circular(20));

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color bgOf(BuildContext c) => isDark(c) ? bgDark : bg;
  static Color cardOf(BuildContext c) => isDark(c) ? cardDark : card;
  static Color surfaceOf(BuildContext c) => isDark(c) ? surfaceDark : surface;
  static Color borderOf(BuildContext c) => isDark(c) ? borderDark : border;
  static Color textOf(BuildContext c) => isDark(c) ? Colors.white : textPrimary;
  static Color subTextOf(BuildContext c) =>
      isDark(c) ? Colors.white70 : textSecondary;

  static List<BoxShadow> shadowOf(BuildContext c) => isDark(c)
      ? const []
      : [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ];

  /// Stable per-person colour so the same student always gets the same avatar.
  static Color avatarColor(String seed) {
    const palette = [
      Color(0xFF00C853),
      Color(0xFF7C4DFF),
      Color(0xFF3B82F6),
      Color(0xFFF59E0B),
      Color(0xFFEC4899),
      Color(0xFF06B6D4),
      Color(0xFF8B5CF6),
      Color(0xFF10B981),
    ];
    if (seed.isEmpty) return palette.first;
    var hash = 0;
    for (final unit in seed.codeUnits) {
      hash = (hash * 31 + unit) & 0x7FFFFFFF;
    }
    return palette[hash % palette.length];
  }

  /// "2 min ago" / "3 days ago" — used across posts, chat and resources.
  ///
  /// These take a BuildContext so every relative date reads in the viewer's
  /// language; there is no sensible way to localise a static helper otherwise.
  static String timeAgo(BuildContext context, DateTime? date) {
    if (date == null) return '';
    final l10n = AppLocalizations.of(context)!;
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return l10n.justNow;
    if (diff.inMinutes < 60) {
      return l10n.timeMinutesShort(diff.inMinutes.toString());
    }
    if (diff.inHours < 24) return l10n.timeHoursShort(diff.inHours.toString());
    if (diff.inDays < 7) return l10n.timeDaysShort(diff.inDays.toString());
    if (diff.inDays < 30) {
      return l10n.timeWeeksShort((diff.inDays / 7).floor().toString());
    }
    return l10n.timeMonthsShort((diff.inDays / 30).floor().toString());
  }

  static List<String> _months(AppLocalizations l10n) => [
        l10n.monthJan, l10n.monthFeb, l10n.monthMar, l10n.monthApr,
        l10n.monthMay, l10n.monthJun, l10n.monthJul, l10n.monthAug,
        l10n.monthSep, l10n.monthOct, l10n.monthNov, l10n.monthDec,
      ];

  static String formatDate(BuildContext context, DateTime? date) {
    if (date == null) return '—';
    final months = _months(AppLocalizations.of(context)!);
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  static String formatDateTime(BuildContext context, DateTime? date) {
    if (date == null) return '—';
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '${formatDate(context, date)} · $h:$m';
  }

  /// Days-until phrasing for assignment deadlines.
  static String dueLabel(BuildContext context, DateTime? due) {
    final l10n = AppLocalizations.of(context)!;
    if (due == null) return l10n.noDeadline;
    final diff = due.difference(DateTime.now());
    if (diff.isNegative) {
      final days = (-diff.inDays);
      if (days == 0) return l10n.dueTodayPassed;
      return l10n.overdueByDays(days.toString());
    }
    if (diff.inHours < 24) return l10n.dueInHours(diff.inHours.toString());
    if (diff.inDays == 1) return l10n.dueTomorrow;
    if (diff.inDays < 7) return l10n.dueInDays(diff.inDays.toString());
    return l10n.dueOn(formatDate(context, due));
  }
}

// ─────────────────────────────────────────────
//  Shared widgets
// ─────────────────────────────────────────────

/// Avatar with an optional presence ring/dot and a teacher badge.
class MemberAvatar extends StatelessWidget {
  final CommunityMember member;
  final double size;
  final bool showPresence;

  const MemberAvatar({
    super.key,
    required this.member,
    this.size = 44,
    this.showPresence = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = CT.avatarColor(member.id.isEmpty ? member.fullName : member.id);
    final hasPhoto = member.avatar != null && member.avatar!.isNotEmpty;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: hasPhoto
                  ? null
                  : LinearGradient(
                      colors: [color, color.withOpacity(0.72)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              border: member.isTeacher
                  ? Border.all(color: CT.teacher, width: 2)
                  : null,
            ),
            clipBehavior: Clip.antiAlias,
            child: hasPhoto
                ? Image.network(
                    member.avatar!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _initials(color),
                  )
                : _initials(color),
          ),
          if (showPresence && member.presence.isActive)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: size * 0.28,
                height: size * 0.28,
                decoration: BoxDecoration(
                  color: CT.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: CT.cardOf(context), width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _initials(Color color) => Container(
        alignment: Alignment.center,
        color: member.avatar != null ? color : null,
        child: Text(
          member.initials,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: size * 0.36,
          ),
        ),
      );
}

/// The pill that reads "👨‍🏫 Teacher" next to an official answer.
class TeacherBadge extends StatelessWidget {
  final String label;
  const TeacherBadge({super.key, this.label = 'Teacher'});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: CT.teacher.withOpacity(0.12),
        borderRadius: CT.r8,
        border: Border.all(color: CT.teacher.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.school_rounded, size: 12, color: CT.teacher),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: CT.teacher,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class CommunityChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final bool filled;

  const CommunityChip({
    super.key,
    required this.label,
    this.icon,
    this.color = CT.primary,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? color : color.withOpacity(0.1),
        borderRadius: CT.r8,
        border: filled ? null : Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: filled ? Colors.white : color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: filled ? Colors.white : color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section title with an optional trailing action ("View all", "+ Create").
class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: CT.primary.withOpacity(0.1),
            borderRadius: CT.r12,
          ),
          child: Icon(icon, size: 18, color: CT.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: CT.textOf(context),
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: TextStyle(fontSize: 11.5, color: CT.subTextOf(context)),
                ),
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: CT.primary,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel!,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }
}

class CommunityCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? accent;

  const CommunityCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CT.cardOf(context),
      borderRadius: CT.r16,
      child: InkWell(
        onTap: onTap,
        borderRadius: CT.r16,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: CT.r16,
            border: Border.all(
              color: accent?.withOpacity(0.3) ?? CT.borderOf(context),
            ),
            boxShadow: CT.shadowOf(context),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Consistent empty state with an optional call to action.
class CommunityEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  const CommunityEmpty({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 28,
          vertical: compact ? 20 : 44,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: compact ? 54 : 76,
              height: compact ? 54 : 76,
              decoration: BoxDecoration(
                color: CT.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: compact ? 26 : 36, color: CT.primary),
            ),
            SizedBox(height: compact ? 12 : 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: compact ? 14 : 16.5,
                fontWeight: FontWeight.w800,
                color: CT.textOf(context),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.5,
                color: CT.subTextOf(context),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CT.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: const RoundedRectangleBorder(borderRadius: CT.r12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CommunityErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const CommunityErrorView({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 44, color: CT.textHint),
            const SizedBox(height: 14),
            Text(
              'Could not load the community',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: CT.textOf(context),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _friendly(error),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: CT.subTextOf(context)),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try again'),
              style: OutlinedButton.styleFrom(
                foregroundColor: CT.primary,
                side: const BorderSide(color: CT.primary),
                shape: const RoundedRectangleBorder(borderRadius: CT.r12),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Strips the exception noise so students see a sentence, not a stack trace.
  static String _friendly(Object error) {
    final text = error.toString().replaceFirst('Exception: ', '');
    if (text.contains('enrolled in this course')) {
      return 'You need to be enrolled in this course to join its community.';
    }
    if (text.length > 160) return 'Something went wrong. Please try again.';
    return text;
  }
}

/// Small stat used in the community header ("47 students", "12 active").
class CommunityStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const CommunityStat({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.color = CT.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: CT.r8,
          ),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                height: 1.1,
                color: CT.textOf(context),
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10.5, color: CT.subTextOf(context)),
            ),
          ],
        ),
      ],
    );
  }
}

/// Round quick-action button used in the community header row.
class CommunityAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final int badge;

  const CommunityAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = CT.primary,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: CT.r12,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: CT.r12,
                  ),
                  child: Icon(icon, size: 21, color: color),
                ),
                if (badge > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      constraints: const BoxConstraints(minWidth: 18),
                      decoration: BoxDecoration(
                        color: CT.danger,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: CT.cardOf(context), width: 1.5),
                      ),
                      child: Text(
                        badge > 99 ? '99+' : '$badge',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 66,
              // Labels are deliberately two words on two lines ("Find\nstudents").
              // maxLines: 1 was clipping every one of them to the first word,
              // leaving "Ask a" and "Course" on screen.
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  height: 1.25,
                  fontWeight: FontWeight.w700,
                  color: CT.textOf(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Overlapping avatar stack for group member previews.
class MemberStack extends StatelessWidget {
  final List<CommunityMember> members;
  final int max;
  final double size;

  const MemberStack({
    super.key,
    required this.members,
    this.max = 4,
    this.size = 26,
  });

  /// How far each avatar slides over the one before it.
  static const double _overlap = 8;

  @override
  Widget build(BuildContext context) {
    final shown = members.take(max).toList();
    final extra = members.length - shown.length;
    final tiles = shown.length + (extra > 0 ? 1 : 0);
    if (tiles == 0) return const SizedBox.shrink();

    // Laid out with a Stack rather than negative margins — Container asserts
    // that margins are non-negative, so overlap has to come from positioning.
    final step = size - _overlap;

    return SizedBox(
      width: size + (tiles - 1) * step,
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * step,
              child: _ring(
                context,
                MemberAvatar(
                  member: shown[i],
                  size: size - 4,
                  showPresence: false,
                ),
              ),
            ),
          if (extra > 0)
            Positioned(
              left: shown.length * step,
              child: _ring(
                context,
                Container(
                  width: size - 4,
                  height: size - 4,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: CT.surfaceOf(context),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '+$extra',
                    style: TextStyle(
                      fontSize: size * 0.3,
                      fontWeight: FontWeight.w800,
                      color: CT.subTextOf(context),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Card-coloured ring that separates one avatar from the one it overlaps.
  Widget _ring(BuildContext context, Widget child) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: CT.cardOf(context),
          shape: BoxShape.circle,
        ),
        child: child,
      );
}

/// Standard bottom-sheet frame used by every community composer.
Future<T?> showCommunitySheet<T>({
  required BuildContext context,
  required String title,
  required Widget Function(BuildContext, ScrollController) builder,
  double initialSize = 0.72,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: initialSize,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (sheetCtx, controller) => Container(
        decoration: BoxDecoration(
          color: CT.bgOf(sheetCtx),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: CT.borderOf(sheetCtx),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 2, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: CT.textOf(sheetCtx),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(sheetCtx).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: CT.subTextOf(sheetCtx),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: CT.borderOf(sheetCtx)),
            Expanded(child: builder(sheetCtx, controller)),
          ],
        ),
      ),
    ),
  );
}

/// Opens an external link (a meeting room, a recording, a shared resource).
///
/// On web a `launchUrl` call that happens *after* an await has lost the
/// browser's user-activation, so popup blockers silently swallow it. When the
/// launch fails we surface a dialog whose button re-launches from a fresh tap,
/// which always gets through.
Future<void> openExternalLink(
  BuildContext context,
  String url, {
  String title = 'Open link',
  String actionLabel = 'Open',
  String? description,
}) async {
  final uri = Uri.tryParse(url);
  if (uri == null || url.isEmpty) {
    communitySnack(context, 'That link looks broken', isError: true);
    return;
  }

  var launched = false;
  try {
    launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    launched = false;
  }
  if (launched || !context.mounted) return;

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      shape: const RoundedRectangleBorder(borderRadius: CT.r16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            description ??
                'Your browser blocked the automatic redirect. Tap below to '
                    'open it.',
            style: TextStyle(fontSize: 13, height: 1.45, color: CT.subTextOf(ctx)),
          ),
          const SizedBox(height: 14),
          SelectableText(
            url,
            style: const TextStyle(fontSize: 11, color: CT.info),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(ctx).pop();
            // Fired straight from this tap, so user-activation is intact.
            launchUrl(uri, mode: LaunchMode.externalApplication);
          },
          icon: const Icon(Icons.open_in_new_rounded, size: 16),
          label: Text(actionLabel),
          style: ElevatedButton.styleFrom(
            backgroundColor: CT.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: const RoundedRectangleBorder(borderRadius: CT.r12),
          ),
        ),
      ],
    ),
  );
}

/// Consistent inline snack feedback.
void communitySnack(BuildContext context, String message, {bool isError = false}) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? CT.danger : CT.primaryDim,
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(borderRadius: CT.r12),
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 3),
    ),
  );
}
