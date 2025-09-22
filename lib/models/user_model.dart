import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String subscriptionStatus;
  final Map<String, dynamic> dailyUsage;
  final Timestamp lastReset;
  final bool isPro;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.subscriptionStatus,
    required this.dailyUsage,
    required this.lastReset,
    this.isPro = false,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      subscriptionStatus: data['subscription_status'] ?? 'Free',
      dailyUsage: Map<String, dynamic>.from(data['daily_usage'] ?? {})
          .map((key, value) => MapEntry(key, value as int)),
      lastReset: data['last_reset'] ?? Timestamp.now(),
      isPro: data['isPro'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'subscription_status': subscriptionStatus,
      'daily_usage': dailyUsage,
      'last_reset': lastReset,
      'isPro': isPro,
    };
  }
}
