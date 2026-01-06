import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Sync email to Firestore on login to ensure existing users are discoverable
      if (credential.user != null) {
        debugPrint(
          "AuthService: Syncing email for user ${credential.user!.uid}: $email",
        );
        await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .set({
              'email': email.toLowerCase(),
              // We don't overwrite partnerUid or other fields
            }, SetOptions(merge: true));
      }
      return credential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint("Error signing in: ${e.message}");
      rethrow;
    } catch (e) {
      debugPrint("Unknown error signing in: $e");
      rethrow;
    }
  }

  Future<User?> registerWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        debugPrint(
          "AuthService: Registering user doc for ${credential.user!.uid} with email: $email",
        );
        await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .set({
              'email': email.toLowerCase(),
              'createdAt': FieldValue.serverTimestamp(),
            });
      }
      return credential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint("Error registering: ${e.message}");
      rethrow;
    } catch (e) {
      debugPrint("Unknown error registering: $e");
      rethrow;
    }
  }

  Future<void> signInAnonymously() async {
    try {
      await _auth.signInAnonymously();
    } catch (e) {
      debugPrint("Error signing in anonymously: $e");
      rethrow;
    }
  }

  // Placeholder for Google Sign In - requires platform specific setup
  // Future<void> signInWithGoogle() async { ... }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
