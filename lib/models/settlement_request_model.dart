import 'package:cloud_firestore/cloud_firestore.dart';

class SettlementRequest {
  final String id;
  final String senderUid;
  final String receiverUid;
  final double amount;
  final String currency;
  final DateTime timestamp;
  final String status; // 'PENDING', 'ACCEPTED', 'REJECTED', 'COMPLETED'

  static const String statusPending = 'PENDING';
  static const String statusAccepted = 'ACCEPTED';
  static const String statusRejected = 'REJECTED';
  static const String statusCompleted = 'COMPLETED';

  SettlementRequest({
    required this.id,
    required this.senderUid,
    required this.receiverUid,
    required this.amount,
    required this.currency,
    required this.timestamp,
    required this.status,
  });

  factory SettlementRequest.fromMap(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return SettlementRequest(
      id: documentId,
      senderUid: data['senderUid'] ?? '',
      receiverUid: data['receiverUid'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      currency: data['currency'] ?? '₺',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      status: data['status'] ?? statusPending,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderUid': senderUid,
      'receiverUid': receiverUid,
      'amount': amount,
      'currency': currency,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status,
    };
  }
}
