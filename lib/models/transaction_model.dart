import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String senderUid;
  final String receiverUid;
  final double amount;
  final String currency;
  final String note;
  final String? photoUrl;
  final DateTime timestamp;
  final bool isSettled;
  final String? settlementId;
  final String? addedByUid;

  TransactionModel({
    required this.id,
    required this.senderUid,
    required this.receiverUid,
    required this.amount,
    this.currency = '₺',
    required this.note,
    this.photoUrl,
    required this.timestamp,
    this.isSettled = false,
    this.settlementId,
    this.addedByUid,
  });

  factory TransactionModel.fromMap(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return TransactionModel(
      id: documentId,
      senderUid: data['senderUid'] ?? '',
      receiverUid: data['receiverUid'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      currency: data['currency'] ?? '₺',
      note: data['note'] ?? '',
      photoUrl: data['photoUrl'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isSettled: data['isSettled'] ?? false,
      settlementId: data['settlementId'],
      addedByUid: data['addedByUid'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderUid': senderUid,
      'receiverUid': receiverUid,
      'amount': amount,
      'currency': currency,
      'note': note,
      'photoUrl': photoUrl,
      'timestamp': Timestamp.fromDate(timestamp),
      'isSettled': isSettled,
      'settlementId': settlementId,
      'addedByUid': addedByUid,
    };
  }
}
