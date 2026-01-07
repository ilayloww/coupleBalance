import 'package:cloud_firestore/cloud_firestore.dart';

class SettlementModel {
  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final double totalAmount;
  final String payerUid;
  final String receiverUid;
  final List<String> transactionIds;
  final DateTime timestamp;

  SettlementModel({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.totalAmount,
    required this.payerUid,
    required this.receiverUid,
    required this.transactionIds,
    required this.timestamp,
  });

  factory SettlementModel.fromMap(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return SettlementModel(
      id: documentId,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      payerUid: data['payerUid'] ?? '',
      receiverUid: data['receiverUid'] ?? '',
      transactionIds: List<String>.from(data['transactionIds'] ?? []),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'totalAmount': totalAmount,
      'payerUid': payerUid,
      'receiverUid': receiverUid,
      'transactionIds': transactionIds,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
