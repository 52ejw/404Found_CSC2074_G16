class AppConstants {
  AppConstants._();

  /// Package / internal name (kept for existing references and tests).
  static const String appName = '404Found';

  /// Brand name shown in the UI (splash, login, feed header).
  static const String displayName = 'CampusFind';

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
