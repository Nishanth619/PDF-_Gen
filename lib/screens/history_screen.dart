import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../constants/strings.dart';
import '../models/pdf_file_model.dart';
import '../providers/pdf_provider.dart';
import '../services/pdf_security_service.dart';
import '../services/password_hint_service.dart';
import '../utils/logger.dart';
import '../widgets/modern_ui_components.dart';
import '../widgets/banner_ad_widget.dart';
import 'package:shimmer/shimmer.dart';

/// Screen to display PDF history
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final Set<String> _selectedPdfIds = {};
  bool _isSelectionMode = false;

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedPdfIds.clear();
      }
    });
  }

  void _toggleSelection(String pdfId) {
    setState(() {
      if (_selectedPdfIds.contains(pdfId)) {
        _selectedPdfIds.remove(pdfId);
      } else {
        _selectedPdfIds.add(pdfId);
      }

      // If no items are selected, exit selection mode
      if (_selectedPdfIds.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _selectAll(List<PdfFileModel> pdfList) {
    setState(() {
      _isSelectionMode = true;
      _selectedPdfIds.clear();
      for (final pdf in pdfList) {
        _selectedPdfIds.add(pdf.id);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedPdfIds.clear();
      _isSelectionMode = false;
    });
  }

  Future<void> _deleteSelectedPdfs(
      BuildContext context, List<PdfFileModel> pdfList) async {
    final selectedPdfs =
        pdfList.where((pdf) => _selectedPdfIds.contains(pdf.id)).toList();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            'Delete ${selectedPdfs.length} PDF${selectedPdfs.length > 1 ? 's' : ''}?'),
        content: Text(
            'Are you sure you want to delete ${selectedPdfs.length} selected PDF${selectedPdfs.length > 1 ? 's' : ''}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final pdfProvider = Provider.of<PdfProvider>(context, listen: false);
        bool allDeleted = true;

        // Delete each selected PDF
        for (final pdf in selectedPdfs) {
          try {
            // Delete from database
            await pdfProvider.deletePdf(pdf.id);

            // Delete the actual file from filesystem
            final file = File(pdf.path);
            if (await file.exists()) {
              await file.delete();
            }
          } catch (e) {
            Logger.e('Error deleting PDF: ${pdf.name}', e);
            allDeleted = false;
          }
        }

        // Refresh the history
        if (context.mounted) {
          await pdfProvider.refreshHistory();
          _clearSelection();

          if (allDeleted) {
            Fluttertoast.showToast(
              msg:
                  '${selectedPdfs.length} PDF${selectedPdfs.length > 1 ? 's' : ''} deleted successfully',
              backgroundColor: Colors.green,
            );
          } else {
            Fluttertoast.showToast(
              msg: 'Some PDFs could not be deleted',
              backgroundColor: Colors.orange,
            );
          }
        }
      } catch (e) {
        Logger.e('Error deleting selected PDFs', e);
        if (context.mounted) {
          Fluttertoast.showToast(
            msg: 'Failed to delete PDFs',
            backgroundColor: Colors.red,
          );
        }
      }
    }
  }

  Future<void> _shareSelectedPdfs(List<PdfFileModel> pdfList) async {
    final selectedPdfs =
        pdfList.where((pdf) => _selectedPdfIds.contains(pdf.id)).toList();

    try {
      final xFiles = selectedPdfs.map((pdf) => XFile(pdf.path)).toList();
      await Share.shareXFiles(
        xFiles,
        subject: 'Shared PDFs',
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Failed to share PDFs',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _deleteSinglePdf(BuildContext context, PdfFileModel pdf) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete PDF'),
        content: Text('Are you sure you want to delete ${pdf.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        // Delete from database first
        final pdfProvider = Provider.of<PdfProvider>(context, listen: false);
        await pdfProvider.deletePdf(pdf.id);

        // Then delete the actual file from filesystem
        final file = File(pdf.path);
        if (await file.exists()) {
          await file.delete();
        }

        // Refresh the history
        if (context.mounted) {
          await pdfProvider.refreshHistory();
          Fluttertoast.showToast(
            msg: 'PDF deleted successfully',
            backgroundColor: Colors.green,
          );
        }
      } catch (e) {
        Logger.e('Error deleting PDF', e);
        if (context.mounted) {
          Fluttertoast.showToast(
            msg: 'Failed to delete PDF',
            backgroundColor: Colors.red,
          );
        }
      }
    }
  }

  Future<void> _shareSinglePdf(PdfFileModel pdf) async {
    try {
      await Share.shareXFiles(
        [XFile(pdf.path)],
        subject: pdf.name,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Failed to share PDF',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _openPdf(BuildContext context, PdfFileModel pdf) async {
    try {
      // Add to recent activity
      final pdfProvider = Provider.of<PdfProvider>(context, listen: false);
      await pdfProvider.addRecentActivity(pdf.id, 'opened');
      
      // Check if PDF is encrypted first
      final securityService = PdfSecurityService();
      final securityInfo = await securityService.checkPdfSecurity(pdf.path);
      
      if (securityInfo.isProtected) {
        // Show password dialog for encrypted PDFs
        await _showPasswordDialog(context, pdf);
      } else {
        // Use system viewer for non-encrypted PDFs
        final result = await OpenFilex.open(pdf.path);
        if (result.type != ResultType.done) {
          Fluttertoast.showToast(
            msg: 'Failed to open PDF: ${result.message}',
            backgroundColor: Colors.red,
          );
        }
      }
    } catch (e) {
      Logger.e('Error opening PDF', e);
      Fluttertoast.showToast(
        msg: 'Failed to open PDF',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _showPasswordDialog(BuildContext context, PdfFileModel pdf) async {
    String? passwordHint;
    bool showHint = false;
    
    // Load password hint
    passwordHint = await PasswordHintService.getHint(pdf.path);

    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Password Required'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('This PDF is password protected. The system PDF viewer will prompt for the password when you open the file.'),
                    const SizedBox(height: 16),
                    
                    // Password hint section
                    if (passwordHint != null && passwordHint!.isNotEmpty) ...[
                      Card(
                        color: Colors.blue.shade50,
                        margin: EdgeInsets.zero,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              showHint = !showHint;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.lightbulb_outline,
                                      color: Colors.blue.shade700,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(
                                      showHint ? Icons.expand_less : Icons.expand_more,
                                      color: Colors.blue.shade700,
                                    ),
                                  ],
                                ),
                                if (!showHint)
                                  Text(
                                    'Tap to reveal your password hint',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade600,
                                    ),
                                  ),
                                if (showHint) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.blue.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.tips_and_updates,
                                          color: Colors.amber.shade700,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Your Hint:',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                                ),
                                              ),
                                              Text(
                                                passwordHint!,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop(); // Close dialog
                    // Open the PDF - system should prompt for password
                    final result = await OpenFilex.open(pdf.path);
                    if (result.type != ResultType.done) {
                      Fluttertoast.showToast(
                        msg: 'Failed to open PDF: ${result.message}',
                        backgroundColor: Colors.red,
                      );
                    }
                  },
                  child: const Text('Open PDF'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: _isSelectionMode
          ? AppBar(
              title: Text('${_selectedPdfIds.length} selected'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _clearSelection,
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () {
                    final pdfProvider =
                        Provider.of<PdfProvider>(context, listen: false);
                    _shareSelectedPdfs(pdfProvider.pdfHistory);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    final pdfProvider =
                        Provider.of<PdfProvider>(context, listen: false);
                    _deleteSelectedPdfs(context, pdfProvider.pdfHistory);
                  },
                ),
              ],
            )
          : AppBar(
              title: const Text(AppStrings.historyTab),
              centerTitle: true,
              actions: [
                Consumer<PdfProvider>(
                  builder: (context, provider, child) {
                    if (provider.pdfHistory.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh',
                      onPressed: () => provider.refreshHistory(),
                    );
                  },
                ),
              ],
            ),
      body: Consumer<PdfProvider>(
        builder: (context, provider, child) {
          if (provider.pdfHistory.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.folder_open_outlined,
              title: 'No PDFs Yet',
              subtitle: 'Your converted PDFs will appear here.\nStart by converting some images!',
            );
          }

          return Column(
            children: [
              if (_isSelectionMode)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => _selectAll(provider.pdfHistory),
                        child: const Text('Select All'),
                      ),
                      TextButton(
                        onPressed: _clearSelection,
                        child: const Text('Clear Selection'),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: provider.pdfHistory.length,
                  itemBuilder: (context, index) {
                    final pdf = provider.pdfHistory[index];
                    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
                    final isSelected = _selectedPdfIds.contains(pdf.id);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: isSelected
                          ? colorScheme.primary.withOpacity(0.1)
                          : null,
                      child: ListTile(
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.picture_as_pdf,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        title: Text(
                          pdf.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${pdf.pageCount} pages • ${_formatFileSize(pdf.size)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              dateFormat.format(pdf.createdAt),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurface.withOpacity(
                                        0.6), // Fixed: Use opacity instead of withValues
                                  ),
                            ),
                          ],
                        ),
                        trailing: _isSelectionMode
                            ? Checkbox(
                                value: isSelected,
                                onChanged: (value) {
                                  _toggleSelection(pdf.id);
                                },
                              )
                            : PopupMenuButton(
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'open',
                                    child: Row(
                                      children: [
                                        Icon(Icons.open_in_new),
                                        SizedBox(width: 8),
                                        Text('Open'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'share',
                                    child: Row(
                                      children: [
                                        Icon(Icons.share),
                                        SizedBox(width: 8),
                                        Text('Share'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Delete',
                                            style:
                                                TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (value) {
                                  switch (value) {
                                    case 'open':
                                      _openPdf(context, pdf);
                                      break;
                                    case 'share':
                                      _shareSinglePdf(pdf);
                                      break;
                                    case 'delete':
                                      _deleteSinglePdf(context, pdf);
                                      break;
                                  }
                                },
                              ),
                        onTap: _isSelectionMode
                            ? () => _toggleSelection(pdf.id)
                            : () => _openPdf(context, pdf),
                        onLongPress: () {
                          if (!_isSelectionMode) {
                            _toggleSelectionMode();
                            _toggleSelection(pdf.id);
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
              
              // Banner Ad at bottom
              const BannerAdWidget(),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<PdfProvider>(
        builder: (context, provider, child) {
          if (provider.pdfHistory.isNotEmpty && !_isSelectionMode) {
            return FloatingActionButton(
              onPressed: () => _toggleSelectionMode(),
              child: const Icon(Icons.select_all),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
