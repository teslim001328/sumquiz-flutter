import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final DateTime? subscriptionExpiry;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.subscriptionExpiry,
  });

  bool get isPro {
    // A user is considered "Pro" if the expiry date exists and is in the future.
    return subscriptionExpiry != null && subscriptionExpiry!.isAfter(DateTime.now());
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      subscriptionExpiry: (data['subscriptionExpiry'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      if (subscriptionExpiry != null) 'subscriptionExpiry': Timestamp.fromDate(subscriptionExpiry!),
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    DateTime? subscriptionExpiry,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      subscriptionExpiry: subscriptionExpiry ?? this.subscriptionExpiry,
    );
  }
}
