import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';

class AuthRepository {
  final AuthService _authService = AuthService();

  Future<AuthResponse> signUp({
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

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _authService.signIn(email: email, password: password);
  }

  Future<bool> signInWithGoogle() {
    return _authService.signInWithGoogle();
  }

  Future<void> signOut() {
    return _authService.signOut();
  }

  Future<void> resetPassword(String email) {
    return _authService.resetPassword(email);
  }

  Future<UserResponse> updatePassword(String password) {
    return _authService.updatePassword(password);
  }

  Future<bool> isLoggedIn() {
    return _authService.isLoggedIn();
  }
}
