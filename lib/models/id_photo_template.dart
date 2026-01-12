/// ID Photo template data for different countries and document types
class IdPhotoTemplate {
  final String id;
  final String name;
  final String country;
  final String countryCode;
  final double widthMm;
  final double heightMm;
  final String backgroundColor;
  final String documentType;
  final String? notes;

  const IdPhotoTemplate({
    required this.id,
    required this.name,
    required this.country,
    required this.countryCode,
    required this.widthMm,
    required this.heightMm,
    required this.backgroundColor,
    required this.documentType,
    this.notes,
  });

  /// Get size in inches
  double get widthInches => widthMm / 25.4;
  double get heightInches => heightMm / 25.4;

  /// Get aspect ratio
  double get aspectRatio => widthMm / heightMm;

  /// Get display size text
  String get sizeText => '${widthMm.toInt()}x${heightMm.toInt()} mm';

  /// Get size in pixels at given DPI
  int widthPixels(int dpi) => (widthInches * dpi).round();
  int heightPixels(int dpi) => (heightInches * dpi).round();
}

/// Predefined templates for different countries
class IdPhotoTemplates {
  static const List<IdPhotoTemplate> all = [
    // United States
    IdPhotoTemplate(
      id: 'us_passport',
      name: 'US Passport',
      country: 'United States',
      countryCode: 'US',
      widthMm: 51,
      heightMm: 51,
      backgroundColor: 'white',
      documentType: 'Passport',
      notes: '2x2 inches, head 25-35mm',
    ),
    IdPhotoTemplate(
      id: 'us_visa',
      name: 'US Visa',
      country: 'United States',
      countryCode: 'US',
      widthMm: 51,
      heightMm: 51,
      backgroundColor: 'white',
      documentType: 'Visa',
    ),

    // India
    IdPhotoTemplate(
      id: 'india_passport',
      name: 'India Passport',
      country: 'India',
      countryCode: 'IN',
      widthMm: 35,
      heightMm: 45,
      backgroundColor: 'white',
      documentType: 'Passport',
      notes: 'Face 70-80% of photo',
    ),
    IdPhotoTemplate(
      id: 'india_visa',
      name: 'India Visa',
      country: 'India',
      countryCode: 'IN',
      widthMm: 51,
      heightMm: 51,
      backgroundColor: 'white',
      documentType: 'Visa',
    ),
    IdPhotoTemplate(
      id: 'india_aadhaar',
      name: 'Aadhaar Card',
      country: 'India',
      countryCode: 'IN',
      widthMm: 35,
      heightMm: 45,
      backgroundColor: 'white',
      documentType: 'ID Card',
    ),
    IdPhotoTemplate(
      id: 'india_pan',
      name: 'PAN Card',
      country: 'India',
      countryCode: 'IN',
      widthMm: 35,
      heightMm: 45,
      backgroundColor: 'white',
      documentType: 'ID Card',
    ),

    // United Kingdom
    IdPhotoTemplate(
      id: 'uk_passport',
      name: 'UK Passport',
      country: 'United Kingdom',
      countryCode: 'GB',
      widthMm: 35,
      heightMm: 45,
      backgroundColor: 'white',
      documentType: 'Passport',
    ),

    // Schengen/Europe
    IdPhotoTemplate(
      id: 'schengen_visa',
      name: 'Schengen Visa',
      country: 'Europe',
      countryCode: 'EU',
      widthMm: 35,
      heightMm: 45,
      backgroundColor: 'white',
      documentType: 'Visa',
      notes: 'ICAO standard',
    ),

    // China
    IdPhotoTemplate(
      id: 'china_passport',
      name: 'China Passport',
      country: 'China',
      countryCode: 'CN',
      widthMm: 33,
      heightMm: 48,
      backgroundColor: 'white',
      documentType: 'Passport',
    ),
    IdPhotoTemplate(
      id: 'china_visa',
      name: 'China Visa',
      country: 'China',
      countryCode: 'CN',
      widthMm: 33,
      heightMm: 48,
      backgroundColor: 'white',
      documentType: 'Visa',
    ),

    // Japan
    IdPhotoTemplate(
      id: 'japan_passport',
      name: 'Japan Passport',
      country: 'Japan',
      countryCode: 'JP',
      widthMm: 35,
      heightMm: 45,
      backgroundColor: 'white',
      documentType: 'Passport',
    ),
    IdPhotoTemplate(
      id: 'japan_visa',
      name: 'Japan Visa',
      country: 'Japan',
      countryCode: 'JP',
      widthMm: 45,
      heightMm: 45,
      backgroundColor: 'white',
      documentType: 'Visa',
    ),

    // Canada
    IdPhotoTemplate(
      id: 'canada_passport',
      name: 'Canada Passport',
      country: 'Canada',
      countryCode: 'CA',
      widthMm: 50,
      heightMm: 70,
      backgroundColor: 'white',
      documentType: 'Passport',
    ),

    // Australia
    IdPhotoTemplate(
      id: 'australia_passport',
      name: 'Australia Passport',
      country: 'Australia',
      countryCode: 'AU',
      widthMm: 35,
      heightMm: 45,
      backgroundColor: 'white',
      documentType: 'Passport',
    ),

    // UAE
    IdPhotoTemplate(
      id: 'uae_passport',
      name: 'UAE Passport',
      country: 'UAE',
      countryCode: 'AE',
      widthMm: 43,
      heightMm: 55,
      backgroundColor: 'white',
      documentType: 'Passport',
    ),
    IdPhotoTemplate(
      id: 'uae_visa',
      name: 'UAE Visa',
      country: 'UAE',
      countryCode: 'AE',
      widthMm: 43,
      heightMm: 55,
      backgroundColor: 'white',
      documentType: 'Visa',
    ),

    // Singapore
    IdPhotoTemplate(
      id: 'singapore_passport',
      name: 'Singapore Passport',
      country: 'Singapore',
      countryCode: 'SG',
      widthMm: 35,
      heightMm: 45,
      backgroundColor: 'white',
      documentType: 'Passport',
    ),

    // Malaysia
    IdPhotoTemplate(
      id: 'malaysia_passport',
      name: 'Malaysia Passport',
      country: 'Malaysia',
      countryCode: 'MY',
      widthMm: 35,
      heightMm: 50,
      backgroundColor: 'blue',
      documentType: 'Passport',
    ),

    // Thailand
    IdPhotoTemplate(
      id: 'thailand_passport',
      name: 'Thailand Passport',
      country: 'Thailand',
      countryCode: 'TH',
      widthMm: 35,
      heightMm: 45,
      backgroundColor: 'white',
      documentType: 'Passport',
    ),

    // South Korea
    IdPhotoTemplate(
      id: 'korea_passport',
      name: 'South Korea Passport',
      country: 'South Korea',
      countryCode: 'KR',
      widthMm: 35,
      heightMm: 45,
      backgroundColor: 'white',
      documentType: 'Passport',
    ),

    // Russia
    IdPhotoTemplate(
      id: 'russia_passport',
      name: 'Russia Passport',
      country: 'Russia',
      countryCode: 'RU',
      widthMm: 35,
      heightMm: 45,
      backgroundColor: 'white',
      documentType: 'Passport',
    ),

    // Brazil
    IdPhotoTemplate(
      id: 'brazil_passport',
      name: 'Brazil Passport',
      country: 'Brazil',
      countryCode: 'BR',
      widthMm: 50,
      heightMm: 70,
      backgroundColor: 'white',
      documentType: 'Passport',
    ),

    // Mexico
    IdPhotoTemplate(
      id: 'mexico_passport',
      name: 'Mexico Passport',
      country: 'Mexico',
      countryCode: 'MX',
      widthMm: 35,
      heightMm: 45,
      backgroundColor: 'white',
      documentType: 'Passport',
    ),

    // Generic
    IdPhotoTemplate(
      id: 'generic_35x45',
      name: 'Standard (35x45mm)',
      country: 'International',
      countryCode: 'INT',
      widthMm: 35,
      heightMm: 45,
      backgroundColor: 'white',
      documentType: 'General',
      notes: 'Most common size worldwide',
    ),
    IdPhotoTemplate(
      id: 'generic_2x2',
      name: 'Square (2x2 inch)',
      country: 'International',
      countryCode: 'INT',
      widthMm: 51,
      heightMm: 51,
      backgroundColor: 'white',
      documentType: 'General',
      notes: 'Common for US documents',
    ),
  ];

