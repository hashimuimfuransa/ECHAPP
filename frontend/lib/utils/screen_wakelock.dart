import 'package:flutter/widgets.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps the device screen awake while the user is busy with a lesson, so
/// studying is never interrupted by the screen dimming or locking.
///
/// A video player acquires a handle when playback starts and releases it when
/// playback stops (pause, finish, error, or dispose); reading surfaces hold one
/// for as long as they are open - see [KeepScreenAwake]. Handles are reference
/// counted across every instance: a screen that keeps two players alive while
/// switching lessons, or a book opened on top of a playing video, can never let
/// the screen sleep underneath the other one.
class ScreenWakelock {
  ScreenWakelock();

  /// Number of players currently holding the screen awake.
  static int _holders = 0;

  bool _isHolding = false;

  /// Keeps the screen on. Safe to call repeatedly.
  void acquire() {
    if (_isHolding) return;
    _isHolding = true;
    _holders++;
    _sync();
  }

  /// Lets the screen sleep again, once every other holder has released too.
  void release() {
    if (!_isHolding) return;
    _isHolding = false;
    _holders--;
    _sync();
  }

  /// Re-applies our state after a third party has changed the wakelock behind
  /// our back. better_player disables the wakelock every time it leaves full
  /// screen, even when playback carries on inline, which would let the screen
  /// sleep on a video the user is still watching.
  ///
  /// Deferred to the next frame so it lands after the foreign call, since the
  /// platform applies these in the order they are sent.
  static void reassert() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  static void _sync() {
    // Best effort only: the browser can refuse the Screen Wake Lock API and
    // unsupported platforms throw. Neither should ever break playback.
    final Future<void> request =
        _holders > 0 ? WakelockPlus.enable() : WakelockPlus.disable();
    request.catchError((Object error) {
      debugPrint('ScreenWakelock: could not update the screen wakelock: $error');
    });
  }
}

/// Holds the screen awake for as long as [child] is on screen.
///
/// This is for reading surfaces - books, notes, PDFs - where there is no
/// playback state to follow. A reader can go minutes without touching the
/// screen, which is exactly when it would otherwise dim mid-page, so the whole
/// time the reader is open counts as "in use".
///
/// The lock only applies while the app is in the foreground: both Android
/// (a window flag) and iOS (the idle timer) drop it as soon as the app is no
/// longer the visible one, so leaving the app never keeps the screen alive.
class KeepScreenAwake extends StatefulWidget {
  const KeepScreenAwake({super.key, required this.child});

  final Widget child;

  @override
  State<KeepScreenAwake> createState() => _KeepScreenAwakeState();
}

class _KeepScreenAwakeState extends State<KeepScreenAwake> {
  final ScreenWakelock _wakelock = ScreenWakelock();

  @override
  void initState() {
    super.initState();
    _wakelock.acquire();
  }

  @override
  void dispose() {
    _wakelock.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
