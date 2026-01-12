import 'package:flutter/material.dart';

class PremiumFeatureDialog extends StatelessWidget {
  const PremiumFeatureDialog({
    super.key,
    required this.featureName,
    required this.description,
    required this.onUpgrade,
  });
  final String featureName;
  final String description;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.star, color: Colors.green),
          const SizedBox(width: 8),
          Text('Feature Unlocked: $featureName'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('All features are now available for free!'),
          const SizedBox(height: 16),
          const Text(
            'Enjoy these features:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildFeatureItem(Icons.text_fields, 'Unlimited OCR Text Extraction'),
          _buildFeatureItem(Icons.lock, 'PDF Password Protection'),
          _buildFeatureItem(Icons.edit, 'Digital Signatures'),
          _buildFeatureItem(Icons.batch_prediction, 'Batch Processing'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Continue'),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
