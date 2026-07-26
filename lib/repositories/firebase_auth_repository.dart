import '../services/firebase_auth_service.dart';
import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuthService _authService;

  FirebaseAuthRepository({FirebaseAuthService? authService})
      : _authService = authService ?? FirebaseAuthService();

  @override
  String? get currentUserId => _authService.currentUserId;

  @override
  Stream<String?> authStateChanges() => _authService.authStateChanges();

  @override
  Future<String> register({required String email, required String password}) {
    return _authService.register(email: email, password: password);
  }

  @override
  Future<String> login({required String email, required String password}) {
    return _authService.login(email: email, password: password);
  }

  @override
  Future<void> logout() => _authService.logout();

  @override
  Future<void> sendPasswordResetEmail(String email) {
    return _authService.sendPasswordResetEmail(email);
  }
}
