import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:simcap/features/profile/widgets/login_social_button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

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
              onPressed: () => _handleLogin(context, isNewUser: true),
            ),
            const SizedBox(height: 12),
            LoginSocialButton(
              icon: Icons.g_mobiledata,
              text: '구글로 시작하기',
              color: Colors.white,
              textColor: Colors.black87,
              border: true,
              onPressed: () => _handleLogin(context, isNewUser: true),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  void _handleLogin(BuildContext context, {required bool isNewUser}) {
    // TODO: 나중에 여기서 실제 로그인 상태 저장 로직 추가

    if (isNewUser) {
      // 신규 유저라면 온보딩 화면으로 이동
      context.go('/onboarding');
    } else {
      // 기존 유저라면 바로 홈 화면으로 이동
      context.go('/home');
    }
  }
}
