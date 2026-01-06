import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionLocation {
  final double lat;
  final double lng;
  final String addressName;

  TransactionLocation({
    required this.lat,
    required this.lng,
    required this.addressName,
  });

  factory TransactionLocation.fromMap(Map<String, dynamic> map) {
    return TransactionLocation(
      lat: map['lat']?.toDouble() ?? 0.0,
      lng: map['lng']?.toDouble() ?? 0.0,
      addressName: map['addressName'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'lat': lat, 'lng': lng, 'addressName': addressName};
  }
}

class TransactionModel {
  final String id;
  final String senderUid;
  final String receiverUid;
  final double amount;
  final String currency;
  final String note;
  final String? photoUrl;
  final TransactionLocation? location;
  final DateTime timestamp;

  TransactionModel({
    required this.id,
    required this.senderUid,
    required this.receiverUid,
    required this.amount,
    this.currency = '₺',
    required this.note,
    this.photoUrl,
    this.location,
    required this.timestamp,
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
      location: data['location'] != null
          ? TransactionLocation.fromMap(data['location'])
          : null,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
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
      'location': location?.toMap(),
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
