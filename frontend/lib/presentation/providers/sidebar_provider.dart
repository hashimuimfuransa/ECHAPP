import 'package:flutter_riverpod/flutter_riverpod.dart';

final sidebarProvider = StateNotifierProvider<SidebarNotifier, bool>((ref) {
  return SidebarNotifier();
});

class SidebarNotifier extends StateNotifier<bool> {
  // Default: collapsed to an icon rail, the way most modern desktop apps
  // start. The user can expand it from the top bar at any time.
  SidebarNotifier() : super(true);

  void toggleSidebar() {
    state = !state;
  }

  void setCollapsed(bool value) {
    state = value;
  }
}
