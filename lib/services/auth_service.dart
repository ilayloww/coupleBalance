import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:async';

import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

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
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _functions = functions ?? FirebaseFunctions.instance {
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
    _userSubscription = _firestore
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
            if (kDebugMode) debugPrint("Error listening to user details: $e");
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  Future<void> _fetchPartnersDetails() async {
    if (_currentUserModel == null || _currentUserModel!.partnerUids.isEmpty) {
      _partners = [];
      _selectedPartnerId = null; // Clear selection if no partners
      _isLoading = false; // Done loading (no partners found)
      notifyListeners();
      return;
    }

    try {
      // Fetch each partner doc individually (not via whereIn query)
      // because security rules use resource.data which requires per-doc evaluation.
      // Each read is wrapped in try-catch so one failure doesn't hide all partners.
      final List<UserModel> fetchedPartners = [];
      for (final uid in _currentUserModel!.partnerUids) {
        try {
          final doc = await _firestore
              .collection('users')
              .doc(uid)
              .get(const GetOptions(source: Source.server));
          if (doc.exists) {
            fetchedPartners.add(UserModel.fromSnapshot(doc));
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint("AuthService: Skipping partner (read failed: $e");
          }
        }
      }

      _partners = fetchedPartners;

      if (kDebugMode) {
        debugPrint("AuthService: Fetched ${_partners.length} partners.");
      }

      // Check validation of selectedPartnerId
      if (_selectedPartnerId != null) {
        // If current selection is not in the new list (unlinked), switch/clear
        final exists = _partners.any((p) => p.uid == _selectedPartnerId);
        if (!exists) {
          if (_partners.isNotEmpty) {
            _selectedPartnerId =
                _partners.first.uid; // Switch to next available
          } else {
            _selectedPartnerId = null; // No partners left
          }
        }
      }

      // Check auto-selection (initial or after clear)
      if (_selectedPartnerId == null && _partners.isNotEmpty) {
        _selectedPartnerId = _partners.first.uid;
      }

      _isLoading = false; // Data Loaded
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint("Error fetching partners: $e");
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
        if (kDebugMode) {
          debugPrint("AuthService: Syncing email for user.");
        }
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'email': email.toLowerCase(),
          // We don't overwrite partnerUid or other fields
        }, SetOptions(merge: true));

        // Trigger fetch immediately
        await _fetchCurrentUserDetails(credential.user!.uid);
      }
      return credential.user;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) debugPrint("Error signing in: ${e.message}");
      rethrow;
    } catch (e) {
      if (kDebugMode) debugPrint("Unknown error signing in: $e");
      rethrow;
    }
  }

  Future<User?> registerWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        if (kDebugMode) {
          debugPrint("AuthService: Registering new user doc.");
        }
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'email': email.toLowerCase(),
          'displayName': displayName,
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
      if (kDebugMode) debugPrint("Error registering: ${e.message}");
      rethrow;
    } catch (e) {
      if (kDebugMode) debugPrint("Unknown error registering: $e");
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
      if (kDebugMode) debugPrint("Error signing in anonymously: $e");
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint("Error sending password reset email: ${e.message}");
      }
      rethrow;
    }
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    final email = user.email;
    if (email == null) throw Exception('User email not found');

    try {
      // Re-authenticate
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      if (currentPassword == newPassword) {
        throw FirebaseAuthException(
          code: 'same-password',
          message: 'New password cannot be the same as current password',
        );
      }

      // Update password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) debugPrint("Error changing password: ${e.message}");
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _userSubscription?.cancel();
    _userSubscription = null;
    _currentUserModel = null;
    _partners = [];
    _selectedPartnerId = null;
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user');

      // Call Cloud Function
      if (kDebugMode) {
        debugPrint("AuthService: Calling deleteAccount cloud function.");
      }
      if (kDebugMode) {
        debugPrint("AuthService: Calling deleteAccount cloud function.");
      }

      // functions.useFunctionsEmulator('localhost', 5001); // Uncomment for local testing

      final callable = _functions.httpsCallable('deleteAccount');
      await callable.call();

      await signOut();
    } catch (e) {
      if (kDebugMode) debugPrint("Error deleting account: $e");
      rethrow;
    }
  }

  Future<String?> generatePartnerId() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    // Return existing if already present
    if (_currentUserModel?.partnerId != null) {
      return _currentUserModel!.partnerId;
    }

    try {
      final callable = _functions.httpsCallable('generateUniquePartnerId');
      final result = await callable.call();
      return result.data['partnerId'] as String?;
    } catch (e) {
      if (kDebugMode) debugPrint('Error generating partner ID: $e');
      rethrow;
    }
  }
}
