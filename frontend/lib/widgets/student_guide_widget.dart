import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:rive/rive.dart' as rive;
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'dart:math' as math;

// ─────────────────────────────────────────────
//  STATE ENUM
// ─────────────────────────────────────────────
enum StudentGuideState {
  greeting,
  thinking,
  success,
  cheer,
  idle,
  disappointed,
  encouraging,
  levelUp,
  streakAlert,
  hintReady,
}

// ─────────────────────────────────────────────
//  CHARACTER THEMES
// ─────────────────────────────────────────────
enum GuideCharacter { greeter, guide }

// ─────────────────────────────────────────────
//  DATA MODELS
// ─────────────────────────────────────────────
class GuideConfig {
  final GuideCharacter character;
  final double size;
  final bool enableSound;
  final bool enableParticles;
  final Color primaryColor;
  final Color accentColor;
  final bool isAiMode;

  const GuideConfig({
    this.character = GuideCharacter.guide,
    this.size = 150,
    this.enableSound = true,
    this.enableParticles = true,
    this.primaryColor = const Color(0xFF58CC02),
    this.accentColor = const Color(0xFFFFD900),
    this.isAiMode = false,
  });
}

// ─────────────────────────────────────────────
//  PARTICLE MODEL
// ─────────────────────────────────────────────
class _Particle {
  double x, y, vx, vy, opacity, scale, rotation;
  Color color;
  bool isEmoji;
  String? emoji;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.opacity,
    required this.scale,
    required this.rotation,
    required this.color,
    this.isEmoji = false,
    this.emoji,
  });
}

// ─────────────────────────────────────────────
//  PARTICLE PAINTER
// ─────────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  _ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      if (p.isEmoji && p.emoji != null) continue; // drawn by widget layer
      final paint = Paint()
        ..color = p.color.withOpacity(p.opacity.clamp(0, 1))
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);
      canvas.scale(p.scale);

      // Draw star
      final path = Path();
      for (int i = 0; i < 5; i++) {
        final angle = (i * 4 * math.pi / 5) - math.pi / 2;
        final r = i == 0 ? 8.0 : 8.0;
        final innerR = 3.5;
        final outerAngle = angle;
        final innerAngle = angle + math.pi / 5;
        if (i == 0) {
          path.moveTo(math.cos(outerAngle) * r, math.sin(outerAngle) * r);
        } else {
          path.lineTo(math.cos(outerAngle) * r, math.sin(outerAngle) * r);
        }
        path.lineTo(
          math.cos(innerAngle) * innerR,
          math.sin(innerAngle) * innerR,
        );
      }
      path.close();
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}

// ─────────────────────────────────────────────
//  SPEECH BUBBLE PAINTER
// ─────────────────────────────────────────────
class _BubblePainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  _BubblePainter({required this.color, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill;
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const r = 12.0;
    const tailW = 16.0;
    const tailH = 10.0;

    final borderPath = _buildBubblePath(size, r, tailW, tailH, 2.5);
    canvas.drawPath(borderPath, borderPaint);

    final fillPath = _buildBubblePath(size, r, tailW, tailH, 0);
    canvas.drawPath(fillPath, fillPaint);
  }

  Path _buildBubblePath(
      Size size, double r, double tailW, double tailH, double inset) {
    final w = size.width - inset * 2;
    final h = size.height - inset * 2 - tailH;
    final ox = inset;
    final oy = inset;

    return Path()
      ..moveTo(ox + r, oy)
      ..lineTo(ox + w - r, oy)
      ..quadraticBezierTo(ox + w, oy, ox + w, oy + r)
      ..lineTo(ox + w, oy + h - r)
      ..quadraticBezierTo(ox + w, oy + h, ox + w - r, oy + h)
      ..lineTo(ox + w / 2 + tailW / 2, oy + h)
      ..lineTo(ox + w / 2, oy + h + tailH)
      ..lineTo(ox + w / 2 - tailW / 2, oy + h)
      ..lineTo(ox + r, oy + h)
      ..quadraticBezierTo(ox, oy + h, ox, oy + h - r)
      ..lineTo(ox, oy + r)
      ..quadraticBezierTo(ox, oy, ox + r, oy)
      ..close();
  }

  @override
  bool shouldRepaint(_BubblePainter old) =>
      old.color != color || old.borderColor != borderColor;
}

