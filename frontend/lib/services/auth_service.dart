import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

class AuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // 안드로이드 에뮬레이터에서 백엔드 접근 시 localhost 대신 10.0.2.2 사용
  final String baseUrl = 'http://10.0.2.2:3000';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    serverClientId:
        '897685041022-b7bm315o2j3bqkq2thqm5j8mf5vcigkl.apps.googleusercontent.com',
  );

  static const String accessTokenKey = 'accessToken';
  static const String onboardingCompletedKey = 'onboardingCompleted';
  static const String loginProviderKey = 'loginProvider';

  Future<Map<String, dynamic>> signInWithGoogle() async {
    await _googleSignIn.signOut();

    final GoogleSignInAccount? account = await _googleSignIn.signIn();

    if (account == null) {
      throw Exception('구글 로그인이 취소되었습니다.');
    }

    final GoogleSignInAuthentication auth = await account.authentication;
    final String? idToken = auth.idToken;

    if (idToken == null) {
      throw Exception('구글 idToken을 가져오지 못했습니다.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('구글 로그인 실패: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final accessToken = data['accessToken'] as String?;

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('백엔드 JWT를 받지 못했습니다.');
    }

    await _storage.write(key: accessTokenKey, value: accessToken);
    await _storage.write(key: loginProviderKey, value: 'google');

    return data;
  }

  Future<Map<String, dynamic>> signInWithKakao() async {
    OAuthToken token;

    if (await isKakaoTalkInstalled()) {
      token = await UserApi.instance.loginWithKakaoTalk();
    } else {
      token = await UserApi.instance.loginWithKakaoAccount();
    }

    final response = await http.post(
      Uri.parse('$baseUrl/auth/kakao'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'accessToken': token.accessToken}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('카카오 로그인 실패: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final accessToken = data['accessToken'] as String?;

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('백엔드 JWT를 받지 못했습니다.');
    }

    await _storage.write(key: accessTokenKey, value: accessToken);
    await _storage.write(key: loginProviderKey, value: 'kakao');

    return data;
  }

  Future<String?> getAccessToken() async {
    return _storage.read(key: accessTokenKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> setOnboardingCompleted(bool value) async {
    await _storage.write(
      key: onboardingCompletedKey,
      value: value.toString(),
    );
  }

  Future<bool> isOnboardingCompleted() async {
    final value = await _storage.read(key: onboardingCompletedKey);
    return value == 'true';
  }

  Future<String> getInitialRoute() async {
    final loggedIn = await isLoggedIn();

    if (!loggedIn) {
      return '/login';
    }

    final onboardingCompleted = await isOnboardingCompleted();

    if (!onboardingCompleted) {
      return '/onboarding';
    }

    return '/home';
  }

  Future<void> logout() async {
    final provider = await _storage.read(key: loginProviderKey);

    if (provider == 'google') {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
    }

    if (provider == 'kakao') {
      try {
        await UserApi.instance.logout();
      } catch (_) {}
    }

    await _storage.delete(key: accessTokenKey);
    await _storage.delete(key: loginProviderKey);

    // 온보딩 상태를 유지하려면 이건 삭제하지 않음, 완전 초기화 할 때 밑에줄 활성화
    // await _storage.delete(key: onboardingCompletedKey);
  }
}