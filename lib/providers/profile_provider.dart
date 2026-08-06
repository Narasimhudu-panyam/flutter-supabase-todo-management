import 'package:flutter/material.dart';

import '../models/profile_model.dart';
import '../repositories/profile_repository.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileRepository _repository = ProfileRepository();

  ProfileModel? _profile;

  bool _isLoading = false;

  ProfileModel? get profile => _profile;

  bool get isLoading => _isLoading;

  Future<void> loadProfile(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _profile = await _repository.getProfile(userId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(ProfileModel profile) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.updateProfile(profile);
      _profile = profile;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
