import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final bool isPro;
  final DateTime? subscriptionExpiry;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.isPro = false,
    this.subscriptionExpiry,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      isPro: data['isPro'] ?? false,
      subscriptionExpiry: (data['subscriptionExpiry'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'isPro': isPro,
      if (subscriptionExpiry != null) 'subscriptionExpiry': Timestamp.fromDate(subscriptionExpiry!),
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    bool? isPro,
    DateTime? subscriptionExpiry,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      isPro: isPro ?? this.isPro,
      subscriptionExpiry: subscriptionExpiry ?? this.subscriptionExpiry,
    );
  }
}
