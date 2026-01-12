import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../services/subscription_service.dart';

/// Premium Screen - Remove Ads
/// All features are FREE. Premium only removes ads.
class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Remove Ads'),
        centerTitle: true,
      ),
      body: Consumer<SubscriptionService>(
        builder: (context, subscription, child) {
          if (subscription.isPremium) {
            return _buildAdFreeView(context, subscription);
          }
          return _buildUpgradeView(context, subscription);
        },
      ),
    );
  }

  Widget _buildAdFreeView(BuildContext context, SubscriptionService subscription) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: 80,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '🎉 Ad-Free Experience!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Plan: ${subscription.subscriptionType.toUpperCase()}',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            Card(
              color: Colors.green.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      '✅ No more ads\n'
                      '✅ Uninterrupted workflow\n'
                      '✅ Support development\n'
                      '✅ All features included',
                      style: TextStyle(fontSize: 16, height: 1.8),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Thank you for supporting PDFGen!',
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradeView(BuildContext context, SubscriptionService subscription) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667EEA).withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.block,
                  size: 64,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Remove Ads',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enjoy PDFGen without interruptions',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Free features notice
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'All features are FREE! Premium only removes ads.',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Benefits
          _buildBenefitsList(),
          const SizedBox(height: 24),

          // Subscription Cards
          _buildSubscriptionCard(
            context: context,
            title: 'Monthly',
            price: '\$0.99/mo',
            productId: SubscriptionService.monthlyProductId,
            subscription: subscription,
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildSubscriptionCard(
            context: context,
            title: 'Yearly',
            price: '\$4.99/yr',
            savings: 'Save 58%',
            productId: SubscriptionService.yearlyProductId,
            subscription: subscription,
            color: Colors.green,
            recommended: true,
          ),
          const SizedBox(height: 12),
          _buildSubscriptionCard(
            context: context,
            title: 'Lifetime',
            price: '\$9.99',
            savings: 'One-time payment',
            productId: SubscriptionService.lifetimeProductId,
            subscription: subscription,
            color: Colors.purple,
          ),
          const SizedBox(height: 24),

          // Restore purchases
          TextButton(
            onPressed: () async {
              await subscription.restorePurchases();
              Fluttertoast.showToast(msg: 'Checking for purchases...');
            },
            child: const Text('Restore Purchases'),
          ),
          const SizedBox(height: 24),

          // Terms
          Text(
            'Subscriptions auto-renew unless cancelled. '
            'Cancel anytime in your app store settings.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsList() {
    final benefits = [
      ('No interstitial ads', Icons.block),
      ('No banner ads', Icons.visibility_off),
      ('Uninterrupted workflow', Icons.speed),
      ('Support indie developer', Icons.favorite),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What You Get',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...benefits.map((b) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(b.$2, color: Colors.green, size: 20),
                  const SizedBox(width: 12),
                  Text(b.$1),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard({
    required BuildContext context,
    required String title,
    required String price,
    required String productId,
    required SubscriptionService subscription,
    required Color color,
    String? savings,
    bool recommended = false,
  }) {
    return Card(
      elevation: recommended ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: recommended
            ? BorderSide(color: color, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () async {
          final success = await subscription.purchaseSubscription(productId);
          if (success) {
            Navigator.pop(context);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.block, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (recommended) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'BEST VALUE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (savings != null)
                      Text(
                        savings,
                        style: TextStyle(color: Colors.green.shade700),
                      ),
                  ],
                ),
              ),
              Text(
                price,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
