import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../models/settlement_request_model.dart';

class SettlementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Creates a new settlement request.
  Future<void> requestSettlement({
    required String senderUid,
    required String receiverUid,
    required double amount,
    required String currency,
    String? transactionId,
  }) async {
    // Client-side validation (must match Firestore rules)
    if (amount <= 0 || amount >= 1000000) {
      throw Exception('INVALID_AMOUNT');
    }
    if (currency.isEmpty || currency.length > 5) {
      throw Exception('INVALID_CURRENCY');
    }

    try {
      // Check for existing pending requests (Direction A -> B)
      final existingRequests = await _firestore
          .collection('settlement_requests')
          .where('senderUid', isEqualTo: senderUid)
          .where('receiverUid', isEqualTo: receiverUid)
          .where('status', isEqualTo: SettlementRequest.statusPending)
          .get();

      // Check for existing pending requests (Direction B -> A)
      final reverseRequests = await _firestore
          .collection('settlement_requests')
          .where('senderUid', isEqualTo: receiverUid)
          .where('receiverUid', isEqualTo: senderUid)
          .where('status', isEqualTo: SettlementRequest.statusPending)
          .get();

      if (existingRequests.docs.isNotEmpty || reverseRequests.docs.isNotEmpty) {
        throw Exception("PENDING_REQUEST_EXISTS");
      }

      final docRef = _firestore.collection('settlement_requests').doc();
      final request = SettlementRequest(
        id: docRef.id,
        senderUid: senderUid,
        receiverUid: receiverUid,
        amount: amount,
        currency: currency,
        timestamp: DateTime.now(),
        status: SettlementRequest.statusPending,
        transactionId: transactionId,
      );

      await docRef.set(request.toMap());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating settlement request: $e');
      }
      rethrow;
    }
  }

  /// Responds to a settlement request via Cloud Function.
  /// The server handles all settlement logic atomically.
  Future<void> respondToSettlementRequest({
    required String requestId,
    required bool response,
  }) async {
    final callable = _functions.httpsCallable('confirmSettlement');
    final result = await callable.call<Map<String, dynamic>>({
      'requestId': requestId,
      'response': response,
    });

    if (result.data['success'] != true) {
      throw Exception('Settlement response failed');
    }
  }

  /// Stream of incoming requests for a user
  Stream<List<SettlementRequest>> getIncomingRequests(String myUid) {
    return _firestore
        .collection('settlement_requests')
        .where('receiverUid', isEqualTo: myUid)
        .where('status', isEqualTo: SettlementRequest.statusPending)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => SettlementRequest.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  /// Fetches a specific settlement request by ID
  Future<SettlementRequest?> fetchSettlementRequest(String requestId) async {
    try {
      final doc = await _firestore
          .collection('settlement_requests')
          .doc(requestId)
          .get();
      if (!doc.exists) return null;
      return SettlementRequest.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching settlement request: $e');
      }
      return null;
    }
  }
}
