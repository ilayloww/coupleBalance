import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String displayName;
  final String? partnerUid;
  final String? fcmToken;
  final int settlementDay;

  UserModel({
    required this.uid,
    required this.displayName,
    this.partnerUid,
    this.fcmToken,
    this.settlementDay = 10,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      uid: documentId,
      displayName: data['displayName'] ?? '',
      partnerUid: data['partnerUid'],
      fcmToken: data['fcmToken'],
      settlementDay: data['settlementDay'] ?? 10,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'partnerUid': partnerUid,
      'fcmToken': fcmToken,
      'settlementDay': settlementDay,
    };
  }

  factory UserModel.fromSnapshot(DocumentSnapshot snapshot) {
    return UserModel.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id);
  }
}
