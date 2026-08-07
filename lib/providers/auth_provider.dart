import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository = AuthRepository();

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  User? get currentUser => Supabase.instance.client.auth.currentUser;

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    if (_isLoading) {
      throw StateError('An authentication request is already in progress.');
    }

    _isLoading = true;
    notifyListeners();

    try {
      return await _repository.signIn(email: email, password: password);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loginWithGoogle() async {
    if (_isLoading) {
      throw StateError('An authentication request is already in progress.');
    }

    _isLoading = true;
    notifyListeners();

    try {
      return await _repository.signInWithGoogle();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<AuthResponse> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    if (_isLoading) {
      throw StateError('An authentication request is already in progress.');
    }

    _isLoading = true;
    notifyListeners();

    try {
      return await _repository.signUp(
        fullName: fullName,
        email: email,
        password: password,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.signOut();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword(String email) {
    return _repository.resetPassword(email);
  }

  Future<UserResponse> updatePassword(String password) async {
    if (_isLoading) {
      throw StateError('An authentication request is already in progress.');
    }

    _isLoading = true;
    notifyListeners();
    try {
      return await _repository.updatePassword(password);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> isLoggedIn() {
    return _repository.isLoggedIn();
  }
}
