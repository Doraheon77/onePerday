import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simcap/features/profile/widgets/login_social_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 로그인 처리 중 버튼 중복 탭 방지
  bool _isLoading = false;

  // SharedPreferences에서 온보딩 완료 여부 확인 후 라우팅
  Future<void> _handleLogin(BuildContext context) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final bool isOnboardingComplete =
          prefs.getBool('isOnboardingComplete') ?? false;

      if (!mounted) return;

      if (isOnboardingComplete) {
        // 기존 유저 — 바로 홈으로
        context.go('/home');
      } else {
        // 신규 유저 — 온보딩으로
        context.go('/onboarding');
      }
    } catch (e) {
      // SharedPreferences 오류 시 안전하게 온보딩으로 이동
      if (mounted) context.go('/onboarding');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
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

              // 카카오 로그인
              LoginSocialButton(
                icon: Icons.chat_bubble,
                text: '카카오로 시작하기',
                color: const Color(0xFFFEE500),
                textColor: Colors.black87,
                onPressed: _isLoading ? null : () => _handleLogin(context),
              ),
              const SizedBox(height: 12),

              // 구글 로그인
              LoginSocialButton(
                icon: Icons.g_mobiledata,
                text: '구글로 시작하기',
                color: Colors.white,
                textColor: Colors.black87,
                border: true,
                onPressed: _isLoading ? null : () => _handleLogin(context),
              ),

              // 로딩 인디케이터
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                      )
                    : const SizedBox(height: 20),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
