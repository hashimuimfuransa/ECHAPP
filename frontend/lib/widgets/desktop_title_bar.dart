import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';

class DesktopTitleBar extends StatelessWidget {
  final bool isSidebarCollapsed;
  final Widget? leading;
  final String? title;
  
  const DesktopTitleBar({
    super.key, 
    this.isSidebarCollapsed = false,
    this.leading,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final buttonColors = WindowButtonColors(
      iconNormal: isDark ? Colors.white70 : Colors.black87,
      mouseOver: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
      mouseDown: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1),
      iconMouseOver: isDark ? Colors.white : Colors.black,
      iconMouseDown: isDark ? Colors.white : Colors.black,
    );

    final closeButtonColors = WindowButtonColors(
      mouseOver: const Color(0xFFE81123),
      mouseDown: const Color(0xFFB71C1C),
      iconNormal: isDark ? Colors.white70 : Colors.black87,
      iconMouseOver: Colors.white,
    );

    return WindowTitleBarBox(
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          border: Border(
            bottom: BorderSide(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            if (leading != null) leading!,
            const SizedBox(width: 12),
            if (title != null) 
              Text(
                title!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            Expanded(
              child: MoveWindow(
                child: Container(),
              ),
            ),
            MinimizeWindowButton(colors: buttonColors),
            MaximizeWindowButton(colors: buttonColors),
            CloseWindowButton(colors: closeButtonColors),
          ],
        ),
      ),
    );
  }
}
