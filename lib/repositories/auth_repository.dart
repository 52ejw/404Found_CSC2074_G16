abstract class AuthRepository {
  String? get currentUserId;
  Stream<String?> authStateChanges();

  /// Returns the new user's id. Does not create the Firestore profile
  /// document — callers should follow up with `UserRepository.createUserProfile`.
  Future<String> register({required String email, required String password});

  Future<String> login({required String email, required String password});

  Future<void> logout();

  Future<void> sendPasswordResetEmail(String email);
}
