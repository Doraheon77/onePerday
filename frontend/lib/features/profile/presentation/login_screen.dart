import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:simcap/features/profile/widgets/login_social_button.dart';
import 'package:simcap/services/auth_service.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            const Icon(
              Icons.auto_awesome_motion_rounded,
              size: 80,
              color: Color(0xFF4CAF50),
            ),
            const SizedBox(height: 24),
            const Text(
              'OnePerDay',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4CAF50),
              ),
            ),
            const Text(
              '나만을 위한 스마트한 영양제 관리',
              style: TextStyle(color: Colors.grey),
            ),
            const Spacer(),

            LoginSocialButton(
              icon: Icons.chat_bubble,
              text: '카카오로 시작하기',
              color: const Color(0xFFFEE500),
              textColor: Colors.black87,
              onPressed: () => _handleKakaoLogin(context),
            ),
            const SizedBox(height: 12),
            LoginSocialButton(
              icon: Icons.g_mobiledata,
              text: '구글로 시작하기',
              color: Colors.white,
              textColor: Colors.black87,
              border: true,
              onPressed: () => _handleGoogleLogin(context),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Future<void> _handleGoogleLogin(BuildContext context) async {
    try {
      final result = await _authService.signInWithGoogle();
      final bool isNewUser = result['isNewUser'] as bool? ?? false;

      if (!context.mounted) return;

      if (isNewUser) {
        context.go('/onboarding');
      } else {
        context.go('/home');
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('구글 로그인 실패: $e')),
      );
    }
  }

  Future<void> _handleKakaoLogin(BuildContext context) async {
    try {
      final result = await _authService.signInWithKakao();
      final bool isNewUser = result['isNewUser'] as bool? ?? false;

      if (!context.mounted) return;

      if (isNewUser) {
        context.go('/onboarding');
      } else {
        context.go('/home');
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('카카오 로그인 실패: $e')),
      );
    }
  }
}