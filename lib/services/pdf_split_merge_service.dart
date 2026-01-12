import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart'; // Add for ValueChanged
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as syncfusion;
import '../models/page_range.dart';

class PDFSplitMergeService {
  /// Parse split ranges string into PageRange objects
  static List<PageRange> parseSplitRanges(String ranges, int totalPages) {
    final parts = ranges.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
    final result = <PageRange>[];

    for (var part in parts) {
      if (part.contains('-')) {
        final split = part.split('-');
        if (split.length != 2) {
          throw Exception('Invalid range format: $part');
        }
        final start = int.tryParse(split[0].trim());
        final end = int.tryParse(split[1].trim());

        if (start == null || end == null || start < 1 || end > totalPages || start > end) {
          throw Exception('Invalid range: $part (Total pages: $totalPages)');
        }
        result.add(PageRange(start - 1, end - 1));
      } else {
        final page = int.tryParse(part);
        if (page == null || page < 1 || page > totalPages) {
          throw Exception('Invalid page: $part (Total pages: $totalPages)');
        }
        result.add(PageRange(page - 1, page - 1));
      }
    }

    return result;
  }

  /// Split a PDF file into multiple parts based on page ranges
  static Future<List<String>> splitPDF(
    Uint8List inputBytes, 
    List<PageRange> ranges, 
    String fileName,
    ValueChanged<double>? onProgress, // Add progress callback
  ) async {
    final resultFiles = <String>[];
    
    try {
      // Load the PDF document using Syncfusion
      final syncfusion.PdfDocument inputPdf = syncfusion.PdfDocument(inputBytes: inputBytes);
      final totalPages = inputPdf.pages.count;
      
      // Report initial progress
      onProgress?.call(0.1);
      
      for (int i = 0; i < ranges.length; i++) {
        final range = ranges[i];
        
        // Create a new PDF document for this range
        final syncfusion.PdfDocument outputPdf = syncfusion.PdfDocument();
        syncfusion.PdfSection? section;
        
        // Copy pages from the input PDF to the output PDF
        for (int pageNum = range.start; pageNum <= range.end; pageNum++) {
          if (pageNum < totalPages) {
            // Create a template from the source page
            final syncfusion.PdfTemplate template = inputPdf.pages[pageNum].createTemplate();
            
            // Create a new section if the page settings are different or if it's the first page
            if (section == null || 
                section.pageSettings.size.width != template.size.width || 
                section.pageSettings.size.height != template.size.height) {
              section = outputPdf.sections!.add();
              section.pageSettings.size = template.size;
              section.pageSettings.margins.all = 0;
            }
            
            // Draw the page template to the new document
            section.pages.add().graphics.drawPdfTemplate(
              template, 
              const ui.Offset(0, 0)
            );
          }
        }

        // Report progress for this file
        final progress = 0.1 + (0.8 * (i + 1) / ranges.length);
        onProgress?.call(progress);

        // Save the document
        final List<int> bytes = await outputPdf.save();
        final newFileName = fileName.replaceAll('.pdf', '_part${i + 1}.pdf');
        final filePath = await _savePDF(bytes, newFileName);
        resultFiles.add(filePath);
        
        // Dispose of the output document
        outputPdf.dispose();
      }
      
      // Report final progress
      onProgress?.call(0.9);
      
      // Dispose of the input document
      inputPdf.dispose();
      
      // Report completion
      onProgress?.call(1.0);
    } catch (e) {
      throw Exception('Error splitting PDF: $e');
    }

    return resultFiles;
  }

  /// Merge multiple PDF files into one
  static Future<String> mergePDFs(
    List<Uint8List> pdfBytesList, 
    List<String> fileNames,
    ValueChanged<double>? onProgress, // Add progress callback
  ) async {
    try {
      // Create a new PDF document
      final syncfusion.PdfDocument outputPdf = syncfusion.PdfDocument();
      syncfusion.PdfSection? section;

      // Report initial progress
      onProgress?.call(0.1);

      // Merge all input PDFs
      for (int i = 0; i < pdfBytesList.length; i++) {
        final syncfusion.PdfDocument inputPdf = syncfusion.PdfDocument(inputBytes: pdfBytesList[i]);
        
        // Copy all pages from the input PDF to the output PDF
        for (int pageNum = 0; pageNum < inputPdf.pages.count; pageNum++) {
          // Create a template from the source page
          final syncfusion.PdfTemplate template = inputPdf.pages[pageNum].createTemplate();
          
          // Create a new section if the page settings are different or if it's the first page
          if (section == null || 
              section.pageSettings.size.width != template.size.width || 
              section.pageSettings.size.height != template.size.height) {
            section = outputPdf.sections!.add();
            section.pageSettings.size = template.size;
            section.pageSettings.margins.all = 0;
          }
          
          // Draw the page template to the new document
          section.pages.add().graphics.drawPdfTemplate(
            template, 
            const ui.Offset(0, 0)
          );
        }
        
        // Report progress for this file
        final progress = 0.1 + (0.8 * (i + 1) / pdfBytesList.length);
        onProgress?.call(progress);
        
        // Dispose of the input document
        inputPdf.dispose();
      }

      // Report progress before saving
      onProgress?.call(0.9);

      // Save the document
      final List<int> bytes = await outputPdf.save();
      final fileName = 'merged_document.pdf';
      final filePath = await _savePDF(bytes, fileName);
      
      // Report completion
      onProgress?.call(1.0);
      
      // Dispose of the output document
      outputPdf.dispose();
      
      return filePath;
    } catch (e) {
      throw Exception('Error merging PDFs: $e');
    }
  }

  /// Save a PDF document to storage
  static Future<String> _savePDF(List<int> bytes, String fileName) async {
    Directory? directory;
    if (Platform.isAndroid) {
      await Permission.storage.request();
      directory = await getExternalStorageDirectory();
    } else if (Platform.isIOS) {
      directory = await getApplicationDocumentsDirectory();
    } else {
      directory = await getDownloadsDirectory();
    }

    // Ensure the directory exists
    if (!await directory!.exists()) {
      await directory.create(recursive: true);
    }

    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  }
  
  /// Get file size in bytes
  static Future<int> getFileSize(String filePath) async {
    final file = File(filePath);
    return await file.length();
  }
}