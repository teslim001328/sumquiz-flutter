import 'dart:async';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class ReferralService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String uid;
  final Uuid _uuid = Uuid();

  ReferralService(this.uid);

  // --- FIX: Now ensures the generated code is unique ---
  Future<String> generateReferralCode() async {
    final userDocRef = _firestore.collection('users').doc(uid);
    final doc = await userDocRef.get();

    if (doc.exists && doc.data()!.containsKey('referralCode')) {
      return doc.data()!['referralCode'];
    }

    String code = await _generateUniqueCode();
    await userDocRef.set({'referralCode': code}, SetOptions(merge: true));
    return code;
  }

  // --- FIX: Applying a code now just links the user, doesn't grant auto-pro ---
  Future<void> applyReferralCode(String code) async {
    final query = await _firestore.collection('users').where('referralCode', isEqualTo: code).limit(1).get();

    if (query.docs.isEmpty) {
      throw Exception('Invalid or expired referral code.');
    }
    final referredBy = query.docs.first.id;

    if (referredBy == uid) {
      throw Exception('You cannot apply your own referral code.');
    }

    // --- FIX: Store who referred this user ---
    await _firestore.collection('users').doc(uid).set({
      'referredBy': referredBy,
      'referralAppliedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    developer.log(
      'User $uid applied referral code from $referredBy',
      name: 'com.example.myapp.ReferralService',
    );
  }

  // --- NEW: Method to grant rewards after a referred user subscribes ---
  Future<void> grantReferrerReward(String referredUserId) async {
    final referredUserDoc = await _firestore.collection('users').doc(referredUserId).get();
    if (!referredUserDoc.exists || !referredUserDoc.data()!.containsKey('referredBy')) {
      return; // Not a referred user
    }

    final referrerId = referredUserDoc.data()!['referredBy'];

    // Grant credit to the original referrer
    await _firestore.collection('users').doc(referrerId).update({
      'referralCredits': FieldValue.increment(1), // e.g., 1 credit = 1 free month
      'referrals': FieldValue.increment(1),
    });

    developer.log(
      'User $referrerId was granted 1 referral credit because user $referredUserId subscribed.',
      name: 'com.example.myapp.ReferralService',
    );
  }

  Stream<int> getReferralCount() {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists || !snapshot.data()!.containsKey('referrals')) {
        return 0;
      }
      return snapshot.data()!['referrals'] as int;
    });
  }

  // --- FIX: Replaced insecure generator with a robust, unique one ---
  Future<String> _generateUniqueCode() async {
    String code = '';
    bool isUnique = false;

    while (!isUnique) {
      code = _uuid.v4().substring(0, 8).toUpperCase(); // e.g., 550E8400
      final query = await _firestore.collection('users').where('referralCode', isEqualTo: code).limit(1).get();
      if (query.docs.isEmpty) {
        isUnique = true;
      }
    }
    return code;
  }
}
