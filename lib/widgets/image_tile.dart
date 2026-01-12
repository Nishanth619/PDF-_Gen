import 'dart:io';
import 'package:flutter/material.dart';

/// Widget for displaying an image tile in the list
class ImageTile extends StatelessWidget {
  const ImageTile({
    super.key,
    required this.image,
    required this.index,
    required this.onRemove,
  });
  final File image;
  final int index;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            image,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
          ),
        ),
        title: Text('Page ${index + 1}'),
        subtitle: Text(
          image.path.split('/').last,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.drag_handle,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}
