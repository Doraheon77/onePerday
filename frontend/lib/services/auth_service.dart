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

  Future<Map<String, dynamic>> signInWithGoogle() async {
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

    await _storage.write(key: 'accessToken', value: data['accessToken']);
    await _storage.write(
      key: 'isNewUser',
      value: data['isNewUser'].toString(),
    );

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

    await _storage.write(key: 'accessToken', value: data['accessToken']);
    await _storage.write(
      key: 'isNewUser',
      value: data['isNewUser'].toString(),
    );

    return data;
  }

  Future<String?> getAccessToken() async {
    return _storage.read(key: 'accessToken');
  }

  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    try {
      await UserApi.instance.logout();
    } catch (_) {}

    await _storage.delete(key: 'accessToken');
    await _storage.delete(key: 'isNewUser');
  }
}