/// Contract for authentication operations (FR01). Owned by Backend
/// Developer 1; consumed by `AuthProvider` (Frontend Developer 2's
/// Provider/ViewModel layer).
///
/// Deliberately returns/accepts plain `String` user ids rather than a
/// Firebase `User`, so the provider layer and its tests never need to
/// depend on `firebase_auth` types.
abstract class AuthRepository {
  String? get currentUserId;

  /// Emits the signed-in user's id, or `null` when signed out. Used by the
  /// splash screen to route to Login or Home.
  Stream<String?> authStateChanges();

  /// Returns the new user's id. Does not create the Firestore profile
  /// document — callers should follow up with `UserRepository.createUserProfile`.
  Future<String> register({required String email, required String password});

  Future<String> login({required String email, required String password});

  Future<void> logout();

  Future<void> sendPasswordResetEmail(String email);
}
