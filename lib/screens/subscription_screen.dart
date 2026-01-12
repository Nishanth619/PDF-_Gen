import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/subscription_service.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Remove Ads'),
      ),
      body: Consumer<SubscriptionService>(
        builder: (context, subscriptionService, _) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.block,
                          size: 64,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Enjoy Ad-Free Experience',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'All premium features are now free! Subscribe to remove ads and support development.',
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Subscription Plans
                  Text(
                    'Choose Your Plan',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Monthly Plan
                  _buildSubscriptionCard(
                    context: context,
                    title: 'Monthly',
                    price: '₹299',
                    description: 'Remove ads for one month',
                    isPopular: false,
                    onSubscribe: () => _handleSubscription(context, 'monthly'),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Yearly Plan
                  _buildSubscriptionCard(
                    context: context,
                    title: 'Yearly',
                    price: '₹799',
                    description: 'Remove ads for one year (Save 78%)',
                    isPopular: true,
                    onSubscribe: () => _handleSubscription(context, 'yearly'),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Lifetime Plan
                  _buildSubscriptionCard(
                    context: context,
                    title: 'Lifetime',
                    price: '₹1799',
                    description: 'Remove ads forever (One-time payment)',
                    isPopular: false,
                    onSubscribe: () => _handleSubscription(context, 'lifetime'),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Restore Purchases
                  Center(
                    child: TextButton.icon(
                      onPressed: () async {
                        await subscriptionService.restorePurchases();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Purchases restored')),
                        );
                      },
                      icon: const Icon(Icons.restore),
                      label: const Text('Restore Purchases'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubscriptionCard({
    required BuildContext context,
    required String title,
    required String price,
    required String description,
    required bool isPopular,
    required VoidCallback onSubscribe,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isPopular
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isPopular)
              Chip(
                label: const Text('BEST VALUE'),
                backgroundColor: colorScheme.primary,
                labelStyle: TextStyle(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            
            const SizedBox(height: 8),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 4),
                if (title == 'Monthly' || title == 'Yearly')
                  Text(
                    title == 'Monthly' ? '/month' : '/year',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSubscribe,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPopular ? colorScheme.primary : null,
                  foregroundColor: isPopular ? colorScheme.onPrimary : null,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Subscribe'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSubscription(BuildContext context, String plan) {
    final subscriptionService = Provider.of<SubscriptionService>(context, listen: false);
    
    // Map plan to product ID
    String productId;
    switch (plan) {
      case 'monthly':
        productId = 'pdf_converter_monthly';
        break;
      case 'yearly':
        productId = 'pdf_converter_yearly';
        break;
      case 'lifetime':
        productId = 'pdf_converter_lifetime';
        break;
      default:
        productId = 'pdf_converter_monthly';
    }
    
    // Purchase subscription
    subscriptionService.purchaseSubscription(productId);
    
    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Processing subscription...')),
    );
  }
}