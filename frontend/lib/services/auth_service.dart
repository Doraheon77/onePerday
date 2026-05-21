import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:simcap/core/supabase/supabase_client.dart';

class AuthService {
  Future<void> signInWithGoogle() async {
    await supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : 'com.example.simcap://login-callback/',
      authScreenLaunchMode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
    );
  }

  Future<void> signInWithKakao() async {
    await supabase.auth.signInWithOAuth(
      OAuthProvider.kakao,
      scopes: 'profile_nickname,profile_image',
      redirectTo: kIsWeb ? null : 'com.example.simcap://login-callback/',
      authScreenLaunchMode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
    );
  }

  bool isLoggedIn() {
    return supabase.auth.currentSession != null;
  }

  Future<bool> hasUserInfo() async {
    final user = supabase.auth.currentUser;

    if (user == null) return false;

    final data = await supabase
        .from('users_info')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();

    return data != null;
  }

  Future<void> completeOnboarding({
    required String name,
    required String gender,
    required int birthYear,
    required String healthStatus,
    required List<String> symptoms,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('로그인된 사용자가 없습니다.');
    }

    await supabase.from('users_info').upsert({
      'id': user.id,
      'name': name,
      'gender': gender,
      'birth_year': birthYear,
      'health_status': healthStatus,
      'symptoms': symptoms,
    });
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }
}
