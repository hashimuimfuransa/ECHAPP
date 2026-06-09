import 'dart:async';
import 'package:flutter/material.dart';

/// A live-ticking countdown/elapsed timer for live sessions.
///
/// States:
///  - scheduledAt > now          → "Starts in HH:MM:SS" (green→orange→red as time closes)
///  - scheduledAt <= now < end   → "Live · MM:SS elapsed | MM:SS left" (red pulsing)
///  - now >= expectedEnd         → "Session ended" (grey)
class LiveSessionCountdown extends StatefulWidget {
  final DateTime scheduledAt;
  final int durationMinutes;
  final bool isLive;
  final bool compact;

  const LiveSessionCountdown({
    super.key,
    required this.scheduledAt,
    required this.durationMinutes,
    this.isLive = false,
    this.compact = false,
  });

  @override
  State<LiveSessionCountdown> createState() => _LiveSessionCountdownState();
}

class _LiveSessionCountdownState extends State<LiveSessionCountdown>
    with SingleTickerProviderStateMixin {
  Timer? _ticker;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulse = Tween(begin: 0.4, end: 1.0).animate(_pulseCtrl);

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  DateTime get _end =>
      widget.scheduledAt.add(Duration(minutes: widget.durationMinutes));

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final end = _end;

    // ── Session ended ──────────────────────────────────────────
    if (now.isAfter(end)) {
      return _chip(
        icon: Icons.stop_circle_outlined,
        label: 'Session ended',
        color: Colors.grey,
        pulse: false,
      );
    }

    // ── Currently live / started ───────────────────────────────
    if (widget.isLive || now.isAfter(widget.scheduledAt)) {
      final elapsed = now.difference(widget.scheduledAt);
      final remaining = end.difference(now);
      if (widget.compact) {
        return _chip(
          icon: Icons.fiber_manual_record,
          label: '${_fmt(elapsed)} elapsed · ${_fmt(remaining)} left',
          color: Colors.red,
          pulse: true,
        );
      }
      return _splitChip(elapsed: elapsed, remaining: remaining);
    }

    // ── Counting down to start ─────────────────────────────────
    final until = widget.scheduledAt.difference(now);
    final Color color = until.inHours < 1
        ? Colors.red
        : until.inHours < 24
            ? Colors.orange
            : const Color(0xFF00897B);

    return _chip(
      icon: Icons.timer_outlined,
      label: 'Starts in ${_fmt(until)}',
      color: color,
      pulse: false,
    );
  }

  Widget _chip({
    required IconData icon,
    required String label,
    required Color color,
    required bool pulse,
  }) {
    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: widget.compact ? 11 : 12,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );

    if (pulse) {
      content = AnimatedBuilder(
        animation: _pulse,
        builder: (_, child) => Opacity(opacity: _pulse.value, child: child),
        child: content,
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.compact ? 7 : 10,
        vertical: widget.compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: content,
    );
  }

  Widget _splitChip({required Duration elapsed, required Duration remaining}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Elapsed
        _pill(
          icon: Icons.play_circle_outline,
          label: _fmt(elapsed),
          sublabel: 'elapsed',
          color: Colors.red,
          pulse: true,
        ),
        const SizedBox(width: 6),
        // Remaining
        _pill(
          icon: Icons.hourglass_bottom_rounded,
          label: _fmt(remaining),
          sublabel: 'left',
          color: Colors.orange,
          pulse: false,
        ),
      ],
    );
  }

  Widget _pill({
    required IconData icon,
    required String label,
    required String sublabel,
    required Color color,
    required bool pulse,
  }) {
    Widget content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1.1,
                ),
              ),
              Text(
                sublabel,
                style: TextStyle(
                  fontSize: 9,
                  color: color.withOpacity(0.8),
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (pulse) {
      return AnimatedBuilder(
        animation: _pulse,
        builder: (_, child) => Opacity(opacity: _pulse.value, child: child),
        child: content,
      );
    }
    return content;
  }

  String _fmt(Duration d) {
    if (d.inSeconds < 0) return '00:00';
    if (d.inHours > 0) {
      return '${d.inHours.toString().padLeft(2, '0')}'
          ':${(d.inMinutes % 60).toString().padLeft(2, '0')}'
          ':${(d.inSeconds % 60).toString().padLeft(2, '0')}';
    }
    return '${d.inMinutes.toString().padLeft(2, '0')}'
        ':${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }
}
