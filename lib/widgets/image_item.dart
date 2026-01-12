import 'dart:io';
import 'package:flutter/material.dart';

/// Widget to display an image item in the list
class ImageItem extends StatelessWidget {
  const ImageItem({
    super.key,
    required this.imageFile,
    required this.index,
    required this.onRemove,
    this.isSelected = false,
    this.onTap,
  });
  final File imageFile;
  final int index;
  final VoidCallback onRemove;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: isSelected ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                imageFile,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(
                        Icons.broken_image,
                        size: 48,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Index badge
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),

            // Remove button
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: onRemove,
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),

            // Selection indicator
            if (isSelected)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.check_circle,
                      color: colorScheme.primary,
                      size: 48,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
