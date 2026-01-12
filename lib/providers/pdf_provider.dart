import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart'; // Import BuildContext
import 'package:provider/provider.dart';

import '../database/database_helper.dart';
import '../models/pdf_file_model.dart';
import '../models/recent_activity_model.dart';
import '../providers/settings_provider.dart';
import '../utils/logger.dart';
import '../utils/pdf_utils.dart';

class PdfProvider extends ChangeNotifier {
  PdfProvider() {
    loadPdfHistory();
    loadRecentActivities();
  }
  final List<File> _selectedImages = [];
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<File> get selectedImages => _selectedImages;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  double _conversionProgress = 0;
  double get conversionProgress => _conversionProgress;

  List<PdfFileModel> _pdfHistory = [];
  List<PdfFileModel> get pdfHistory => _pdfHistory;
  List<PdfFileModel> get pdfFiles => _pdfHistory;

  List<RecentActivityModel> _recentActivities = [];
  List<RecentActivityModel> get recentActivities => _recentActivities;

  Future<void> initialize() async {
    await loadPdfHistory();
    await loadRecentActivities();
  }

  Future<void> loadPdfHistory() async {
    List<PdfFileModel> pdfs = [];
    try {
      pdfs = await _dbHelper.getAllPdfs();
    } catch (e) {
      Logger.e('Error getting all PDFs', e);
      pdfs = [];
    }

    // Process metadata loading in background to avoid blocking UI
    if (pdfs.isNotEmpty) {
      // Use compute for heavy operations
      final processedPdfs = await compute(_loadPdfMetadata, pdfs);
      _pdfHistory = processedPdfs;
    } else {
      _pdfHistory = pdfs;
    }
    
    notifyListeners();
  }

  /// Load PDF metadata in isolate
  static List<PdfFileModel> _loadPdfMetadata(List<PdfFileModel> pdfs) {
    // This is a simplified version - in a real app, you'd do actual metadata loading here
    // For now, we'll just return the pdfs as-is to demonstrate the pattern
    return pdfs;
  }

  Future<void> loadRecentActivities() async {
    try {
      // Limit to 5 most recent activities
      _recentActivities = await _dbHelper.getRecentActivities(limit: 5);
      notifyListeners();
    } catch (e) {
      Logger.e('Error loading recent activities', e);
      _recentActivities = [];
      notifyListeners();
    }
  }

  void addImages(List<File> images) {
    _selectedImages.addAll(images);
    notifyListeners();
  }

  void removeImage(int index) {
    _selectedImages.removeAt(index);
    notifyListeners();
  }

  void clearImages() {
    _selectedImages.clear();
    notifyListeners();
  }

  void replaceImage(int index, File newImage) {
    if (index >= 0 && index < _selectedImages.length) {
      _selectedImages[index] = newImage;
      notifyListeners();
    }
  }

  void reorderImages(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = _selectedImages.removeAt(oldIndex);
    _selectedImages.insert(newIndex, item);
    notifyListeners();
  }

  Future<PdfFileModel?> convertToPdf(String fileName, BuildContext context) async {
    if (_selectedImages.isEmpty) return null;

    _isLoading = true;
    _conversionProgress = 0.0;
    notifyListeners();

    try {
      // Get settings from provider
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      
      final result = await PdfUtils.createPdfFromImages(
        imageFiles: _selectedImages,
        fileName: fileName,
        autoEnhance: settings.autoEnhance,
        autoRotate: settings.autoRotate,
        pageSize: settings.pageSize,
        imageQuality: settings.imageQuality,
        saveLocation: settings.saveLocation, // Pass save location
        onProgress: (progress) {
          _conversionProgress = progress;
          notifyListeners();
        },
      );

      _isLoading = false;
      _conversionProgress = 0.0;
      notifyListeners();

      return result;
    } catch (e) {
      _isLoading = false;
      _conversionProgress = 0.0;
      notifyListeners();
      return null;
    }
  }

  Future<void> refreshHistory() async {
    await loadPdfHistory();
    await loadRecentActivities();
  }

  Future<bool> insertPdf(PdfFileModel pdf) async {
    try {
      await _dbHelper.insertPdf(pdf);
      await loadPdfHistory(); // Refresh in background
      await loadRecentActivities(); // Also refresh recent activities
      return true;
    } catch (e) {
      Logger.e('Error inserting PDF to database', e);
      return false;
    }
  }

  Future<void> loadPdfFiles() async {
    await loadPdfHistory();
  }

  Future<void> addPdfFile(File file) async {
    try {
      // Get file size in isolate to avoid blocking UI
      final fileSize = await compute(_getFileSize, file.path);
      
      final pdfModel = PdfFileModel(
        name: file.path.split('/').last,
        path: file.path,
        size: fileSize,
        createdAt: DateTime.now(),
      );
      await insertPdf(pdfModel);
    } catch (e) {
      Logger.e('Error adding PDF file', e);
    }
  }

  /// Get file size in isolate
  static int _getFileSize(String filePath) {
    try {
      final file = File(filePath);
      return file.lengthSync();
    } catch (e) {
      return 0;
    }
  }

  // Recent Activity Methods

  Future<void> addRecentActivity(String pdfId, String action) async {
    try {
      final activity = RecentActivityModel(
        pdfId: pdfId,
        action: action,
      );
      await _dbHelper.insertRecentActivity(activity);
      await loadRecentActivities(); // Refresh the list
    } catch (e) {
      Logger.e('Error adding recent activity', e);
    }
  }

  Future<void> openPdf(PdfFileModel pdf) async {
    // Add to recent activity
    await addRecentActivity(pdf.id, 'opened');

    // You can add additional logic here for opening the PDF
    // For example, using a PDF viewer package
  }

  // Delete PDF from database
  Future<void> deletePdf(String id) async {
    try {
      await _dbHelper.deletePdf(id);
      await loadPdfHistory();
      await loadRecentActivities();
    } catch (e) {
      Logger.e('Error deleting PDF', e);
    }
  }
}