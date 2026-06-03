import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:simcap/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthState();
    });
  }

  Future<void> _checkAuthState() async {
    final loggedIn = _authService.isLoggedIn();

    if (!mounted) return;

    if (!loggedIn) {
      context.go('/login');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final termsAgreed = prefs.getBool('termsAgreed') ?? false;
    if (!mounted) return;
    if (!termsAgreed) {
      context.go('/terms');
      return;
    }

    try {
      final hasUserInfo = await _authService.hasUserInfo();
      if (!mounted) return;
      if (hasUserInfo) {
        context.go('/home');
      } else {
        context.go('/onboarding');
      }
    } catch (e) {
      debugPrint('[SplashScreen] 인증 상태 확인 실패 (사용자 삭제됨 또는 만료): $e');
      await _authService.signOut();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
