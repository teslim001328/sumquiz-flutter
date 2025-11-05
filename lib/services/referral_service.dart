import 'dart:async';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class ReferralService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  Future<String> generateReferralCode(String uid) async {
    final userDocRef = _firestore.collection('users').doc(uid);
    final doc = await userDocRef.get();

    if (doc.exists && doc.data()!.containsKey('referralCode')) {
      return doc.data()!['referralCode'];
    } else {
      String code = await _generateUniqueCode();
      await userDocRef.set({'referralCode': code}, SetOptions(merge: true));
      return code;
    }
  }

  Future<void> applyReferralCode(String code, String newUserId) async {
    if (code.trim().isEmpty) {
      developer.log('Attempted to apply an empty referral code.', name: 'com.example.myapp.ReferralService');
      return;
    }

    final query = await _firestore
        .collection('users')
        .where('referralCode', isEqualTo: code)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final referrer = query.docs.first;
      final referrerId = referrer.id;

      if (referrerId == newUserId) {
        developer.log('User $newUserId attempted to refer themselves.', name: 'com.example.myapp.ReferralService');
        return;
      }
      
      final newUserDocRef = _firestore.collection('users').doc(newUserId);
      final newUserDoc = await newUserDocRef.get();

      if (newUserDoc.exists && newUserDoc.data()!.containsKey('appliedReferralCode')) {
        developer.log('User $newUserId has already applied a referral code.', name: 'com.example.myapp.ReferralService');
        return;
      }

      // Grant reward to the referrer
      await _checkAndGrantReferrerReward(referrerId);

      // Grant a 3-day Pro trial to the new user (invitee)
      final trialExpiryDate = DateTime.now().add(const Duration(days: 3));
      await newUserDocRef.set({
        'appliedReferralCode': code,
        'isPro': true,
        'subscriptionExpiry': Timestamp.fromDate(trialExpiryDate),
      }, SetOptions(merge: true));

      developer.log('User $newUserId applied referral code $code and received a 3-day trial.', name: 'com.example.myapp.ReferralService');

    } else {
      developer.log('Referral code $code not found.', name: 'com.example.myapp.ReferralService');
    }
  }

  Future<void> _checkAndGrantReferrerReward(String referrerId) async {
    final referrerDocRef = _firestore.collection('users').doc(referrerId);
    
    await _firestore.runTransaction((transaction) async {
      final referrerDoc = await transaction.get(referrerDocRef);

      if (!referrerDoc.exists) {
        return;
      }

      final data = referrerDoc.data()!;
      final currentReferrals = (data['referrals'] as int?) ?? 0;
      final totalReferrals = (data['totalReferrals'] as int?) ?? 0;
      final currentRewards = (data['referralRewards'] as int?) ?? 0;

      final newReferralCount = currentReferrals + 1;
      final newTotalReferrals = totalReferrals + 1;

      if (newReferralCount >= 3) {
        transaction.update(referrerDocRef, {
          'referrals': 0, 
          'totalReferrals': newTotalReferrals,
          'referralRewards': currentRewards + 1, 
        });

        developer.log(
          'User $referrerId reached 3 referrals and was granted 1 week of pro. Total rewards: ${currentRewards + 1}',
          name: 'com.example.myapp.ReferralService',
        );
      } else {
        transaction.update(referrerDocRef, {
          'referrals': newReferralCount,
          'totalReferrals': newTotalReferrals,
        });

        developer.log(
          'User $referrerId now has $newReferralCount referrals towards their next reward. Total referrals: $newTotalReferrals',
          name: 'com.example.myapp.ReferralService',
        );
      }
    });
  }

  Stream<int> getReferralCount(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists || !snapshot.data()!.containsKey('referrals')) {
        return 0;
      }
      return snapshot.data()!['referrals'] as int;
    });
  }
  
  Stream<int> getTotalReferralCount(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists || !snapshot.data()!.containsKey('totalReferrals')) {
        return 0;
      }
      return snapshot.data()!['totalReferrals'] as int;
    });
  }
  
  Stream<int> getReferralRewards(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists || !snapshot.data()!.containsKey('referralRewards')) {
        return 0;
      }
      return snapshot.data()!['referralRewards'] as int;
    });
  }

  Future<String> _generateUniqueCode() async {
    String code = '';
    bool isUnique = false;

    while (!isUnique) {
      code = _uuid.v4().substring(0, 8).toUpperCase();
      final query = await _firestore.collection('users').where('referralCode', isEqualTo: code).limit(1).get();
      if (query.docs.isEmpty) {
        isUnique = true;
      }
    }
    return code;
  }
}
