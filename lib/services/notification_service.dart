import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
      debugPrint('User granted permission');

      // 2. Get and Save Token
      String? token = await _fcm.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
      }

      // 3. Listen for Token Refreshes
      _fcm.onTokenRefresh.listen(_saveTokenToFirestore);

      // 4. Handle Notification Tap (Background -> Foreground)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('Notification clicked (background): ${message.data}');
        _handleNotificationClick(message, navigatorKey);
      });

      // 5. Handle Notification Tap (Terminated -> Foreground)
      _fcm.getInitialMessage().then((RemoteMessage? message) {
        if (message != null) {
          debugPrint('Notification clicked (terminated): ${message.data}');
          _handleNotificationClick(message, navigatorKey);
        }
      });
    } else {
      debugPrint('User declined or has not accepted permission');
    }
  }

  void _handleNotificationClick(
    RemoteMessage message,
    GlobalKey<NavigatorState> navigatorKey,
  ) {
    if (message.data['type'] == 'friend_request') {
      navigatorKey.currentState?.pushNamed('/partners');
    }
    // Add other types here if needed (e.g. new_expense -> /home)
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
          debugPrint("FCM Token saved: $token");
        } else {
          debugPrint(
            "Skipping FCM Token save: User doc does not exist (account likely deleted).",
          );
        }
      } catch (e) {
        debugPrint("Error saving FCM token: $e");
      }
    }
  }
}
