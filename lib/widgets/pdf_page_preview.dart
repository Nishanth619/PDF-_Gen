import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

/// Widget to display PDF page thumbnails with selection capability
class PdfPagePreview extends StatefulWidget {
  final Uint8List pdfBytes;
  final Set<int> selectedPages;
  final Function(Set<int>) onSelectionChanged;
  final bool allowMultiSelect;

  const PdfPagePreview({
    super.key,
    required this.pdfBytes,
    required this.selectedPages,
    required this.onSelectionChanged,
    this.allowMultiSelect = true,
  });

  @override
  State<PdfPagePreview> createState() => _PdfPagePreviewState();
}

class _PdfPagePreviewState extends State<PdfPagePreview> {
  PdfDocument? _document;
  List<PdfPageImage?> _pageImages = [];
  bool _loading = true;
  String? _error;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  @override
  void didUpdateWidget(PdfPagePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pdfBytes != widget.pdfBytes) {
      _loadPdf();
    }
  }

  Future<void> _loadPdf() async {
    setState(() {
      _loading = true;
      _error = null;
      _pageImages = [];
    });

    try {
      _document = await PdfDocument.openData(widget.pdfBytes);
      _totalPages = _document!.pagesCount;
      
      // Load thumbnails for all pages
      final List<PdfPageImage?> images = [];
      for (int i = 1; i <= _totalPages; i++) {
        try {
          final page = await _document!.getPage(i);
          final pageImage = await page.render(
            width: page.width * 0.3, // Thumbnail size
            height: page.height * 0.3,
            format: PdfPageImageFormat.png,
          );
          await page.close();
          images.add(pageImage);
        } catch (e) {
          images.add(null);
        }
        
        // Update UI after each page load
        if (mounted) {
          setState(() {
            _pageImages = List.from(images);
          });
        }
      }

      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load PDF: $e';
          _loading = false;
        });
      }
    }
  }

  void _togglePage(int pageNumber) {
    final newSelection = Set<int>.from(widget.selectedPages);
    
    if (newSelection.contains(pageNumber)) {
      newSelection.remove(pageNumber);
    } else {
      if (!widget.allowMultiSelect) {
        newSelection.clear();
      }
      newSelection.add(pageNumber);
    }
    
    widget.onSelectionChanged(newSelection);
  }

  void _selectAll() {
    final allPages = Set<int>.from(List.generate(_totalPages, (i) => i + 1));
    widget.onSelectionChanged(allPages);
  }

  void _deselectAll() {
    widget.onSelectionChanged({});
  }

  void _selectRange(int start, int end) {
    final rangePages = Set<int>.from(
      List.generate(end - start + 1, (i) => start + i)
    );
    widget.onSelectionChanged(rangePages);
  }

  @override
  void dispose() {
    _document?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_error != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with page count and actions
            Row(
              children: [
                Icon(Icons.pages, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Page Preview',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                if (!_loading)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$_totalPages pages',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                const Spacer(),
                if (!_loading && widget.allowMultiSelect) ...[
                  TextButton(
                    onPressed: _selectAll,
                    child: const Text('All', style: TextStyle(fontSize: 12)),
                  ),
                  TextButton(
                    onPressed: _deselectAll,
                    child: const Text('None', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ],
            ),
            
            // Selected pages indicator
            if (widget.selectedPages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 4,
                  children: [
                    Text(
                      'Selected: ',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    Text(
                      _formatSelectedPages(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 12),
            
            // Page thumbnails grid
            if (_loading && _pageImages.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Loading pages...'),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _totalPages,
                  itemBuilder: (context, index) {
                    final pageNumber = index + 1;
                    final isSelected = widget.selectedPages.contains(pageNumber);
                    final pageImage = index < _pageImages.length ? _pageImages[index] : null;
                    
                    return GestureDetector(
                      onTap: () => _togglePage(pageNumber),
                      child: Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected 
                                ? colorScheme.primary 
                                : Colors.grey.shade300,
                            width: isSelected ? 3 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: isSelected 
                              ? colorScheme.primaryContainer.withOpacity(0.3)
                              : Colors.white,
                        ),
                        child: Column(
                          children: [
                            // Page thumbnail
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(7),
                                ),
                                child: pageImage?.bytes != null
                                    ? Image.memory(
                                        pageImage!.bytes,
                                        fit: BoxFit.contain,
                                      )
                                    : Container(
                                        color: Colors.grey.shade200,
                                        child: Center(
                                          child: _loading
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                  ),
                                                )
                                              : Icon(
                                                  Icons.insert_drive_file,
                                                  color: Colors.grey.shade400,
                                                ),
                                        ),
                                      ),
                              ),
                            ),
                            
                            // Page number
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? colorScheme.primary
                                    : Colors.grey.shade100,
                                borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(7),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  if (isSelected) const SizedBox(width: 4),
                                  Text(
                                    'Page $pageNumber',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected 
                                          ? Colors.white
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              
            // Loading progress
            if (_loading && _pageImages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(
                  value: _pageImages.length / _totalPages,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatSelectedPages() {
    if (widget.selectedPages.isEmpty) return 'None';
    
    final pages = widget.selectedPages.toList()..sort();
    
    // Convert to ranges for cleaner display
    List<String> ranges = [];
    int start = pages[0];
    int end = pages[0];
    
    for (int i = 1; i < pages.length; i++) {
      if (pages[i] == end + 1) {
        end = pages[i];
      } else {
        ranges.add(start == end ? '$start' : '$start-$end');
        start = pages[i];
        end = pages[i];
      }
    }
    ranges.add(start == end ? '$start' : '$start-$end');
    
    return ranges.join(', ');
  }
}
