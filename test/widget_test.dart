import 'package:couple_balance/services/auth_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:couple_balance/main.dart';
import 'package:couple_balance/screens/login_screen.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:couple_balance/services/notification_service.dart';
import 'package:couple_balance/services/deep_link_service.dart';

// Simple mock for FirebaseFunctions since we don't use it in the smoke test
class MockFirebaseFunctions extends Fake implements FirebaseFunctions {}

class MockNotificationService extends Fake implements NotificationService {
  @override
  Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    // Do nothing
  }
}

class MockDeepLinkService extends Fake implements DeepLinkService {
  @override
  void init() {
    // Do nothing
  }
}

void main() {
  testWidgets('App smoke test - Load Login Screen', (
    WidgetTester tester,
  ) async {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Mock Firebase Services
    final mockAuth = MockFirebaseAuth();
    final mockFirestore = FakeFirebaseFirestore();
    final mockFunctions = MockFirebaseFunctions();
    final mockNotificationService = MockNotificationService();
    final mockDeepLinkService = MockDeepLinkService();

    final authService = AuthService(
      auth: mockAuth,
      firestore: mockFirestore,
      functions: mockFunctions,
    );

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MyApp(
        prefs: prefs,
        authServiceOverride: authService,
        notificationServiceOverride: mockNotificationService,
        deepLinkServiceOverride: mockDeepLinkService,
      ),
    );

    // Pump frames to allow for auth check and navigation delay
    await tester.pumpAndSettle();

    // Verify that we are on the LoginScreen (since mockAuth has no user)
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
