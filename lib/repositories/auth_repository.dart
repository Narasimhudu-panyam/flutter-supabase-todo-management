import '../services/auth_service.dart';

class AuthRepository {
  final AuthService _authService = AuthService();

  Future signUp({
    required String email,
    required String password,
    required String fullName,
  }) {
    return _authService.signUp(
      email: email,
      password: password,
      fullName: fullName,
    );
  }

  Future signIn({required String email, required String password}) {
    return _authService.signIn(email: email, password: password);
  }

  Future<void> signOut() {
    return _authService.signOut();
  }

  Future<void> resetPassword(String email) {
    return _authService.resetPassword(email);
  }

  Future<bool> isLoggedIn() {
    return _authService.isLoggedIn();
  }
}
