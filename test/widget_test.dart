import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:couple_balance/main.dart';
import 'package:couple_balance/screens/login_screen.dart';

void main() {
  testWidgets('App smoke test - Load Login Screen', (
    WidgetTester tester,
  ) async {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(prefs: prefs));

    // Pump frames to allow for auth check and navigation delay
    await tester.pumpAndSettle();

    // Verify that we are on the LoginScreen
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
