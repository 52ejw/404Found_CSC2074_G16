import 'package:flutter_test/flutter_test.dart';
import 'package:found404/core/utils/search_keywords.dart';

void main() {
  test('buildSearchKeywords lowercases and tokenises across fields', () {
    final keywords = buildSearchKeywords(
      itemName: 'Blue Water-Bottle',
      category: 'Accessories',
      location: 'Library Level 2',
      description: 'Has a dent near the cap.',
    );

    expect(keywords, containsAll(['blue', 'water', 'bottle', 'accessories', 'library', 'level', '2']));
    expect(keywords.every((k) => k == k.toLowerCase()), isTrue);
  });

  test('tokenizeQuery matches the same normalisation as buildSearchKeywords', () {
    final built = buildSearchKeywords(itemName: 'Black Wallet', category: 'Wallet', location: 'Canteen');
    final query = tokenizeQuery('BLACK wallet');

    expect(query.every(built.contains), isTrue);
  });

  test('buildSearchKeywords de-duplicates repeated tokens', () {
    final keywords = buildSearchKeywords(itemName: 'wallet wallet', category: 'wallet', location: 'canteen');
    expect(keywords.where((k) => k == 'wallet').length, 1);
  });
}
