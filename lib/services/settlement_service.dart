import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/settlement_request_model.dart';
import '../models/settlement_model.dart';

class SettlementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Creates a new settlement request.
  Future<void> requestSettlement({
    required String senderUid,
    required String receiverUid,
    required double amount,
    required String currency,
    String? transactionId,
  }) async {
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

      // Check if duplicate exists for THIS specific type (all vs single)
      // For simplicity/current logic: If ANY pending request exists between these two, block it.
      // We can refine later to allow multiple single-requests if needed, but for now block to avoid confusion.

      if (existingRequests.docs.isNotEmpty || reverseRequests.docs.isNotEmpty) {
        // Already pending in either direction
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
      debugPrint('Error creating settlement request: $e');
      rethrow;
    }
  }

  /// Responds to a settlement request.
  /// If [response] is true, it triggers the atomic settlement process.
  /// If [response] is false, it just marks the request as REJECTED.
  Future<void> respondToSettlementRequest({
    required String requestId,
    required bool response,
  }) async {
    final requestRef = _firestore
        .collection('settlement_requests')
        .doc(requestId);

    if (!response) {
      // Scenario A: Rejected
      await requestRef.update({'status': SettlementRequest.statusRejected});
      return;
    }

    // Scenario B: Confirmed (True) -> Atomic Transaction
    await _firestore.runTransaction((transaction) async {
      final requestSnapshot = await transaction.get(requestRef);
      if (!requestSnapshot.exists) {
        throw Exception("Settlement Request does not exist!");
      }

      final requestData = SettlementRequest.fromMap(
        requestSnapshot.data() as Map<String, dynamic>,
        requestSnapshot.id,
      );

      if (requestData.status != SettlementRequest.statusPending) {
        // Already processed or invalid
        throw Exception("Request is not in PENDING state.");
      }

      List<DocumentSnapshot> relevantDocs = [];

      if (requestData.transactionId != null) {
        // --- Single Transaction Settlement ---
        final txDoc = await transaction.get(
          _firestore.collection('transactions').doc(requestData.transactionId),
        );
        if (!txDoc.exists) {
          throw Exception("Transaction does not exist!");
        }
        if (txDoc['isSettled'] == true) {
          // Already settled, maybe by another means?
          // Just complete the request but don't re-settle? Or fail?
          // Let's fail to be safe/clear.
          throw Exception("Transaction is already settled.");
        }
        relevantDocs = [txDoc];
      } else {
        // --- All Unsettled Transactions Settlement ---

        // 1. Fetch all unsettled transactions by querying both directions explicitly
        // We use two separate queries to ensure compliance with security rules (which allow access if you are sender OR receiver).
        // A single OR query on just one party (requestData.senderUid) is insecure/denied because it includes transactions with third parties.

        final query1 = _firestore
            .collection('transactions')
            .where('senderUid', isEqualTo: requestData.senderUid)
            .where('receiverUid', isEqualTo: requestData.receiverUid)
            .get();

        final query2 = _firestore
            .collection('transactions')
            .where('senderUid', isEqualTo: requestData.receiverUid)
            .where('receiverUid', isEqualTo: requestData.senderUid)
            .get();

        final results = await Future.wait([query1, query2]);
        var allDocs = [...results[0].docs, ...results[1].docs];

        // Remove duplicates if any (unlikely with this specific logic but good practice when merging queries)
        final seenIds = <String>{};
        relevantDocs = allDocs.where((doc) {
          if (seenIds.contains(doc.id)) return false;
          seenIds.add(doc.id);

          final data = doc.data();
          // Filter strictly for unsettled
          return data['isSettled'] != true;
        }).toList();
      }

      // 2. Create Settlement Document
      final settlementRef = _firestore.collection('settlements').doc();
      final settlement = SettlementModel(
        id: settlementRef.id,
        startDate: relevantDocs.isNotEmpty
            ? ((relevantDocs.last.data() as Map<String, dynamic>)['timestamp']
                      as Timestamp)
                  .toDate()
            : DateTime.now(), // Fallback
        endDate: DateTime.now(),
        totalAmount: requestData.amount, // Use the agreed amount
        payerUid: requestData.senderUid, // Payer initiated the request
        receiverUid: requestData.receiverUid,
        transactionIds: relevantDocs.map((e) => e.id).toList(),
        timestamp: DateTime.now(),
      );

      final settlementMap = settlement.toMap();
      settlementMap['settledByUid'] =
          requestData.receiverUid; // receiver confirmed it

      // 3. Writes
      transaction.set(settlementRef, settlementMap);

      transaction.update(requestRef, {
        'status': SettlementRequest.statusCompleted,
      });

      for (var doc in relevantDocs) {
        transaction.update(doc.reference, {
          'isSettled': true,
          'settlementId': settlement.id,
        });
      }
    });
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
      debugPrint('Error fetching settlement request: $e');
      return null;
    }
  }
}
