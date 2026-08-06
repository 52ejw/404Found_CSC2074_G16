List<String> buildSearchKeywords({
  required String itemName,
  required String category,
  required String location,
  String description = '',
}) {
  final combined = '$itemName $category $location $description'.toLowerCase();
  final tokens = combined
      .split(RegExp(r'[^a-z0-9]+'))
      .where((token) => token.isNotEmpty)
      .toSet()
      .toList();
  return tokens;
}

/// Normalises a user's search box input into the same token form so it can
/// be matched against [ItemPost.searchKeywords].
List<String> tokenizeQuery(String query) {
  return query
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((token) => token.isNotEmpty)
      .toList();
}
