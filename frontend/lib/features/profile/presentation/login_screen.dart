import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:simcap/features/profile/widgets/login_social_button.dart';
import 'package:simcap/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  Future<void> _handleGoogleLogin(BuildContext context) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final result = await _authService.signInWithGoogle();
      final bool isNewUser = result['isNewUser'] as bool? ?? false;

      if (!mounted) return;

      if (isNewUser) {
        context.go('/onboarding');
      } else {
        context.go('/home');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('구글 로그인 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleKakaoLogin(BuildContext context) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final result = await _authService.signInWithKakao();
      final bool isNewUser = result['isNewUser'] as bool? ?? false;

      if (!mounted) return;

      if (isNewUser) {
        context.go('/onboarding');
      } else {
        context.go('/home');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('카카오 로그인 실패: $e')),
      );
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

              LoginSocialButton(
                icon: Icons.chat_bubble,
                text: '카카오로 시작하기',
                color: const Color(0xFFFEE500),
                textColor: Colors.black87,
                onPressed: _isLoading ? null : () => _handleKakaoLogin(context),
              ),
              const SizedBox(height: 12),

              LoginSocialButton(
                icon: Icons.g_mobiledata,
                text: '구글로 시작하기',
                color: Colors.white,
                textColor: Colors.black87,
                border: true,
                onPressed: _isLoading ? null : () => _handleGoogleLogin(context),
              ),

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