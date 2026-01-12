import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import '../utils/file_utils.dart';

/// Recent Files Widget
/// Quick access to recently created PDFs
class RecentFilesWidget extends StatefulWidget {
  const RecentFilesWidget({super.key});

  @override
  State<RecentFilesWidget> createState() => _RecentFilesWidgetState();
}

class _RecentFilesWidgetState extends State<RecentFilesWidget> {
  List<File> _recentFiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentFiles();
  }

  Future<void> _loadRecentFiles() async {
    try {
      final pdfDir = await FileUtils.getPdfDirectory();
      final files = pdfDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.toLowerCase().endsWith('.pdf'))
          .toList();
      
      // Sort by modified time (newest first)
      files.sort((a, b) {
        final aTime = a.statSync().modified;
        final bTime = b.statSync().modified;
        return bTime.compareTo(aTime);
      });
      
      // Get only last 5 files
      setState(() {
        _recentFiles = files.take(5).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_recentFiles.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.history, size: 40, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text(
                'No recent PDFs',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              const Text(
                'Your recent PDFs will appear here',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Files',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton(
              onPressed: _loadRecentFiles,
              child: const Text('Refresh'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Full-width vertical list
        ...List.generate(
          _recentFiles.length > 3 ? 3 : _recentFiles.length,
          (index) => _buildFileCard(_recentFiles[index]),
        ),
      ],
    );
  }

  Widget _buildFileCard(File file) {
    final name = file.path.split('/').last;
    final stat = file.statSync();
    final timeAgo = _formatTimeAgo(stat.modified);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => OpenFilex.open(file.path),
      onLongPress: () => _showFileOptions(file),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isDark ? Colors.white10 : Colors.grey.shade200,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // PDF Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 24),
                ),
                const SizedBox(width: 12),
                // File info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.replaceAll('.pdf', ''),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$timeAgo • ${_formatSize(stat.size)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Actions
                Icon(
                  Icons.chevron_right,
                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFileOptions(File file) {
    final name = file.path.split('/').last;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.open_in_new),
            title: const Text('Open'),
            onTap: () {
              Navigator.pop(context);
              OpenFilex.open(file.path);
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share'),
            onTap: () {
              Navigator.pop(context);
              Share.shareXFiles([XFile(file.path)]);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Delete', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              await file.delete();
              _loadRecentFiles();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${time.day}/${time.month}';
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