// ─────────────────────────────────────────────
//  XP BAR WIDGET
// ─────────────────────────────────────────────
class XPBar extends StatefulWidget {
  final int current;
  final int max;
  final Color color;
  final bool isMobile;
  const XPBar(
      {super.key,
      required this.current,
      required this.max,
      required this.color,
      this.isMobile = false});

  @override
  State<XPBar> createState() => _XPBarState();
}

class _XPBarState extends State<XPBar> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutExpo);
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(XPBar old) {
    super.didUpdateWidget(old);
    if (old.current != widget.current) _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pct = (widget.current / widget.max).clamp(0.0, 1.0);
    final barHeight = widget.isMobile ? 6.0 : 10.0;
    final fontSize = widget.isMobile ? 8.0 : 10.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('⚡ XP',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: fontSize,
                    color: widget.color)),
            Flexible(
              child: Text('${widget.current}/${widget.max}',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: fontSize,
                      color: widget.color),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        SizedBox(height: widget.isMobile ? 2 : 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => Stack(
              children: [
                Container(
                    height: barHeight,
                    width: double.infinity,
                    color: widget.color.withOpacity(0.15)),
                FractionallySizedBox(
                  widthFactor: pct * _anim.value,
                  child: Container(
                    height: barHeight,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [widget.color, widget.color.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                            color: widget.color.withOpacity(0.5),
                            blurRadius: 6,
                            spreadRadius: 0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  MAIN GUIDE WIDGET
// ─────────────────────────────────────────────
class StudentGuideWidget extends StatefulWidget {
  final StudentGuideState initialState;
  final String? message;
  final bool autoDismiss;
  final VoidCallback? onDismiss;
  final VoidCallback? onTap;
  final GuideConfig config;
  final int xp;
  final int maxXp;
  final int streak;

  const StudentGuideWidget({
    super.key,
    this.initialState = StudentGuideState.greeting,
    this.message,
    this.autoDismiss = false,
    this.onDismiss,
    this.onTap,
    this.config = const GuideConfig(),
    this.xp = 0,
    this.maxXp = 100,
    this.streak = 0,
  });

  @override
  State<StudentGuideWidget> createState() => StudentGuideWidgetState();
}

class StudentGuideWidgetState extends State<StudentGuideWidget>
    with TickerProviderStateMixin {
  late StudentGuideState _state;
  late AudioPlayer _audio;
  String? _msg;
  bool _visible = true;
  final _rng = math.Random();

  // ── rive controllers ──────────────────────────
  rive.RiveWidgetController? _riveController;
  rive.BooleanInput? _talking;
  rive.BooleanInput? _thinking;
  rive.BooleanInput? _celebrating;
  rive.BooleanInput? _disappointed;
  rive.BooleanInput? _idle;
  rive.BooleanInput? _hover;
  rive.BooleanInput? _waving;

  // ── core animations ──────────────────────────
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  late AnimationController _bubbleCtrl;
  late Animation<double> _bubbleAnim;

  // ── particles ────────────────────────────────
  late AnimationController _particleCtrl;
  final List<_Particle> _particles = [];
  Timer? _particleTick;

  // ── idle / dismiss timers ────────────────────
  Timer? _idleTimer;
  Timer? _dismissTimer;

  static const Map<GuideCharacter, String> _riveUrls = {
    GuideCharacter.greeter: 'assets/24247-45305-cashy-character.riv',
    GuideCharacter.guide: 'assets/24247-45305-cashy-character.riv',
  };

  // ── state meta ───────────────────────────────
  static const Map<StudentGuideState, _StateMeta> _meta = {
    StudentGuideState.greeting: _StateMeta(
        emoji: '👋',
        label: 'Hello!',
        gradient: [Color(0xFF58CC02), Color(0xFF89E219)],
        border: Color(0xFF47A302)),
    StudentGuideState.thinking: _StateMeta(
        emoji: '🤔',
        label: 'Thinking…',
        gradient: [Color(0xFF1CB0F6), Color(0xFF4DD8FF)],
        border: Color(0xFF0D9AD6)),
    StudentGuideState.success: _StateMeta(
        emoji: '🏆',
        label: 'Amazing!',
        gradient: [Color(0xFFFFD900), Color(0xFFFFB800)],
        border: Color(0xFFD4A000)),
    StudentGuideState.cheer: _StateMeta(
        emoji: '🎉',
        label: 'You rock!',
        gradient: [Color(0xFFFF4B4B), Color(0xFFFF8080)],
        border: Color(0xFFCC0000)),
    StudentGuideState.idle: _StateMeta(
        emoji: '😊',
        label: "I'm here!",
        gradient: [Color(0xFF8549BA), Color(0xFFB07FE0)],
        border: Color(0xFF6A3A99)),
    StudentGuideState.disappointed: _StateMeta(
        emoji: '😔',
        label: 'Try again!',
        gradient: [Color(0xFFFF9600), Color(0xFFFFB347)],
        border: Color(0xFFCC7A00)),
    StudentGuideState.encouraging: _StateMeta(
        emoji: '💪',
        label: 'Keep going!',
        gradient: [Color(0xFF58CC02), Color(0xFF89E219)],
        border: Color(0xFF47A302)),
    StudentGuideState.levelUp: _StateMeta(
        emoji: '🚀',
        label: 'Level Up!',
        gradient: [Color(0xFFFFD900), Color(0xFFFF6B00)],
        border: Color(0xFFD4A000)),
    StudentGuideState.streakAlert: _StateMeta(
        emoji: '🔥',
        label: 'On fire!',
        gradient: [Color(0xFFFF4B4B), Color(0xFFFF8C00)],
        border: Color(0xFFCC0000)),
    StudentGuideState.hintReady: _StateMeta(
        emoji: '💡',
        label: 'Hint ready!',
        gradient: [Color(0xFF1CB0F6), Color(0xFF89E219)],
        border: Color(0xFF0D9AD6)),
  };

  // ── tap messages ─────────────────────────────
  static const List<String> _tapMessages = [
    "Hey, that tickles! 😄",
    "Haha, stop it! 😆",
    "Focus, we're learning! 📚",
    "You're so curious! 🧐",
    "Save that energy for the quiz! 💪",
    "I like you too! 🥰",
  ];

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
    _msg = widget.message;
    _audio = AudioPlayer();

    _setupAnimations();
    _fadeCtrl.forward();
    _resetIdleTimer();
    if (widget.autoDismiss) _scheduleDismiss();
  }

  void _setupAnimations() {
    // fade
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim =
        CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);

    // entrance scale
    _scaleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnim = CurvedAnimation(
        parent: _scaleCtrl, curve: Curves.elasticOut);
    _scaleCtrl.forward();

    // bubble pop
    _bubbleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _bubbleAnim = CurvedAnimation(
        parent: _bubbleCtrl, curve: Curves.elasticOut);
    if (_msg != null) _bubbleCtrl.forward();

    // particles
    _particleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 16));
  }

  // ── PUBLIC API ────────────────────────────────

  void updateState(StudentGuideState state,
      {String? message, bool autoDismiss = false}) {
    if (!mounted) return;
    _dismissTimer?.cancel();
    setState(() {
      _state = state;
      _msg = message;
      _visible = true;
    });
    _scaleCtrl.forward(from: 0);
    if (message != null) {
      _bubbleCtrl.forward(from: 0);
    } else {
      _bubbleCtrl.reverse();
    }
    if (state == StudentGuideState.success ||
        state == StudentGuideState.cheer ||
        state == StudentGuideState.levelUp) {
      _spawnParticles();
    }
    _resetIdleTimer();
    if (autoDismiss) _scheduleDismiss();
    _updateRiveState();
  }

  void showMessage(String message, {Duration? duration}) {
    if (!mounted) return;
    setState(() => _msg = message);
    _bubbleCtrl.forward(from: 0);
    if (duration != null) {
      Timer(duration, () {
        if (mounted) {
          _bubbleCtrl.reverse().then((_) {
            if (mounted) setState(() => _msg = null);
          });
        }
      });
    }
  }

  void celebrateSuccess({String? message}) {
    updateState(StudentGuideState.success,
        message: message ?? '🎉 Excellent work!', autoDismiss: false);
    _spawnParticles();
  }

  void showDisappointment({String? message}) {
    updateState(StudentGuideState.disappointed,
        message: message ?? "Don't give up! Try again 💪");
  }

  void triggerLevelUp(int level) {
    updateState(StudentGuideState.levelUp,
        message: '🚀 LEVEL $level UNLOCKED!', autoDismiss: false);
    _spawnParticles(count: 60);
  }

  // ── PARTICLES ─────────────────────────────────

  void _spawnParticles({int count = 30}) {
    if (!widget.config.enableParticles) return;
    final size = _getResponsiveSize();
    final cx = (size + (MediaQuery.of(context).size.width < 600 ? 10 : 40)) / 2;
    final cy = (size + (MediaQuery.of(context).size.width < 600 ? 10 : 40)) / 2;
    final colors = [
      widget.config.primaryColor,
      widget.config.accentColor,
      Colors.pinkAccent,
      Colors.purpleAccent,
      const Color(0xFF1CB0F6),
    ];
    for (int i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * math.pi * 2;
      final speed = 2 + _rng.nextDouble() * 5;
      _particles.add(_Particle(
        x: cx,
        y: cy,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed - 4,
        opacity: 1.0,
        scale: 0.5 + _rng.nextDouble() * 1.0,
        rotation: _rng.nextDouble() * math.pi * 2,
        color: colors[_rng.nextInt(colors.length)],
      ));
    }
    _particleTick?.cancel();
    _particleTick =
        Timer.periodic(const Duration(milliseconds: 16), (_) => _tickParticles());
  }

  void _tickParticles() {
    if (!mounted) return;
    bool any = false;
    for (final p in _particles) {
      p.x += p.vx;
      p.y += p.vy;
      p.vy += 0.18; // gravity
      p.opacity -= 0.02;
      p.rotation += 0.08;
      if (p.opacity > 0) any = true;
    }
    _particles.removeWhere((p) => p.opacity <= 0);
    if (!any) {
      _particleTick?.cancel();
      _particleTick = null;
    }
    if (mounted) setState(() {});
  }

  // ── TIMERS ────────────────────────────────────

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    if (_state == StudentGuideState.idle) return;
    _idleTimer = Timer(const Duration(seconds: 40), () {
      if (mounted && _visible) {
        updateState(StudentGuideState.idle, message: "Need a hint? I'm here! 💡");
      }
    });
  }

  void _scheduleDismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) _fadeOut();
    });
  }

  void _fadeOut() {
    _idleTimer?.cancel();
    _dismissTimer?.cancel();
    _fadeCtrl.reverse().then((_) {
      if (mounted) {
        setState(() => _visible = false);
        widget.onDismiss?.call();
      }
    });
  }

  // ── TAP HANDLER ───────────────────────────────

  void _onTap() {
    if (widget.onTap != null) {
      widget.onTap!();
      return;
    }
    final msgs = _tapMessages;
    final msg = msgs[_rng.nextInt(msgs.length)];
    updateState(StudentGuideState.cheer, message: msg, autoDismiss: true);
  }

  // ── HELPERS ───────────────────────────────────

  String get _riveUrl =>
      _riveUrls[widget.config.character] ??
      _riveUrls[GuideCharacter.guide]!;

  double _getResponsiveSize() {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) return widget.config.size * 0.45;
    if (screenWidth < 1024) return widget.config.size * 0.75;
    return widget.config.size;
  }

  _StateMeta get _currentMeta => _meta[_state]!;

  @override
  void dispose() {
    _idleTimer?.cancel();
    _dismissTimer?.cancel();
    _particleTick?.cancel();
    _audio.dispose();
    for (final ctrl in [
      _fadeCtrl,
      _scaleCtrl,
      _bubbleCtrl,
      _particleCtrl,
    ]) {
      ctrl.dispose();
    }
    super.dispose();
  }

  // ── BUILD ─────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    final meta = _currentMeta;
    final size = _getResponsiveSize();
    final isMobile = MediaQuery.of(context).size.width < 600;
    final primary = meta.gradient[0];
    final border = meta.border;
    final containerSize = size + (isMobile ? 10 : 80);

    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isMobile ? 120 : 280,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Speech bubble ──────────────────────
              if (_msg != null) _buildBubble(meta, primary, border, isMobile),

              // ── Character + particles ──────────────
              SizedBox(
                width: containerSize,
                height: containerSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Particle layer (behind)
                    if (_particles.isNotEmpty)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _ParticlePainter(List.from(_particles)),
                        ),
                      ),

                    // Character
                    _buildCharacterCard(meta, size, primary, border),
                  ],
                ),
              ),

              // ── Stats row ─────────────────────────
              _buildStatsRow(primary, isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBubble(_StateMeta meta, Color primary, Color border, bool isMobile) {
    return ScaleTransition(
      scale: _bubbleAnim,
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(bottom: isMobile ? 2 : 4),
        child: CustomPaint(
          painter: _BubblePainter(
            color: _bubbleBackground(meta),
            borderColor: border,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isMobile ? 110 : 220,
            ),
            padding: EdgeInsets.fromLTRB(
              isMobile ? 8 : 12,
              isMobile ? 4 : 8,
              isMobile ? 8 : 12,
              isMobile ? 14 : 20,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(meta.emoji,
                    style: TextStyle(fontSize: isMobile ? 10 : 16)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _msg!,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: isMobile ? 8 : 10.5,
                      height: 1.1,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _bubbleBackground(_StateMeta meta) {
    final isDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    return isDark ? const Color(0xFF1F1F2E) : Colors.white;
  }

  Widget _buildCharacterCard(
      _StateMeta meta, double size, Color primary, Color border) {
    // Check if we're on Windows where Rive might cause crashes
    final bool isWindows = !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

    return GestureDetector(
      onTap: _onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.config.isAiMode)
            Container(
              width: size * 0.8,
              height: size * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primary.withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),
          SizedBox(
            width: size,
            height: size,
            child: isWindows 
              ? _buildStaticFallback(meta, size, primary)
              : _buildRiveCharacter(size),
          ),
        ],
      ),
    );
  }

  Widget _buildStaticFallback(_StateMeta meta, double size, Color primary) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          meta.emoji,
          style: TextStyle(fontSize: size * 0.5),
        ),
      ),
    );
  }

  Widget _buildRiveCharacter(double size) {
    try {
      return rive.RiveWidgetBuilder(
        fileLoader: rive.FileLoader.fromAsset(_riveUrl,
            riveFactory: rive.Factory.rive),
        onLoaded: _onRiveLoaded,
        builder: (context, state) {
          if (state is rive.RiveLoaded) {
            return rive.RiveWidget(
              controller: state.controller,
              fit: rive.Fit.contain,
            );
          } else if (state is rive.RiveFailed) {
            return const Center(
                child: Icon(Icons.error_outline, color: Colors.red));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      );
    } catch (e) {
      print('Rive loading error caught: $e');
      return const Center(child: Icon(Icons.error_outline, color: Colors.red));
    }
  }

  void _onRiveLoaded(rive.RiveLoaded loaded) {
    _riveController = loaded.controller;
    final stateMachine = _riveController!.stateMachine;
    _talking = stateMachine.boolean('talking') ?? stateMachine.boolean('talk');
    _thinking = stateMachine.boolean('thinking') ?? stateMachine.boolean('think');
    _celebrating = stateMachine.boolean('celebrating') ?? stateMachine.boolean('celebrate') ?? stateMachine.boolean('success');
    _disappointed = stateMachine.boolean('disappointed') ?? stateMachine.boolean('fail') ?? stateMachine.boolean('sad');
    _idle = stateMachine.boolean('idle');
    _hover = stateMachine.boolean('hover');
    _waving = stateMachine.boolean('waving') ?? stateMachine.boolean('wave');
    _updateRiveState();
  }

  void _updateRiveState() {
    if (_riveController == null) return;
    _talking?.value = _state == StudentGuideState.greeting || _state == StudentGuideState.cheer || _state == StudentGuideState.encouraging;
    _thinking?.value = _state == StudentGuideState.thinking;
    _celebrating?.value = _state == StudentGuideState.success || _state == StudentGuideState.levelUp;
    _disappointed?.value = _state == StudentGuideState.disappointed;
    _idle?.value = true;
    _hover?.value = _state == StudentGuideState.greeting || _state == StudentGuideState.cheer;
    _waving?.value = _state == StudentGuideState.greeting;
  }

  Widget _buildStatsRow(Color primary, bool isMobile) {
    if (widget.streak == 0 && widget.xp == 0) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(top: isMobile ? 4 : 10),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 6 : 10, vertical: isMobile ? 4 : 8),
        decoration: BoxDecoration(
          color: primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
          border: Border.all(color: primary.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            if (widget.streak > 0)
              Padding(
                padding: EdgeInsets.only(bottom: isMobile ? 2 : 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🔥', style: TextStyle(fontSize: isMobile ? 10 : 14)),
                    SizedBox(width: isMobile ? 2 : 4),
                    Flexible(
                      child: Text(
                        '${widget.streak} day streak!',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: isMobile ? 8 : 11,
                          color: primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            XPBar(
                current: widget.xp,
                max: widget.maxXp,
                color: primary,
                isMobile: isMobile),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  STATE META
// ─────────────────────────────────────────────
class _StateMeta {
  final String emoji;
  final String label;
  final List<Color> gradient;
  final Color border;
  const _StateMeta({
    required this.emoji,
    required this.label,
    required this.gradient,
    required this.border,
  });
}

// ─────────────────────────────────────────────
//  DEMO SCREEN  (drop this into your app to preview)
// ─────────────────────────────────────────────
class GuideDemo extends StatefulWidget {
  const GuideDemo({super.key});
  @override
  State<GuideDemo> createState() => _GuideDemoState();
}

class _GuideDemoState extends State<GuideDemo> {
  final _guideKey = GlobalKey<StudentGuideWidgetState>();
  GuideCharacter _char = GuideCharacter.guide;
  int _xp = 42;
  int _streak = 7;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('✨ E-Learning Guide',
            style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontSize: 20)),
        actions: [
          // Character picker
          for (final c in GuideCharacter.values)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TextButton(
                onPressed: () => setState(() => _char = c),
                child: Text(
                  c.name,
                  style: TextStyle(
                    color: _char == c ? const Color(0xFF58CC02) : Colors.white54,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Guide widget
            Center(
              child: StudentGuideWidget(
                key: _guideKey,
                initialState: StudentGuideState.greeting,
                message: 'Hi! Ready? 🚀',
                xp: _xp,
                maxXp: 100,
                streak: _streak,
                config: GuideConfig(
                  character: _char,
                  size: 140,
                  primaryColor: const Color(0xFF58CC02),
                  accentColor: const Color(0xFFFFD900),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Controls
            _buildControlGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildControlGrid() {
    final buttons = [
      _Btn('👋 Greet', const Color(0xFF58CC02),
          () => _guideKey.currentState?.updateState(StudentGuideState.greeting, message: 'Welcome! 👋')),
      _Btn('🤔 Think', const Color(0xFF1CB0F6),
          () => _guideKey.currentState?.updateState(StudentGuideState.thinking, message: 'Thinking…')),
      _Btn('🏆 Win', const Color(0xFFFFD900),
          () => _guideKey.currentState?.celebrateSuccess(message: 'Perfect! 🏆')),
      _Btn('🎉 Cheer', const Color(0xFFFF4B4B),
          () => _guideKey.currentState?.updateState(StudentGuideState.cheer, message: 'On fire! 🔥')),
      _Btn('😔 Oops', const Color(0xFFFF9600),
          () => _guideKey.currentState?.showDisappointment()),
      _Btn('💪 Encourage', const Color(0xFF8549BA),
          () => _guideKey.currentState?.updateState(StudentGuideState.encouraging, message: 'Go! 💪')),
      _Btn('🚀 Level Up', const Color(0xFFFFD900),
          () => _guideKey.currentState?.triggerLevelUp(5)),
      _Btn('🔥 Streak', const Color(0xFFFF4B4B),
          () => _guideKey.currentState?.updateState(StudentGuideState.streakAlert, message: '${_streak}🔥 streak!')),
      _Btn('💡 Hint', const Color(0xFF1CB0F6),
          () => _guideKey.currentState?.updateState(StudentGuideState.hintReady, message: 'Hint! 💡')),
      _Btn('➕ XP', const Color(0xFF58CC02),
          () => setState(() => _xp = (_xp + 10).clamp(0, 100))),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 3.2,
      children: buttons
          .map((b) => _buildButton(b.label, b.color, b.onTap))
          .toList(),
    );
  }

  Widget _buildButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 13)),
        ),
      ),
    );
  }
}

class _Btn {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Btn(this.label, this.color, this.onTap);
}