import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as syncfusion;

import '../models/page_range.dart';
import '../providers/pdf_provider.dart';
import '../services/pdf_split_merge_service.dart';
import '../utils/toast_helper.dart';
import '../models/pdf_file_model.dart';
import '../services/pdf_service.dart';
import '../widgets/pdf_page_preview.dart';
import '../widgets/modern_ui_components.dart';
import '../widgets/banner_ad_widget.dart';

/// Screen for splitting and merging PDF files
class PDFSplitMergeScreen extends StatefulWidget {
  const PDFSplitMergeScreen({super.key});

  @override
  State<PDFSplitMergeScreen> createState() => _PDFSplitMergeScreenState();
}

class _PDFSplitMergeScreenState extends State<PDFSplitMergeScreen> {
  List<PDFFileData> _files = [];
  bool _processing = false;
  String _errorMessage = '';
  String _successMessage = '';
  PDFMode _mode = PDFMode.split;
  List<String> _resultFiles = [];
  double _progress = 0.0; // Add progress tracking
  Set<int> _selectedPages = {}; // Selected pages from preview
  int _totalPages = 0; // Total pages in selected PDF
  bool _compressOnMerge = false; // Compress while merging option

  final TextEditingController _rangeController = TextEditingController();

  @override
  void dispose() {
    _rangeController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: _mode == PDFMode.merge,
      );

