import '../models/profile_model.dart';
import 'supabase_service.dart';

class ProfileService {
  Future<ProfileModel?> getProfile(String userId) async {
    final response = await SupabaseService.client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return ProfileModel.fromMap(response);
  }

  Future<void> updateProfile(ProfileModel profile) async {
    await SupabaseService.client
        .from('profiles')
        .update(profile.toMap())
        .eq('id', profile.id);
  }
}
