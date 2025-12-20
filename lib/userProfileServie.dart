import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfileService {
  static final UserProfileService _instance = UserProfileService._internal();
  factory UserProfileService() => _instance;
  UserProfileService._internal();

  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _currentProfile;

  Future<void> initialize() async {
    await _fetchCurrentProfile();
  }

  Future<void> _fetchCurrentProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response =
          await _supabase.from('profiles').select().eq('id', userId).single();

      _currentProfile = response;
    } catch (e) {
      throw Exception('Failed to fetch user profile: $e');
    }
  }

  Future<void> refresh() async {
    await _fetchCurrentProfile();
  }

  String? get userId => _supabase.auth.currentUser?.id;
  // String? get email => _supabase.auth.currentUser?.email;

  String? get name => _currentProfile?['full_name'];
  String? get email => _currentProfile?['email'];
  String? get role => _currentProfile?['account_type'];

  Map<String, dynamic>? get fullProfile => _currentProfile;

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('profiles').update(updates).eq('id', userId);

      await refresh();
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }
}
