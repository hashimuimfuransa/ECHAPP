import 'package:flutter_riverpod/flutter_riverpod.dart';

final sidebarProvider = StateNotifierProvider<SidebarNotifier, bool>((ref) {
  return SidebarNotifier();
});

class SidebarNotifier extends StateNotifier<bool> {
  SidebarNotifier() : super(false); // Default: not collapsed

  void toggleSidebar() {
    state = !state;
  }

  void setCollapsed(bool value) {
    state = value;
  }
}
