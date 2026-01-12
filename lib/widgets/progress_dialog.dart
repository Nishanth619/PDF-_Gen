import 'package:flutter/material.dart';

/// Dialog showing conversion progress
class ProgressDialog extends StatelessWidget {
  const ProgressDialog({
    super.key,
    required this.progress,
    required this.message,
  });
  final double progress;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              value: progress,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
