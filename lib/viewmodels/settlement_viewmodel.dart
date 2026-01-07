import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/settlement_model.dart';

class SettlementViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<bool> settleUp({
    required String myUid,
    required String partnerUid,
    required double totalAmount, // Absolute amount being settled
    required bool iAmPayer, // true if myUid is paying, false if receiving
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      // 1. Fetch all unsettled transactions involving this pair
      // Since we can't easily do OR queries for sender/receiver, we fetch all and filter
      // OR better, we fetch two queries and merge results.
      // For simplicity/correctness with the current structure, let's fetch 'transactions'
      // where isSettled == false. Ideally we'd filter by users too but Firestore limits.
      // We will do a client-side filter for safety to ensure we only settle OUR transactions.

      final snapshot = await firestore
          .collection('transactions')
          .where(
            Filter.or(
              Filter('senderUid', isEqualTo: myUid),
              Filter('receiverUid', isEqualTo: myUid),
            ),
          )
          .orderBy('timestamp', descending: true)
          .get();

      final relevantDocs = snapshot.docs.where((doc) {
        final data = doc.data();
        // Treat null or missing as false (unsettled). Only skip if strictly true.
        if (data['isSettled'] == true) return false;

        final sender = data['senderUid'];
        final receiver = data['receiverUid'];
        // Check if it's a transaction between me and partner
        return (sender == myUid && receiver == partnerUid) ||
            (sender == partnerUid && receiver == myUid);
      }).toList();

      if (relevantDocs.isEmpty) {
        _isLoading = false;
        notifyListeners();
        return false; // Nothing to settle
      }

      // 2. Create Settlement Document
      final settlementRef = firestore.collection('settlements').doc();
      final settlement = SettlementModel(
        id: settlementRef.id,
        startDate: (relevantDocs.last.data()['timestamp'] as Timestamp)
            .toDate(), // Oldest tx
        endDate: DateTime.now(),
        totalAmount: totalAmount,
        payerUid: iAmPayer ? myUid : partnerUid,
        receiverUid: iAmPayer ? partnerUid : myUid,
        transactionIds: relevantDocs.map((d) => d.id).toList(),
        timestamp: DateTime.now(),
      );

      final settlementMap = settlement.toMap();
      settlementMap['settledByUid'] =
          myUid; // Explicitly add who clicked the button
      batch.set(settlementRef, settlementMap);

      // 3. Update Transactions
      for (var doc in relevantDocs) {
        batch.update(doc.reference, {
          'isSettled': true,
          'settlementId': settlement.id,
        });
      }

      await batch.commit();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error settling up: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Stream<List<SettlementModel>> getSettlementHistory(
    String myUid,
    String partnerUid,
  ) {
    return FirebaseFirestore.instance
        .collection('settlements')
        .where(
          Filter.or(
            Filter('payerUid', isEqualTo: myUid),
            Filter('receiverUid', isEqualTo: myUid),
          ),
        )
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => SettlementModel.fromMap(doc.data(), doc.id))
              .where(
                (s) =>
                    (s.payerUid == myUid && s.receiverUid == partnerUid) ||
                    (s.payerUid == partnerUid && s.receiverUid == myUid),
              )
              .toList();
        });
  }
}
