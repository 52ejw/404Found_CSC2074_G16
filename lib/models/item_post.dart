import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/firestore_converters.dart';
import 'enums.dart';

/// Corresponds to a document in the `posts/{postId}` collection.
///
/// [searchKeywords] holds lowercased, tokenised terms derived from
/// [itemName]/[description]/[category]/[location] so the feed can run
/// prefix search with Firestore's `array-contains` without a paid search
/// service.
class ItemPost {
  final String id;
  final String ownerId;
  final String ownerName;
  final PostType postType;
  final String itemName;
  final String category;
  final String description;
  final String location;
  final DateTime eventDate;
  final List<String> imageUrls;
  final ContactPreference contactPreference;
  final PostStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> searchKeywords;

  const ItemPost({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.postType,
    required this.itemName,
    required this.category,
    required this.description,
    required this.location,
    required this.eventDate,
    this.imageUrls = const [],
    this.contactPreference = ContactPreference.inAppChat,
    this.status = PostStatus.open,
    required this.createdAt,
    required this.updatedAt,
    this.searchKeywords = const [],
  });

  factory ItemPost.fromMap(String id, Map<String, dynamic> map) {
    return ItemPost(
      id: id,
      ownerId: map['ownerId'] as String? ?? '',
      ownerName: map['ownerName'] as String? ?? '',
      postType: enumFromName(PostType.values, map['postType'] as String?, PostType.lost),
      itemName: map['itemName'] as String? ?? '',
      category: map['category'] as String? ?? '',
      description: map['description'] as String? ?? '',
      location: map['location'] as String? ?? '',
      eventDate: dateTimeFromFirestore(map['eventDate']),
      imageUrls: List<String>.from(map['imageUrls'] as List? ?? const []),
      contactPreference: enumFromName(
        ContactPreference.values,
        map['contactPreference'] as String?,
        ContactPreference.inAppChat,
      ),
      status: enumFromName(PostStatus.values, map['status'] as String?, PostStatus.open),
      createdAt: dateTimeFromFirestore(map['createdAt']),
      updatedAt: dateTimeFromFirestore(map['updatedAt']),
      searchKeywords: List<String>.from(map['searchKeywords'] as List? ?? const []),
    );
  }

  factory ItemPost.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    return ItemPost.fromMap(doc.id, doc.data() ?? const {});
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'ownerName': ownerName,
      'postType': postType.name,
      'itemName': itemName,
      'category': category,
      'description': description,
      'location': location,
      'eventDate': Timestamp.fromDate(eventDate),
      'imageUrls': imageUrls,
      'contactPreference': contactPreference.name,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'searchKeywords': searchKeywords,
    };
  }

  ItemPost copyWith({
    String? itemName,
    String? category,
    String? description,
    String? location,
    DateTime? eventDate,
    List<String>? imageUrls,
    ContactPreference? contactPreference,
    PostStatus? status,
    DateTime? updatedAt,
    List<String>? searchKeywords,
  }) {
    return ItemPost(
      id: id,
      ownerId: ownerId,
      ownerName: ownerName,
      postType: postType,
      itemName: itemName ?? this.itemName,
      category: category ?? this.category,
      description: description ?? this.description,
      location: location ?? this.location,
      eventDate: eventDate ?? this.eventDate,
      imageUrls: imageUrls ?? this.imageUrls,
      contactPreference: contactPreference ?? this.contactPreference,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      searchKeywords: searchKeywords ?? this.searchKeywords,
    );
  }
}
