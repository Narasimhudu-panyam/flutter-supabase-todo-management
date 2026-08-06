import '../models/profile_model.dart';
import '../services/profile_service.dart';

class ProfileRepository {
  final ProfileService _service = ProfileService();

  Future<ProfileModel?> getProfile(String userId) {
    return _service.getProfile(userId);
  }

  Future<void> updateProfile(ProfileModel profile) {
    return _service.updateProfile(profile);
  }
}
