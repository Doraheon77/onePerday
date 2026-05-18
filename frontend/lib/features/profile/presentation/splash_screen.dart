import 'package:flutter/material.dart';
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

    final hasUserInfo = await _authService.hasUserInfo();

    if (!mounted) return;

    if (hasUserInfo) {
      context.go('/home');
    } else {
      context.go('/onboarding');
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