      if (result != null) {
        setState(() {
          _errorMessage = '';
          _successMessage = '';
          _resultFiles.clear();
        });

        for (var file in result.files) {
          if (file.path != null) {
            final bytes = await File(file.path!).readAsBytes();
            final pageCount = await _getPageCount(bytes);
            setState(() {
              _files.add(PDFFileData(
                name: file.name,
                path: file.path!,
                bytes: bytes,
                pageCount: pageCount,
              ));
              if (_mode == PDFMode.split && _files.length == 1) {
                _totalPages = pageCount;
              }
            });
          }
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking files: $e';
      });
    }
  }

  void _removeFile(int index) {
    setState(() {
      _files.removeAt(index);
      _errorMessage = '';
      _successMessage = '';
    });
  }

  void _moveFile(int index, bool moveUp) {
    if ((moveUp && index == 0) || (!moveUp && index == _files.length - 1)) {
      return;
    }

    setState(() {
      final targetIndex = moveUp ? index - 1 : index + 1;
      final temp = _files[index];
      _files[index] = _files[targetIndex];
      _files[targetIndex] = temp;
    });
  }

  Future<void> _splitPDF() async {
    if (_files.isEmpty) {
      setState(() {
        _errorMessage = 'Please upload a PDF file';
      });
      return;
    }

    if (_rangeController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter page ranges (e.g., 1-3, 5, 7-9)';
      });
      return;
    }

    setState(() {
      _processing = true;
      _errorMessage = '';
      _successMessage = '';
      _resultFiles.clear();
      _progress = 0.0;
    });

    try {
      final inputBytes = _files[0].bytes;
      
      // Load PDF to get page count
      final pdfDocument = PDFDocument();
      await pdfDocument.load(inputBytes);
      final totalPages = pdfDocument.pagesCount;
      
      final ranges = PDFSplitMergeService.parseSplitRanges(_rangeController.text, totalPages);

      final resultFiles = await PDFSplitMergeService.splitPDF(
        inputBytes, 
        ranges, 
        _files[0].name,
        (progress) { // Add progress callback
          setState(() {
            _progress = progress;
            _successMessage = 'Splitting PDF... ${(_progress * 100).round()}%';
          });
        },
      );

      setState(() {
        _resultFiles = resultFiles;
        _successMessage = 'PDF split successfully! ${resultFiles.length} file(s) created.';
        _progress = 1.0;
      });
      
      // Add split files to history
      await _addToHistory(resultFiles);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error splitting PDF: $e';
      });
    } finally {
      setState(() {
        _processing = false;
      });
    }
  }

  Future<void> _mergePDFs() async {
    if (_files.length < 2) {
      setState(() {
        _errorMessage = 'Please upload at least 2 PDF files to merge';
      });
      return;
    }

    setState(() {
      _processing = true;
      _errorMessage = '';
      _successMessage = '';
      _resultFiles.clear();
      _progress = 0.0;
    });

    try {
      final pdfBytesList = _files.map((file) => file.bytes).toList();
      final fileNames = _files.map((file) => file.name).toList();

      final mergedFilePath = await PDFSplitMergeService.mergePDFs(
        pdfBytesList, 
        fileNames,
        (progress) { // Add progress callback
          setState(() {
            _progress = progress;
            _successMessage = 'Merging PDFs... ${(_progress * 100).round()}%';
          });
        },
      );

      setState(() {
        _resultFiles = [mergedFilePath];
        _successMessage = 'PDFs merged successfully!';
        _progress = 1.0;
      });
      
      // Add merged file to history
      await _addToHistory([mergedFilePath]);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error merging PDFs: $e';
      });
    } finally {
      setState(() {
        _processing = false;
      });
    }
  }
  
  /// Add generated PDF files to history
  Future<void> _addToHistory(List<String> filePaths) async {
    try {
      final pdfProvider = Provider.of<PdfProvider>(context, listen: false);
      
      for (final filePath in filePaths) {
        final file = File(filePath);
        if (await file.exists()) {
          final fileName = file.path.split('/').last;
          final fileSize = await PDFSplitMergeService.getFileSize(filePath);
          
          final pdfModel = PdfFileModel(
            name: fileName,
            path: filePath,
            size: fileSize,
            pageCount: 0, // We could implement page count detection here
            createdAt: DateTime.now(),
          );
          
          await pdfProvider.insertPdf(pdfModel);
        }
      }
    } catch (e) {
      // Log error but don't interrupt the user flow
      print('Error adding to history: $e');
    }
  }
  
  /// Open a PDF file
  Future<void> _openPdf(String filePath) async {
    try {
      final pdfProvider = Provider.of<PdfProvider>(context, listen: false);
      
      // Find the PDF in history
      final pdfs = pdfProvider.pdfHistory;
      final pdf = pdfs.firstWhere(
        (p) => p.path == filePath, 
        orElse: () => PdfFileModel(
          name: filePath.split('/').last,
          path: filePath,
          size: 0,
          pageCount: 0,
          createdAt: DateTime.now(),
        )
      );
      
      // Add to recent activity
      await pdfProvider.addRecentActivity(pdf.id, 'opened');
      
      // Use the existing PDF service to open the file
      final success = await PdfService.openPdf(filePath);
      if (!success) {
        ToastHelper.showError(context, 'Failed to open PDF: ${pdf.name}');
      }
    } catch (e) {
      ToastHelper.showError(context, 'Error opening PDF: $e');
    }
  }

  Future<void> _shareFile(String filePath) async {
    try {
      await Share.shareXFiles([XFile(filePath)]);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error sharing file: $e';
      });
    }
  }

  void _reset() {
    setState(() {
      _files.clear();
      _rangeController.clear();
      _errorMessage = '';
      _successMessage = '';
      _resultFiles.clear();
      _selectedPages.clear();
      _totalPages = 0;
      _compressOnMerge = false;
    });
  }

  /// Get page count from PDF bytes
  Future<int> _getPageCount(Uint8List bytes) async {
    try {
      final pdf = syncfusion.PdfDocument(inputBytes: bytes);
      final count = pdf.pages.count;
      pdf.dispose();
      return count;
    } catch (e) {
      return 0;
    }
  }

  /// Extract a single page from PDF
  Future<void> _extractSinglePage(int pageNumber) async {
    if (_files.isEmpty) return;
    
    setState(() {
      _rangeController.text = '$pageNumber';
      _selectedPages = {pageNumber};
    });
    
    // Trigger split with single page
    await _splitPDF();
  }

  /// Update range controller when pages are selected from preview
  void _onPageSelectionChanged(Set<int> pages) {
    setState(() {
      _selectedPages = pages;
      // Auto-fill the range text field
      _rangeController.text = _formatSelectedPagesToRange(pages);
    });
  }

  String _formatSelectedPagesToRange(Set<int> pages) {
    if (pages.isEmpty) return '';
    
    final sortedPages = pages.toList()..sort();
    List<String> ranges = [];
    int start = sortedPages[0];
    int end = sortedPages[0];
    
    for (int i = 1; i < sortedPages.length; i++) {
      if (sortedPages[i] == end + 1) {
        end = sortedPages[i];
      } else {
        ranges.add(start == end ? '$start' : '$start-$end');
        start = sortedPages[i];
        end = sortedPages[i];
      }
    }
    ranges.add(start == end ? '$start' : '$start-$end');
    
    return ranges.join(', ');
  }

  /// Build file item widget for the file list
  Widget _buildFileItem({
    required Key key,
    required PDFFileData file,
    required int index,
    required ColorScheme colorScheme,
    required bool showReorderHandle,
  }) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          // Drag handle for reordering
          if (showReorderHandle)
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.drag_handle, color: Colors.grey),
              ),
            ),
          
          const Icon(Icons.picture_as_pdf, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
                if (file.pageCount > 0)
                  Text(
                    '${file.pageCount} pages',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
              ],
            ),
          ),
          
          // Page count badge
          if (file.pageCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${file.pageCount}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
            onPressed: () => _removeFile(index),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  /// Build quick extract chip
  Widget _buildQuickExtractChip(int pageNumber, ColorScheme colorScheme) {
    return ActionChip(
      label: Text('Page $pageNumber'),
      avatar: const Icon(Icons.content_cut, size: 16),
      onPressed: () => _extractSinglePage(pageNumber),
      backgroundColor: colorScheme.secondaryContainer,
      labelStyle: TextStyle(
        fontSize: 12,
        color: colorScheme.onSecondaryContainer,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Split & Merge'),
        centerTitle: true,
        actions: const [
          HelpIconButton(
            title: 'Split & Merge',
            icon: Icons.call_split_rounded,
            iconColor: Color(0xFF8B5CF6),
            helpText: 'Split PDF:\n'
                '1. Select a PDF file\n'
                '2. Choose "Split" mode\n'
                '3. Enter page ranges (e.g., 1-3, 5, 7-10)\n'
                '4. Tap Split to extract pages\n\n'
                'Merge PDFs:\n'
                '1. Select multiple PDF files\n'
                '2. Reorder by dragging if needed\n'
                '3. Tap Merge to combine them',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Mode Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _mode = PDFMode.split;
                              _reset();
                            });
                          },
                          icon: const Icon(Icons.content_cut),
                          label: const Text('Split PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _mode == PDFMode.split
                                ? colorScheme.primary
                                : colorScheme.surface,
                            foregroundColor: _mode == PDFMode.split
                                ? colorScheme.onPrimary
                                : colorScheme.onSurface,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _mode = PDFMode.merge;
                              _reset();
                            });
                          },
                          icon: const Icon(Icons.merge_type),
                          label: const Text('Merge PDFs'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _mode == PDFMode.merge
                                ? colorScheme.primary
                                : colorScheme.surface,
                            foregroundColor: _mode == PDFMode.merge
                                ? colorScheme.onPrimary
                                : colorScheme.onSurface,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // File Upload
              Card(
                child: InkWell(
                  onTap: _pickFiles,
                  child: Container(
                    height: 140,
                    decoration: BoxDecoration(
                      border: Border.all(color: colorScheme.primary, width: 2, style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.upload_file, size: 48, color: colorScheme.primary),
                        const SizedBox(height: 8),
                        Text(
                          _mode == PDFMode.split
                              ? 'Upload PDF to Split'
                              : 'Upload PDFs to Merge',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _mode == PDFMode.split
                              ? 'Single file only'
                              : 'Multiple files supported',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Uploaded Files
              if (_files.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Uploaded Files (${_files.length})',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            // Show total pages for merge mode
                            if (_mode == PDFMode.merge)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_files.fold<int>(0, (sum, f) => sum + f.pageCount)} total pages',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        // Drag & drop hint for merge mode
                        if (_mode == PDFMode.merge && _files.length > 1)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              '💡 Drag files to reorder',
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.primary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        
                        // File list with drag support for merge mode
                        if (_mode == PDFMode.merge && _files.length > 1)
                          ReorderableListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _files.length,
                            onReorder: (oldIndex, newIndex) {
                              setState(() {
                                if (newIndex > oldIndex) newIndex--;
                                final item = _files.removeAt(oldIndex);
                                _files.insert(newIndex, item);
                              });
                            },
                            itemBuilder: (context, index) {
                              final file = _files[index];
                              return _buildFileItem(
                                key: ValueKey('${file.path}_$index'),
                                file: file,
                                index: index,
                                colorScheme: colorScheme,
                                showReorderHandle: true,
                              );
                            },
                          )
                        else
                          ...List.generate(_files.length, (index) {
                            final file = _files[index];
                            return _buildFileItem(
                              key: ValueKey('${file.path}_$index'),
                              file: file,
                              index: index,
                              colorScheme: colorScheme,
                              showReorderHandle: false,
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              
              // Compress option for merge mode - placed right after file list
              if (_mode == PDFMode.merge && _files.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Card(
                    child: CheckboxListTile(
                      value: _compressOnMerge,
                      onChanged: (value) {
                        setState(() {
                          _compressOnMerge = value ?? false;
                        });
                      },
                      title: const Text(
                        'Compress while merging',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        'Reduces file size (may slightly affect quality)',
                        style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color),
                      ),
                      secondary: Icon(
                        Icons.compress,
                        color: _compressOnMerge ? colorScheme.primary : Colors.grey,
                      ),
                      controlAffinity: ListTileControlAffinity.trailing,
                    ),
                  ),
                ),

              // PDF Page Preview (for split mode)
              if (_mode == PDFMode.split && _files.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: PdfPagePreview(
                    pdfBytes: _files[0].bytes,
                    selectedPages: _selectedPages,
                    onSelectionChanged: _onPageSelectionChanged,
                    allowMultiSelect: true,
                  ),
                ),

              const SizedBox(height: 12),

              // Split Options
              if (_mode == PDFMode.split && _files.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Page count badge
                        if (_totalPages > 0)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.pages, size: 16, color: colorScheme.onPrimaryContainer),
                                const SizedBox(width: 6),
                                Text(
                                  'Total: $_totalPages pages',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        // Quick Extract Buttons
                        if (_totalPages > 0) ...[
                          const Text(
                            'Quick Extract',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (int i = 1; i <= (_totalPages > 5 ? 5 : _totalPages); i++)
                                _buildQuickExtractChip(i, colorScheme),
                              if (_totalPages > 5)
                                ActionChip(
                                  label: const Text('Last Page'),
                                  avatar: const Icon(Icons.last_page, size: 16),
                                  onPressed: () => _extractSinglePage(_totalPages),
                                  backgroundColor: colorScheme.tertiaryContainer,
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onTertiaryContainer,
                                  ),
                                ),
                            ],
                          ),
                          const Divider(height: 24),
                        ],
                        
                        const Text(
                          'Custom Page Ranges',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _rangeController,
                          decoration: InputDecoration(
                            hintText: 'e.g., 1-3, 5, 7-9',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Enter page numbers or ranges separated by commas (or tap pages in preview)',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Error Message
              if (_errorMessage.isNotEmpty)
                Card(
                  color: colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage,
                            style: TextStyle(color: colorScheme.onErrorContainer),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Success Message
              if (_successMessage.isNotEmpty)
                Card(
                  color: colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle, color: colorScheme.onPrimaryContainer),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _successMessage,
                                style: TextStyle(
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...List.generate(_resultFiles.length, (index) {
                          final filePath = _resultFiles[index];
                          final fileName = filePath.split('/').last;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        fileName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        filePath,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: colorScheme.onSurface.withOpacity(0.6),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.visibility, size: 20),
                                  onPressed: () => _openPdf(filePath),
                                  tooltip: 'Open PDF',
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => _shareFile(filePath),
                                  icon: const Icon(Icons.share, size: 16),
                                  label: const Text('Share'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.primary,
                                    foregroundColor: colorScheme.onPrimary,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _reset,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.secondary,
                              foregroundColor: colorScheme.onSecondary,
                            ),
                            child: const Text('Process Another PDF'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Process Button
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _processing || _files.isEmpty
                      ? null
                      : (_mode == PDFMode.split ? _splitPDF : _mergePDFs),
                  icon: _processing
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                            value: _progress > 0 ? _progress : null, // Show progress if available
                          ),
                        )
                      : Icon(_mode == PDFMode.split
                          ? Icons.content_cut
                          : Icons.merge_type),
                  label: Text(
                    _processing
                        ? (_mode == PDFMode.split ? 'Splitting PDF...' : 'Merging PDFs...')
                        : (_mode == PDFMode.split ? 'Split PDF' : 'Merge PDFs'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    disabledBackgroundColor: colorScheme.onSurface.withOpacity(0.38),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Instructions
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'How to Use',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInstruction('Split PDF', [
                        'Upload a single PDF file',
                        'Enter page ranges (e.g., 1-3, 5, 7-9)',
                        'Click "Split PDF" to create separate files',
                      ]),
                      const SizedBox(height: 12),
                      _buildInstruction('Merge PDFs', [
                        'Upload multiple PDF files',
                        'Reorder files using ↑ ↓ buttons',
                        'Click "Merge PDFs" to combine them',
                      ]),
                    ],
                  ),
                ),
              ),
              
              // Banner Ad at bottom
              const SizedBox(height: 16),
              const BannerAdWidget(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstruction(String title, List<String> steps) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        ...steps.map((step) => Padding(
          padding: const EdgeInsets.only(left: 8, top: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• ', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7))),
              Expanded(
                child: Text(
                  step,
                  style: TextStyle(
                    fontSize: 13, 
                    color: colorScheme.onSurface.withOpacity(0.7)
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}

enum PDFMode { split, merge }

class PDFFileData {
  final String name;
  final String path;
  final Uint8List bytes;
  final int pageCount;

  PDFFileData({
    required this.name,
    required this.path,
    required this.bytes,
    this.pageCount = 0,
  });
}

class PDFDocument {
  int pagesCount = 0;
  
  Future<void> load(Uint8List bytes) async {
    try {
      // Load the PDF document using Syncfusion to get the actual page count
      final pdf = syncfusion.PdfDocument(inputBytes: bytes);
      pagesCount = pdf.pages.count;
      pdf.dispose();
    } catch (e) {
      // Fallback to placeholder value if there's an error
      pagesCount = 5;
    }
  }
}