  /// Get templates by country
  static List<IdPhotoTemplate> getByCountry(String countryCode) {
    return all.where((t) => t.countryCode == countryCode).toList();
  }

  /// Get templates by document type
  static List<IdPhotoTemplate> getByType(String documentType) {
    return all.where((t) => t.documentType == documentType).toList();
  }

  /// Get unique countries
  static List<String> get countries {
    return all.map((t) => t.country).toSet().toList()..sort();
  }

  /// Get popular templates (most commonly used)
  static List<IdPhotoTemplate> get popular {
    return [
      all.firstWhere((t) => t.id == 'us_passport'),
      all.firstWhere((t) => t.id == 'india_passport'),
      all.firstWhere((t) => t.id == 'uk_passport'),
      all.firstWhere((t) => t.id == 'schengen_visa'),
      all.firstWhere((t) => t.id == 'generic_35x45'),
    ];
  }
}

/// Background colors for ID photos
class IdPhotoBackgroundColors {
  static const Map<String, int> colors = {
    'white': 0xFFFFFFFF,
    'light_blue': 0xFFE3F2FD,
    'blue': 0xFF2196F3,
    'red': 0xFFF44336,
    'light_gray': 0xFFF5F5F5,
    'gray': 0xFF9E9E9E,
  };

  static int getColor(String name) {
    return colors[name] ?? colors['white']!;
  }

  static List<String> get names => colors.keys.toList();
}

/// Print layout sizes
class PrintLayouts {
  static const Map<String, Map<String, double>> layouts = {
    '4x6': {'width': 101.6, 'height': 152.4}, // mm
    '5x7': {'width': 127.0, 'height': 177.8},
    '6x4': {'width': 152.4, 'height': 101.6},
    'A4': {'width': 210.0, 'height': 297.0},
    'Letter': {'width': 215.9, 'height': 279.4},
  };

  static Map<String, double>? getLayout(String name) {
    return layouts[name];
  }

  static List<String> get names => layouts.keys.toList();

  /// Calculate how many photos fit on a print layout
  static Map<String, int> calculateGrid(String layoutName, IdPhotoTemplate template) {
    final layout = layouts[layoutName];
    if (layout == null) return {'cols': 0, 'rows': 0, 'total': 0};

    final cols = (layout['width']! / (template.widthMm + 2)).floor(); // 2mm spacing
    final rows = (layout['height']! / (template.heightMm + 2)).floor();

    return {
      'cols': cols,
      'rows': rows,
      'total': cols * rows,
    };
  }
}
