import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final DateTime? proSubscriptionExpires;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.proSubscriptionExpires,
  });

  bool get isPro {
    // A user is considered "Pro" if the expiry date exists and is in the future.
    return proSubscriptionExpires != null && proSubscriptionExpires!.isAfter(DateTime.now());
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      proSubscriptionExpires: (data['proSubscriptionExpires'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      if (proSubscriptionExpires != null) 'proSubscriptionExpires': Timestamp.fromDate(proSubscriptionExpires!),
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    DateTime? proSubscriptionExpires,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      proSubscriptionExpires: proSubscriptionExpires ?? this.proSubscriptionExpires,
    );
  }
}
