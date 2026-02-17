import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class CountdownTimer extends StatefulWidget {
  final DateTime? expirationDate;
  final VoidCallback? onExpiration;

  const CountdownTimer({
    Key? key,
    this.expirationDate,
    this.onExpiration,
  }) : super(key: key);

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Timer _timer;
  Duration? _remainingTime;

  @override
  void initState() {
    super.initState();
    _calculateRemainingTime();

    if (_remainingTime != null && _remainingTime!.inSeconds > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _calculateRemainingTime();
        if (_remainingTime != null && _remainingTime!.inSeconds <= 0) {
          if (widget.onExpiration != null) {
            widget.onExpiration!();
          }
          timer.cancel();
        }
      });
    }
  }

  void _calculateRemainingTime() {
    if (widget.expirationDate != null) {
      final now = DateTime.now();
      final expiration = widget.expirationDate!;
      
      if (expiration.isAfter(now)) {
        final difference = expiration.difference(now);
        setState(() {
          _remainingTime = difference;
        });
      } else {
        setState(() {
          _remainingTime = const Duration(seconds: 0);
          if (widget.onExpiration != null) {
            widget.onExpiration!();
          }
        });
      }
    } else {
      setState(() {
        _remainingTime = null;
      });
    }
  }

  @override
  void didUpdateWidget(CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expirationDate != widget.expirationDate) {
      _calculateRemainingTime();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_remainingTime == null) {
      return Container();
    }

    if (_remainingTime!.inSeconds <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade300),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.block, color: Colors.red, size: 16),
            SizedBox(width: 4),
            Text(
              'Access Expired',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    // Format the remaining time
    String formattedTime = _formatDuration(_remainingTime!);

    Color textColor = Colors.black87;
    Color bgColor = Colors.green.shade50;
    Color borderColor = Colors.green.shade200;

    // Change color if less than 7 days remaining
    if (_remainingTime!.inDays < 7) {
      textColor = Colors.orange[700]!;
      bgColor = Colors.orange.shade50;
      borderColor = Colors.orange.shade200;
    }

    // Change color if less than 1 day remaining
    if (_remainingTime!.inHours < 24) {
      textColor = Colors.red[700]!;
      bgColor = Colors.red.shade50;
      borderColor = Colors.red.shade200;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer, color: textColor, size: 16),
          const SizedBox(width: 4),
          Text(
            'Expires in: $formattedTime',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}