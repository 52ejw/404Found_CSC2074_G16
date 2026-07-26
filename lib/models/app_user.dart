import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/firestore_converters.dart';
import 'enums.dart';

/// Corresponds to a document in the `users/{userId}` collection.
class AppUser {
  final String id;
  final String name;
  final String email;
  final String? faculty;
  final String? contact;
  final String? profileImageUrl;
  final UserRole role;
  final DateTime createdAt;
  final int successfulRecoveries;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.faculty,
    this.contact,
    this.profileImageUrl,
    this.role = UserRole.student,
    required this.createdAt,
    this.successfulRecoveries = 0,
  });

  factory AppUser.fromMap(String id, Map<String, dynamic> map) {
    return AppUser(
      id: id,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      faculty: map['faculty'] as String?,
      contact: map['contact'] as String?,
      profileImageUrl: map['profileImageUrl'] as String?,
      role: enumFromName(UserRole.values, map['role'] as String?, UserRole.student),
      createdAt: dateTimeFromFirestore(map['createdAt']),
      successfulRecoveries: (map['successfulRecoveries'] as num?)?.toInt() ?? 0,
    );
  }

  factory AppUser.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    return AppUser.fromMap(doc.id, doc.data() ?? const {});
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'faculty': faculty,
      'contact': contact,
      'profileImageUrl': profileImageUrl,
      'role': role.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'successfulRecoveries': successfulRecoveries,
    };
  }

  AppUser copyWith({
    String? name,
    String? faculty,
    String? contact,
    String? profileImageUrl,
    int? successfulRecoveries,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email,
      faculty: faculty ?? this.faculty,
      contact: contact ?? this.contact,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      role: role,
      createdAt: createdAt,
      successfulRecoveries: successfulRecoveries ?? this.successfulRecoveries,
    );
  }
}
