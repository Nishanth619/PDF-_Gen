import 'dart:isolate';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/pdf_file_model.dart';
import '../models/recent_activity_model.dart';

/// Database helper for managing PDF files
class DatabaseHelper {
  DatabaseHelper._init();
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  /// Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pdf_converter.db');
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return openDatabase(
      path,
      version: 2, // Updated version
      onCreate: _createDB,
      onUpgrade: _upgradeDB, // Added upgrade function
    );
  }

  /// Create database tables
  Future<void> _createDB(Database db, int version) async {
    // Create pdf_files table
    await db.execute('''
      CREATE TABLE pdf_files (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        path TEXT NOT NULL,
        size INTEGER NOT NULL,
        pageCount INTEGER NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    // Create recent_activity table for version 2+
    if (version >= 2) {
      await db.execute('''
        CREATE TABLE recent_activity (
          id TEXT PRIMARY KEY,
          pdfId TEXT NOT NULL,
          action TEXT NOT NULL,
          timestamp TEXT NOT NULL,
          FOREIGN KEY (pdfId) REFERENCES pdf_files (id) ON DELETE CASCADE
        )
      ''');
    }
  }

  /// Upgrade database
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Check if recent_activity table already exists
      final result = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='recent_activity'");
      
      // Only create the table if it doesn't exist
      if (result.isEmpty) {
        await db.execute('''
          CREATE TABLE recent_activity (
            id TEXT PRIMARY KEY,
            pdfId TEXT NOT NULL,
            action TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            FOREIGN KEY (pdfId) REFERENCES pdf_files (id) ON DELETE CASCADE
          )
        ''');
      }
    }
  }

  /// Insert PDF file
  Future<void> insertPdf(PdfFileModel pdf) async {
    final db = await database;
    await db.insert(
      'pdf_files',
      pdf.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all PDF files with multi-threading
  Future<List<PdfFileModel>> getAllPdfs() async {
    final db = await database;
    final result = await db.query(
      'pdf_files',
      orderBy: 'createdAt DESC',
    );

    // Process large result sets in isolate to avoid blocking UI
    if (result.length > 50) {
      return await compute(_processPdfList, result);
    } else {
      return result.map(PdfFileModel.fromJson).toList();
    }
  }

  /// Process PDF list in isolate
  static List<PdfFileModel> _processPdfList(List<Map<String, dynamic>> result) {
    return result.map(PdfFileModel.fromJson).toList();
  }

  /// Get PDF by ID
  Future<PdfFileModel?> getPdfById(String id) async {
    final db = await database;
    final result = await db.query(
      'pdf_files',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return PdfFileModel.fromJson(result.first);
    }
    return null;
  }

  /// Update PDF file
  Future<int> updatePdf(PdfFileModel pdf) async {
    final db = await database;
    return db.update(
      'pdf_files',
      pdf.toJson(),
      where: 'id = ?',
      whereArgs: [pdf.id],
    );
  }

  /// Delete PDF file
  Future<int> deletePdf(String id) async {
    final db = await database;
    // This will also delete related recent activities due to CASCADE
    return db.delete(
      'pdf_files',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete all PDF files
  Future<int> deleteAllPdfs() async {
    final db = await database;
    return db.delete('pdf_files');
  }

  /// Search PDF files by name with multi-threading
  Future<List<PdfFileModel>> searchPdfs(String query) async {
    final db = await database;
    final result = await db.query(
      'pdf_files',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'createdAt DESC',
    );

    // Process large result sets in isolate to avoid blocking UI
    if (result.length > 20) {
      return await compute(_processPdfList, result);
    } else {
      return result.map(PdfFileModel.fromJson).toList();
    }
  }

  /// Get PDF count
  Future<int> getPdfCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM pdf_files');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Recent Activity Methods

  /// Insert recent activity
  Future<void> insertRecentActivity(RecentActivityModel activity) async {
    final db = await database;
    await db.insert(
      'recent_activity',
      activity.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get recent activities with multi-threading
  Future<List<RecentActivityModel>> getRecentActivities({int limit = 5}) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT ra.*, p.name as pdfName, p.path as pdfPath, p.size as pdfSize, p.pageCount as pdfPageCount, p.createdAt as pdfCreatedAt
      FROM recent_activity ra
      LEFT JOIN pdf_files p ON ra.pdfId = p.id
      ORDER BY ra.timestamp DESC
      LIMIT ?
    ''', [limit]);

    // Process result in isolate for better performance
    return await compute(_processRecentActivities, result);
  }

  /// Process recent activities in isolate
  static List<RecentActivityModel> _processRecentActivities(List<Map<String, dynamic>> result) {
    return result.map((json) {
      // Extract PDF data if it exists
      PdfFileModel? pdf;
      if (json['pdfName'] != null) {
        final pdfJson = {
          'id': json['pdfId'],
          'name': json['pdfName'] as String,
          'path': json['pdfPath'] as String,
          'size': json['pdfSize'] as int,
          'pageCount': json['pdfPageCount'] as int,
          'createdAt': json['pdfCreatedAt'] as String,
        };
        pdf = PdfFileModel.fromJson(pdfJson);
      }

      return RecentActivityModel.fromJson({
        'id': json['id'] as String,
        'pdfId': json['pdfId'] as String,
        'action': json['action'] as String,
        'timestamp': json['timestamp'] as String,
        'pdf': pdf,
      });
    }).toList();
  }
}