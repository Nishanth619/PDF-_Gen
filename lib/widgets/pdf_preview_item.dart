import 'dart:io';
import 'package:flutter/material.dart';

/// Widget to display PDF preview item
class PdfPreviewItem extends StatelessWidget {
  const PdfPreviewItem({
    super.key,
    required this.imageFile,
    required this.index,
    required this.onRemove,
    this.onReorder,
  });
  final File imageFile;
  final int index;
  final VoidCallback onRemove;
  final VoidCallback? onReorder;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Drag handle
            if (onReorder != null)
              Icon(
                Icons.drag_handle,
                color: Colors.grey[600],
              ),

            const SizedBox(width: 12),

            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                imageFile,
                width: 60,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 60,
                    height: 80,
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image),
                  );
                },
              ),
            ),

            const SizedBox(width: 12),

            // Page info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Page ${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FutureBuilder<int>(
                    future: imageFile.length(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final size = snapshot.data!;
                        final sizeStr = size < 1024
                            ? '$size B'
                            : size < 1024 * 1024
                                ? '${(size / 1024).toStringAsFixed(1)} KB'
                                : '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
                        return Text(
                          sizeStr,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),

            // Remove button
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: Colors.red,
              onPressed: onRemove,
              tooltip: 'Remove page',
            ),
          ],
        ),
      ),
    );
  }
}
