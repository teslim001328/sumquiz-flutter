import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../services/subscription_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  SubscriptionScreenState createState() => SubscriptionScreenState();
}

class SubscriptionScreenState extends State<SubscriptionScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  List<ProductDetails> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _subscriptionService.listenToPurchases(context);
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final products = await _subscriptionService.getProducts();
    setState(() {
      _products = products;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade to Pro'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildProductList(),
    );
  }

  Widget _buildProductList() {
    return ListView.builder(
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return Card(
          margin: const EdgeInsets.all(16.0),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Text(
                  product.title,
                  style: GoogleFonts.oswald(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  product.description,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Text(
                  product.price,
                  style: GoogleFonts.oswald(
                      fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    _subscriptionService.purchaseSubscription(product);
                  },
                  child: const Text('Subscribe'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
