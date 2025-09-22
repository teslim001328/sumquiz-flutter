import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../services/upgrade_service.dart';

class UpgradeModal extends StatefulWidget {
  const UpgradeModal({super.key});

  @override
  UpgradeModalState createState() => UpgradeModalState();
}

class UpgradeModalState extends State<UpgradeModal> {
  bool _isLoading = false;
  List<ProductDetails> _products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final upgradeService = context.read<UpgradeService>();
    final products = await upgradeService.getProducts();
    setState(() {
      _products = products;
    });
  }

  void _purchase(ProductDetails product) async {
    setState(() {
      _isLoading = true;
    });
    final upgradeService = context.read<UpgradeService>();
    await upgradeService.purchaseProPlan(product, context);
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Go Pro!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Unlock all features and get unlimited access to everything.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_products.isEmpty)
              const Text('No products available.')
            else
              ..._products.map((product) => ElevatedButton(
                    onPressed: () => _purchase(product),
                    child: Text('${product.title} - ${product.price}'),
                  )),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Maybe Later'),
            ),
          ],
        ),
      ),
    );
  }
}
