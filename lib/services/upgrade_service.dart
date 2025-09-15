import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

class UpgradeService {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  final Set<String> _productIds = {
    'sumquiz_pro_monthly',
    'sumquiz_pro_yearly',
  };

  StreamSubscription<List<PurchaseDetails>> get subscription => _subscription;

  Future<List<ProductDetails>> getProducts() async {
    final bool isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) {
      print('In-app purchase is not available.');
      return [];
    }

    final ProductDetailsResponse response =
        await _inAppPurchase.queryProductDetails(_productIds);
    if (response.error != null) {
      print('Failed to query products: ${response.error}');
      return [];
    }
    return response.productDetails;
  }

  Future<void> purchaseProduct(ProductDetails product) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  void listenToPurchaseUpdates(BuildContext context) {
    _subscription = _inAppPurchase.purchaseStream.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList, context);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (error) {
      print('Error listening to purchases: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during purchase: $error')),
      );
    });
  }

  void _listenToPurchaseUpdated(
      List<PurchaseDetails> purchaseDetailsList, BuildContext context) {
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Handle pending purchases
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase is pending...')),
        );
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          // Handle error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${purchaseDetails.error!.message}')),
          );
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          await _firestoreService.updateUser(_auth.currentUser!.uid, {
            'subscription_status': 'Pro',
            'upgradedAt': Timestamp.now(),
            'daily_usage.summaries': 0,
            'daily_usage.quizzes': 0,
            'daily_usage.flashcards': 0,
          });
          showSuccessDialog(context);
        }
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    });
  }

  void showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade Successful!'),
        content: const Text('You are now a Pro user! 🎉'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void dispose() {
    _subscription.cancel();
  }
}
