import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/errors/app_exception.dart';
import '../models/app_user.dart';
import '../services/firestore_service.dart';
import 'user_repository.dart';

class FirestoreUserRepository implements UserRepository {
  final FirestoreService _firestore;

  FirestoreUserRepository({FirestoreService? firestore}) : _firestore = firestore ?? FirestoreService();

  @override
  Future<void> createUserProfile(AppUser user) async {
    try {
      await _firestore.users.doc(user.id).set(user);
    } on FirebaseException catch (e) {
      throw RepositoryException('Failed to create user profile: ${e.message}');
    }
  }

  @override
  Future<AppUser?> getUserById(String userId) async {
    try {
      final doc = await _firestore.users.doc(userId).get();
      return doc.data();
    } on FirebaseException catch (e) {
      throw RepositoryException('Failed to load user: ${e.message}');
    }
  }

  @override
  Stream<AppUser?> watchUser(String userId) {
    return _firestore.users.doc(userId).snapshots().map((doc) => doc.data());
  }

  @override
  Future<void> updateUserProfile(
    String userId, {
    String? name,
    String? faculty,
    String? contact,
    String? profileImageUrl,
  }) async {
    final updates = <String, dynamic>{
      'name': ?name,
      'faculty': ?faculty,
      'contact': ?contact,
      'profileImageUrl': ?profileImageUrl,
    };
    if (updates.isEmpty) return;
    try {
      await _firestore.users.doc(userId).update(updates);
    } on FirebaseException catch (e) {
      throw RepositoryException('Failed to update profile: ${e.message}');
    }
  }

  @override
  Future<void> incrementSuccessfulRecoveries(String userId) async {
    try {
      await _firestore.users.doc(userId).update({
        'successfulRecoveries': FieldValue.increment(1),
      });
    } on FirebaseException catch (e) {
      throw RepositoryException('Failed to update recovery count: ${e.message}');
    }
  }
}
