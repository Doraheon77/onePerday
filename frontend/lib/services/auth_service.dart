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

  User? get currentUser => supabase.auth.currentUser;

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

  // Mapping lists matching database BigInt IDs
  static const Map<String, int> goalMap = {
    '눈 건강': 1,
    '관절 건강': 2,
    '면역력 증진': 3,
    '피로 회복': 4,
    '장 건강': 5,
    '피부 개선': 6,
    '뼈/치아 건강': 7,
    '혈행 개선': 8,
    '두뇌/기억력 개선': 9,
    '다이어트': 10,
    '스트레스 케어': 11,
    '모발/손톱 영양': 12,
    '간 건강': 13,
  };

  static const Map<String, int> conditionMap = {
    '고혈압': 1,
    '당뇨': 2,
    '고지혈증': 3,
    '심장 질환': 4,
    '신장 질환': 5,
    '간 질환': 6,
    '갑상선 질환': 7,
    '골다공증': 8,
    '관절염': 9,
    '빈혈': 10,
  };

  static const Map<String, int> allergyMap = {
    '견과류': 1,
    '갑각류': 2,
    '고등어': 3,
    '우유': 4,
    '달걀': 5,
    '밀': 6,
    '메밀': 6,
    '대두': 7,
  };

  Future<void> completeOnboarding({
    required String name,
    required String gender,
    required int birthYear,
    required List<String> selectedGoals,
    required List<String> selectedHealth,
    required List<String> selectedAllergies,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('로그인된 사용자가 없습니다.');
    }

    // Map Goals
    final List<int> mappedGoals = [];
    for (var goal in selectedGoals) {
      if (goalMap.containsKey(goal)) {
        mappedGoals.add(goalMap[goal]!);
      }
    }

    // Map Conditions
    final List<int> mappedConditions = [];
    for (var condition in selectedHealth) {
      if (conditionMap.containsKey(condition)) {
        mappedConditions.add(conditionMap[condition]!);
      }
    }

    // Map Allergies
    final List<int> mappedAllergies = [];
    for (var allergy in selectedAllergies) {
      if (allergyMap.containsKey(allergy)) {
        mappedAllergies.add(allergyMap[allergy]!);
      }
    }

    await supabase
        .from('users_info')
        .update({
          'name': name,
          'gender': gender,
          'birth_year': birthYear,
          'health_goals': mappedGoals,
          'conditions': mappedConditions,
          'allergies': mappedAllergies,
        })
        .eq('id', user.id);
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }
}
