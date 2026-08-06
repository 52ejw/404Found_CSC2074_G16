import '../models/app_user.dart';

abstract class UserRepository {
  Future<void> createUserProfile(AppUser user);

  Future<AppUser?> getUserById(String userId);

  Stream<AppUser?> watchUser(String userId);

  Future<void> updateUserProfile(
    String userId, {
    String? name,
    String? faculty,
    String? contact,
    String? profileImageUrl,
  });

  Future<void> incrementSuccessfulRecoveries(String userId);
}
