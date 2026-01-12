import 'package:uuid/uuid.dart';
import 'pdf_file_model.dart';

/// Model class for recent activity
class RecentActivityModel {
  RecentActivityModel({
    String? id,
    required this.pdfId,
    required this.action,
    DateTime? timestamp,
    PdfFileModel? pdf, // Optional PDF model for convenience
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now(),
        pdf = pdf;

  /// Create from JSON
  factory RecentActivityModel.fromJson(Map<String, dynamic> json) {
    PdfFileModel? pdf;
    if (json.containsKey('pdf') && json['pdf'] != null) {
      if (json['pdf'] is Map<String, dynamic>) {
        pdf = PdfFileModel.fromJson(json['pdf'] as Map<String, dynamic>);
      }
    }

    return RecentActivityModel(
      id: json['id'] as String,
      pdfId: json['pdfId'] as String,
      action: json['action'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      pdf: pdf,
    );
  }

  final String id;
  final String pdfId;
  final String action; // e.g., "opened", "edited", "shared", "created"
  final DateTime timestamp;
  final PdfFileModel? pdf; // Optional embedded PDF model

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pdfId': pdfId,
      'action': action,
      'timestamp': timestamp.toIso8601String(),
      // Note: We don't include the PDF in the JSON for database storage
      // The PDF data is joined from the pdf_files table when retrieving
    };
  }

  /// Create a copy with updated fields
  RecentActivityModel copyWith({
    String? id,
    String? pdfId,
    String? action,
    DateTime? timestamp,
    PdfFileModel? pdf,
  }) {
    return RecentActivityModel(
      id: id ?? this.id,
      pdfId: pdfId ?? this.pdfId,
      action: action ?? this.action,
      timestamp: timestamp ?? this.timestamp,
      pdf: pdf ?? this.pdf,
    );
  }

  @override
  String toString() {
    return 'RecentActivityModel(id: $id, pdfId: $pdfId, action: $action, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RecentActivityModel &&
        other.id == id &&
        other.pdfId == pdfId &&
        other.action == action &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return id.hashCode ^ pdfId.hashCode ^ action.hashCode ^ timestamp.hashCode;
  }
}