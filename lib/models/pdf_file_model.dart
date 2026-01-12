
import 'package:uuid/uuid.dart';

/// Model class for PDF files
class PdfFileModel {

  PdfFileModel({
    String? id,
    required this.name,
    required this.path,
    required this.size,
    this.pageCount = 0, // Made optional with default value
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  /// Create from JSON
  factory PdfFileModel.fromJson(Map<String, dynamic> json) {
    return PdfFileModel(
      id: json['id'] as String,
      name: json['name'] as String,
      path: json['path'] as String,
      size: json['size'] as int,
      pageCount: json['pageCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
  final String id;
  final String name;
  final String path;
  final int size;
  final int pageCount;
  final DateTime createdAt;

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'size': size,
      'pageCount': pageCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  PdfFileModel copyWith({
    String? id,
    String? name,
    String? path,
    int? size,
    int? pageCount,
    DateTime? createdAt,
  }) {
    return PdfFileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      size: size ?? this.size,
      pageCount: pageCount ?? this.pageCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'PdfFileModel(id: $id, name: $name, path: $path, size: $size, pageCount: $pageCount, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PdfFileModel &&
        other.id == id &&
        other.name == name &&
        other.path == path &&
        other.size == size &&
        other.pageCount == pageCount &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        path.hashCode ^
        size.hashCode ^
        pageCount.hashCode ^
        createdAt.hashCode;
  }
}
