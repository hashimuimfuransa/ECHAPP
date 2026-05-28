import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';

/// Modern animated dialog with blur backdrop, scale animation, and spring physics
/// 
/// Usage:
/// ```dart
/// showModernDialog(
///   context: context,
///   title: 'Confirm Action',
///   content: Text('Are you sure?'),
///   actions: [
///     ModernDialogAction.cancel(onPressed: () => Navigator.pop(context)),
///     ModernDialogAction.confirm(onPressed: () => Navigator.pop(context)),
///   ],
/// );
/// ```

class ModernDialog extends StatefulWidget {
  final String? title;
  final Widget? content;
  final List<Widget>? actions;
  final bool barrierDismissible;
  final EdgeInsetsGeometry? contentPadding;
  final EdgeInsetsGeometry? actionsPadding;
  final double? maxWidth;
  final Widget? icon;

  const ModernDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.barrierDismissible = true,
    this.contentPadding,
    this.actionsPadding,
    this.maxWidth,
    this.icon,
  });

  @override
  State<ModernDialog> createState() => _ModernDialogState();
}

class _ModernDialogState extends State<ModernDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _animationController.reverse();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () async {
        if (widget.barrierDismissible) {
          await _dismiss();
          return false;
        }
        return false;
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: widget.maxWidth ?? 400,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                  ),
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.1),
                    blurRadius: 60,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: widget.icon,
                      ),
                    ],
                    if (widget.title != null) ...[
                      if (widget.icon == null) const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          widget.title!,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    if (widget.content != null) ...[
                      const SizedBox(height: 16),
                      Padding(
                        padding: widget.contentPadding ??
                            const EdgeInsets.symmetric(horizontal: 24),
                        child: widget.content,
                      ),
                    ],
                    if (widget.actions != null && widget.actions!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Padding(
                        padding: widget.actionsPadding ??
                            const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: widget.actions!
                              .map((action) => Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: action,
                                  ))
                              .toList(),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows a modern animated dialog
Future<T?> showModernDialog<T>({
  required BuildContext context,
  String? title,
  Widget? content,
  List<Widget>? actions,
  bool barrierDismissible = true,
  EdgeInsetsGeometry? contentPadding,
  EdgeInsetsGeometry? actionsPadding,
  double? maxWidth,
  Widget? icon,
}) {
  // Get MaterialLocalizations with fallback to avoid null errors
  final materialLocalizations = MaterialLocalizations.of(context);
  
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: materialLocalizations?.modalBarrierDismissLabel ?? 'Dismiss',
    barrierColor: Colors.black.withOpacity(0.5),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: ModernDialog(
          title: title,
          content: content,
          actions: actions,
          barrierDismissible: barrierDismissible,
          contentPadding: contentPadding,
          actionsPadding: actionsPadding,
          maxWidth: maxWidth,
          icon: icon,
        ),
      );
    },
  );
}

/// Modern dialog action button styles
class ModernDialogAction {
  static Widget cancel({
    required VoidCallback? onPressed,
    String text = 'Cancel',
    bool isLoading = false,
  }) {
    return _AnimatedButton(
      onPressed: isLoading ? null : onPressed,
      isLoading: isLoading,
      backgroundColor: Colors.transparent,
      foregroundColor: AppTheme.greyColor,
      text: text,
      elevation: 0,
    );
  }

  static Widget confirm({
    required VoidCallback? onPressed,
    String text = 'Confirm',
    bool isLoading = false,
    Color? backgroundColor,
  }) {
    return _AnimatedButton(
      onPressed: isLoading ? null : onPressed,
      isLoading: isLoading,
      backgroundColor: backgroundColor ?? AppTheme.primary,
      foregroundColor: Colors.white,
      text: text,
      elevation: 4,
    );
  }

  static Widget danger({
    required VoidCallback? onPressed,
    String text = 'Delete',
    bool isLoading = false,
  }) {
    return _AnimatedButton(
      onPressed: isLoading ? null : onPressed,
      isLoading: isLoading,
      backgroundColor: Colors.red.shade500,
      foregroundColor: Colors.white,
      text: text,
      elevation: 4,
    );
  }

  static Widget custom({
    required VoidCallback? onPressed,
    required String text,
    required Color backgroundColor,
    required Color foregroundColor,
    bool isLoading = false,
  }) {
    return _AnimatedButton(
      onPressed: isLoading ? null : onPressed,
      isLoading: isLoading,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      text: text,
      elevation: 4,
    );
  }
}

class _AnimatedButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color backgroundColor;
  final Color foregroundColor;
  final String text;
  final double elevation;

  const _AnimatedButton({
    required this.onPressed,
    required this.isLoading,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.text,
    required this.elevation,
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed != null
          ? (_) => _pressController.forward()
          : null,
      onTapUp: widget.onPressed != null
          ? (_) => _pressController.reverse()
          : null,
      onTapCancel: widget.onPressed != null
          ? () => _pressController.reverse()
          : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: ElevatedButton(
          onPressed: widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.backgroundColor,
            foregroundColor: widget.foregroundColor,
            elevation: widget.elevation,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: widget.isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.foregroundColor,
                    ),
                  ),
                )
              : Text(
                  widget.text,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
        ),
      ),
    );
  }
}
