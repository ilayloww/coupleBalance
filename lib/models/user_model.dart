import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String displayName;
  final String? partnerUid; // Deprecated: Use partnerUids instead
  final List<String> partnerUids;
  final String? fcmToken;
  final int settlementDay;
  final String? photoUrl;
  final String? email;

  UserModel({
    required this.uid,
    required this.displayName,
    this.partnerUid,
    this.partnerUids = const [],
    this.fcmToken,
    this.settlementDay = 10,
    this.photoUrl,
    this.email,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    // Handle migration/compatibility:
    // If partnerUids exists, use it.
    // Else if partnerUid exists, wrap it in a list.
    List<String> partners = [];
    if (data['partnerUids'] != null) {
      partners = List<String>.from(data['partnerUids']);
    } else if (data['partnerUid'] != null) {
      partners = [data['partnerUid']];
    }

    return UserModel(
      uid: documentId,
      displayName: data['displayName'] ?? '',
      partnerUid: data['partnerUid'],
      partnerUids: partners,
      fcmToken: data['fcmToken'],
      settlementDay: data['settlementDay'] ?? 10,
      photoUrl: data['photoUrl'],
      email: data['email'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'partnerUid': partnerUid,
      'partnerUids': partnerUids,
      'fcmToken': fcmToken,
      'settlementDay': settlementDay,
      'photoUrl': photoUrl,
      'email': email,
    };
  }

  factory UserModel.fromSnapshot(DocumentSnapshot snapshot) {
    return UserModel.fromMap(
      snapshot.data() as Map<String, dynamic>,
      snapshot.id,
    );
  }
}
