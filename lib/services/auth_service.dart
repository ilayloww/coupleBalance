import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  UserModel? _currentUserModel;
  UserModel? get currentUserModel => _currentUserModel;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  Stream<User?> get userChanges => _auth.userChanges();

  // State for multiple partners
  String? _selectedPartnerId;
  String? get selectedPartnerId => _selectedPartnerId;
  List<UserModel> _partners = [];
  List<UserModel> get partners => _partners;

  // State for loading
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Initialize service by listening to auth changes
  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        _currentUserModel = null;
        _partners = [];
        _selectedPartnerId = null;
        _isLoading = false;
        notifyListeners();
      } else {
        _isLoading = true;
        notifyListeners();
        _fetchCurrentUserDetails(user.uid);
      }
    });
  }

  void selectPartner(String partnerId) {
    if (_partners.any((p) => p.uid == partnerId)) {
      _selectedPartnerId = partnerId;
      notifyListeners();
    }
  }

  StreamSubscription<DocumentSnapshot>? _userSubscription;

  Future<void> _fetchCurrentUserDetails(String uid) async {
    _userSubscription?.cancel();
    _userSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen(
          (doc) {
            if (doc.exists) {
              _currentUserModel = UserModel.fromSnapshot(doc);
              // Only set loading true if we don't have partners yet?
              // Or always true to indicate refresh?
              // For now, let's keep it simple. If we are already displaying data, maybe we don't want to flicker loader?
              // But the primary issue is the START.
              // Let's rely on _fetchPartnersDetails to unset it.
              _fetchPartnersDetails();
            } else {
              _isLoading = false;
              notifyListeners();
            }
          },
          onError: (e) {
            debugPrint("Error listening to user details: $e");
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  Future<void> _fetchPartnersDetails() async {
    if (_currentUserModel == null || _currentUserModel!.partnerUids.isEmpty) {
      _partners = [];
      _isLoading = false; // Done loading (no partners found)
      notifyListeners();
      return;
    }

    try {
      // Split into chunks of 10 for 'whereIn' query limit if needed,
      // but for now simple iteration or whereIn is fine for small numbers.
      final snapshots = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: _currentUserModel!.partnerUids)
          .get();

      _partners = snapshots.docs
          .map((doc) => UserModel.fromSnapshot(doc))
          .toList();

      debugPrint("AuthService: Fetched ${_partners.length} partners.");

      // Check auto-selection again now that we have partners
      if (_selectedPartnerId == null && _partners.isNotEmpty) {
        _selectedPartnerId = _partners.first.uid;
      }

      _isLoading = false; // Data Loaded
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching partners: $e");
      _isLoading = false; // Failed but done
      notifyListeners();
    }
  }

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

        // Trigger fetch immediately
        await _fetchCurrentUserDetails(credential.user!.uid);
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
              'partnerUids': [],
            });

        // Send verification email
        await credential.user!.sendEmailVerification();

        // Trigger fetch
        await _fetchCurrentUserDetails(credential.user!.uid);
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

  Future<void> sendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<void> reloadUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
      notifyListeners();
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
    await _userSubscription?.cancel();
    _userSubscription = null;
    _currentUserModel = null;
    _partners = [];
    _selectedPartnerId = null;
    notifyListeners();
  }
}
