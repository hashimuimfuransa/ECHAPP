import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellence_coaching_hub/presentation/screens/dashboard/dashboard_screen.dart';

void main() {
  testWidgets('Dashboard screen layout test', (WidgetTester tester) async {
    // Build our app with ProviderScope and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: DashboardScreen(),
        ),
      ),
    );

    // Verify that the dashboard screen builds without layout errors
    expect(find.byType(DashboardScreen), findsOneWidget);
    
    // Test that the layout doesn't throw any exceptions
    await tester.pumpAndSettle();
    
    // If we reach here without exceptions, the layout is working
    expect(true, isTrue);
  });
}