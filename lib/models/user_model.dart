import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  String name;
  String email;
  String subscriptionStatus;
  Map<String, int> dailyUsage;
  Timestamp lastReset;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.subscriptionStatus,
    required this.dailyUsage,
    required this.lastReset,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      subscriptionStatus: data['subscriptionStatus'] ?? 'Free',
      dailyUsage: Map<String, int>.from(data['dailyUsage'] ?? {}),
      lastReset: data['lastReset'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'subscriptionStatus': subscriptionStatus,
      'dailyUsage': dailyUsage,
      'lastReset': lastReset,
    };
  }
}
