import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import '../../services/subscription_service.dart';

class ProStatusWrapper extends StatelessWidget {
  final Widget Function(BuildContext, bool) builder;

  const ProStatusWrapper({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return StreamProvider<List<PurchaseDetails>>.value(
      value: context.read<SubscriptionService>().purchaseStream,
      initialData: const [],
      child: Consumer<List<PurchaseDetails>>(
        builder: (context, purchases, __) {
          final isPro = purchases.any((purchase) => purchase.productID == SubscriptionService.proPlanId && (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored));
          return builder(context, isPro);
        },
      ),
    );
  }
}
