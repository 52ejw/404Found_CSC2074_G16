class AppConstants {
  AppConstants._();

  /// Package / internal name (kept for existing references and tests).
  static const String appName = '404Found';

  /// Brand name shown in the UI (splash, login, feed header).
  static const String displayName = 'CampusFind';

  /// Host institution — shown alongside the brand name in headers.
  static const String universityName = 'Sunway University';

  /// Campus locations used by create-post forms and feed filtering (FR06).
  static const List<String> locations = [
    'University Building',
    'North Building',
    'New University Building',
    'Library',
    'Sunway Le Quadrant',
    'Boulevard / Food Court',
    'Sports Field',
    'Sunway Pyramid Link',
    'BRT Station',
    'Carpark',
    'Student Residences',
    'Other',
  ];

  /// Item categories used by create-post forms and feed filtering (FR06).
  static const List<String> categories = [
    'Bags',
    'Electronics',
    'Documents',
    'Keys',
    'Clothing',
    'Accessories',
    'Books',
    'Cards',
    'Other',
  ];
}
