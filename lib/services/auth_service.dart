import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Must match AndroidManifest.xml and Supabase Auth > URL Configuration.
  /// Used by every browser/email auth callback, not only Google OAuth.
  static const String _authRedirectUrl =
      'io.supabase.flutter://login-callback/';
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
      emailRedirectTo: _authRedirectUrl,
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<bool> signInWithGoogle() {
    return _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: _authRedirectUrl,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  Future<void> signOut() {
    return _client.auth.signOut();
  }

  Future<void> resetPassword(String email) {
    return _client.auth.resetPasswordForEmail(
      email,
      redirectTo: _authRedirectUrl,
    );
  }

  /// Adds or changes the password of the currently authenticated user.
  /// This is also how a Google-only account can gain email/password access.
  Future<UserResponse> updatePassword(String password) {
    return _client.auth.updateUser(UserAttributes(password: password));
  }

  Future<bool> isLoggedIn() async {
    return _client.auth.currentSession != null;
  }
}
