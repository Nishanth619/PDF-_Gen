
/// Application constants
class AppConstants {
  // App info
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // PDF settings
  static const List<String> pageSizes = [
    'A4',
    'Letter',
    'Legal',
    'A3',
    'A5',
  ];

  static const Map<String, List<double>> pageSizeDimensions = {
    'A4': [595.0, 842.0],
    'Letter': [612.0, 792.0],
    'Legal': [612.0, 1008.0],
    'A3': [842.0, 1191.0],
    'A5': [420.0, 595.0],
  };

  // Image settings
  static const int maxImageSize = 4096;
  static const double defaultImageQuality = 0.85;
  static const int jpegQuality = 85;

  // File settings
  static const String pdfExtension = '.pdf';
  static const String defaultPdfName = 'document';
  static const int maxFileNameLength = 100;

  // Storage
  static const String appFolderName = 'PDFGen';
  static const String tempFolderName = 'temp';
  static const String pdfFolderName = 'PDFs';

  // URLs
  static const String privacyPolicyUrl = 'mailto:pdfgen09@gmail.com';
  static const String termsOfServiceUrl = 'mailto:pdfgen09@gmail.com';
  static const String supportEmail = 'pdfgen09@gmail.com';

  // Limits
  static const int maxImagesPerPdf = 100;
  static const int maxPdfFileSize = 50 * 1024 * 1024; // 50 MB

  // Animation durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Shared preferences keys
  static const String keyDarkMode = 'dark_mode';
  static const String keyPageSize = 'page_size';
  static const String keyImageQuality = 'image_quality';
  static const String keyAutoRotate = 'auto_rotate';
  static const String keySaveLocation = 'save_location';
  static const String keyFirstLaunch = 'first_launch';

  // Default values
  static const bool defaultDarkMode = false;
  static const String defaultPageSize = 'A4';
  static const bool defaultAutoRotate = true;
}
