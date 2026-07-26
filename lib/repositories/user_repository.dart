import '../models/app_user.dart';

/// Contract for the `users` collection (FR02 profile management). Owned by
/// Backend Developer 1.
abstract class UserRepository {
  Future<void> createUserProfile(AppUser user);

  Future<AppUser?> getUserById(String userId);

  /// Realtime profile stream, e.g. for the Profile screen and for
  /// `AuthProvider` to expose the current user's data.
  Stream<AppUser?> watchUser(String userId);

  Future<void> updateUserProfile(String userId, {String? name, String? faculty, String? contact, String? profileImageUrl});

  /// Called by the claim workflow when a claim reaches Returned, to keep
  /// `successfulRecoveries` accurate for the Profile screen.
  Future<void> incrementSuccessfulRecoveries(String userId);
}
