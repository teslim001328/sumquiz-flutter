
import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:rxdart/rxdart.dart';

// Enum for the state of the purchase process
enum PurchaseState { idle, purchasing, success, error, restored, canceled }

class PurchaseResult {
  final PurchaseState state;
  final String? errorMessage;

  PurchaseResult(this.state, {this.errorMessage});
}

class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  final _purchaseResultController =
      BehaviorSubject<PurchaseResult>.seeded(PurchaseResult(PurchaseState.idle));
  Stream<PurchaseResult> get purchaseResultStream =>
      _purchaseResultController.stream;

  static const String _monthlyId = 'sumquiz_monthly';
  static const String _annualId = 'sumquiz_annual';
  static const String _lifetimeId = 'sumquiz_lifetime';
  static const Set<String> _kIds = {_monthlyId, _annualId, _lifetimeId};

  // --- SINGLE SOURCE OF TRUTH FOR PRO STATUS ---
  Stream<bool> isProStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) return false;
      final data = snapshot.data() as Map<String, dynamic>;
      // Check for 'subscriptionExpiry' field
      if (data.containsKey('subscriptionExpiry')) {
        // Lifetime access is handled by a null expiry date after a purchase
        if (data['subscriptionExpiry'] == null) return true;
        
        final expiryDate = (data['subscriptionExpiry'] as Timestamp).toDate();
        return expiryDate.isAfter(DateTime.now());
      }
      return false;
    }).onErrorReturn(false);
  }

  void initialize(String uid) {
    final purchaseUpdated = _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen(
      (purchaseDetailsList) {
        _listenToPurchaseUpdated(purchaseDetailsList, uid);
      },
      onDone: () {
        _subscription.cancel();
      },
      onError: (error) {
        _purchaseResultController.add(PurchaseResult(PurchaseState.error,
            errorMessage: 'Error in purchase stream: $error'));
        developer.log('Error in purchase stream.',
            name: 'com.myapp.SubscriptionService', error: error);
      },
    );
  }

  void _listenToPurchaseUpdated(
      List<PurchaseDetails> purchaseDetailsList, String uid) {
    for (var details in purchaseDetailsList) {
      PurchaseResult newResult;
      switch (details.status) {
        case PurchaseStatus.pending:
          newResult = PurchaseResult(PurchaseState.purchasing);
          break;
        case PurchaseStatus.error:
          newResult = PurchaseResult(PurchaseState.error,
              errorMessage: details.error?.message ?? 'An unknown error occurred.');
          developer.log('Purchase Error',
              name: 'com.myapp.SubscriptionService', error: details.error);
          break;
        case PurchaseStatus.canceled:
          newResult = PurchaseResult(PurchaseState.canceled);
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _verifyAndFulfillPurchase(details, uid);
          newResult = PurchaseResult(details.status == PurchaseStatus.purchased
              ? PurchaseState.success
              : PurchaseState.restored);
          break;
      }

      _purchaseResultController.add(newResult);

      if (details.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(details);
      }
    }
  }

  Future<void> _verifyAndFulfillPurchase(
      PurchaseDetails purchaseDetails, String uid) async {
    const bool isValid = true; // Placeholder for server-side validation

    if (!isValid) {
      return;
    }

    final transactionDateTime = purchaseDetails.transactionDate != null
        ? DateTime.fromMillisecondsSinceEpoch(
            int.parse(purchaseDetails.transactionDate!))
        : DateTime.now();

    DateTime? expiryDate;
    if (purchaseDetails.productID == _monthlyId) {
      expiryDate = transactionDateTime.add(const Duration(days: 30));
    } else if (purchaseDetails.productID == _annualId) {
      expiryDate = transactionDateTime.add(const Duration(days: 365));
    }

    WriteBatch batch = _firestore.batch();
    DocumentReference userRef = _firestore.collection('users').doc(uid);

    // *** MODIFIED: Using the standardized 'subscriptionExpiry' field ***
    batch.set(
        userRef,
        {
          'isPro': true,
          'subscriptionExpiry':
              expiryDate != null ? Timestamp.fromDate(expiryDate) : null,
          'purchaseId': purchaseDetails.purchaseID,
          'productId': purchaseDetails.productID,
          'lastVerified': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true));

    await batch.commit();
  }

  Future<void> purchasePlan(String planId) async {
    try {
      _purchaseResultController.add(PurchaseResult(PurchaseState.purchasing));
      final bool available = await _inAppPurchase.isAvailable();
      if (!available) {
        _purchaseResultController.add(PurchaseResult(PurchaseState.error,
            errorMessage: 'In-app purchasing is not available on this device.'));
        developer.log('In-app purchase not available',
            name: 'com.myapp.SubscriptionService');
        return;
      }

      final ProductDetailsResponse response =
          await _inAppPurchase.queryProductDetails(_kIds);
      if (response.notFoundIDs.isNotEmpty) {
        _purchaseResultController.add(PurchaseResult(PurchaseState.error,
            errorMessage: 'The requested subscription plan was not found.'));
        developer.log('Product not found: ${response.notFoundIDs}',
            name: 'com.myapp.SubscriptionService');
        return;
      }

      if (response.error != null) {
        _purchaseResultController.add(PurchaseResult(PurchaseState.error,
            errorMessage:
                'Error retrieving subscription plans: ${response.error!.message}'));
        developer.log('Error querying product details: ${response.error}',
            name: 'com.myapp.SubscriptionService');
        return;
      }

      final ProductDetails productDetails =
          response.productDetails.firstWhere((details) => details.id == planId);
      final PurchaseParam purchaseParam =
          PurchaseParam(productDetails: productDetails);

      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e, s) {
      _purchaseResultController.add(PurchaseResult(PurchaseState.error,
          errorMessage: 'An unexpected error occurred: $e'));
      developer.log('Error during purchase process',
          name: 'com.myapp.SubscriptionService', error: e, stackTrace: s);
    }
  }

  // Method to reset the state after the UI has handled it
  void resetPurchaseState() {
    _purchaseResultController.add(PurchaseResult(PurchaseState.idle));
  }

  Future<void> restorePurchases() async {
    await _inAppPurchase.restorePurchases();
  }

  void dispose() {
    _subscription.cancel();
    _purchaseResultController.close();
  }
}
