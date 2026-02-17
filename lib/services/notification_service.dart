import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../screens/settlement_confirmation_screen.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    // 1. Request Permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) debugPrint('User granted notification permission');

      // 2. Get and Save Token
      String? token = await _fcm.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
      }

      // 3. Listen for Token Refreshes
      _fcm.onTokenRefresh.listen(_saveTokenToFirestore);

      // 4. Handle Notification Tap (Background -> Foreground)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (kDebugMode) {
          debugPrint(
            'Notification clicked (background): type=${message.data['type']}',
          );
        }
        _handleNotificationClick(message, navigatorKey);
      });

      // 5. Handle Notification Tap (Terminated -> Foreground)
      _fcm.getInitialMessage().then((RemoteMessage? message) {
        if (message != null) {
          if (kDebugMode) {
            debugPrint(
              'Notification clicked (terminated): type=${message.data['type']}',
            );
          }
          _handleNotificationClick(message, navigatorKey);
        }
      });
    } else {
      if (kDebugMode) {
        debugPrint('User declined or has not accepted permission');
      }
    }
  }

  void _handleNotificationClick(
    RemoteMessage message,
    GlobalKey<NavigatorState> navigatorKey,
  ) {
    if (message.data['type'] == 'friend_request') {
      navigatorKey.currentState?.pushNamed('/partners');
    } else if (message.data['type'] == 'settlement_request') {
      final requestId = message.data['requestId'];
      if (requestId != null) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => SettlementConfirmationScreen(requestId: requestId),
          ),
        );
      }
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final docRef = _firestore.collection('users').doc(user.uid);
        final doc = await docRef.get();
        if (doc.exists) {
          await docRef.set({
            'fcmToken': token,
            'lastTokenUpdate': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          if (kDebugMode) debugPrint("FCM Token saved successfully.");
        } else {
          if (kDebugMode) {
            debugPrint("Skipping FCM Token save: User doc does not exist.");
          }
        }
      } catch (e) {
        if (kDebugMode) debugPrint("Error saving FCM token: $e");
      }
    }
  }
}
