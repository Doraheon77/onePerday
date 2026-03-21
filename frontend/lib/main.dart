import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'features/home/presentation/home_screen.dart';

class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('스토어 - 쇼핑 준비중')));
  }
}

class CabinetScreen extends StatelessWidget {
  const CabinetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('캐비닛 - 목록 준비중')));
  }
}

class RecommendScreen extends StatelessWidget {
  const RecommendScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('추천 - 리스트 준비중')));
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('프로필 - 정보 준비중')));
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '심캡',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50), // Primary 녹색
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Pretendard',
        scaffoldBackgroundColor: const Color(0xFFF9FAFB), // 밝은 회백 배경
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      routerConfig: _router,
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/home',
  routes: [
    ShellRoute(
      builder: (context, state, child) => ScaffoldWithNavBar(child: child),
      routes: [
        GoRoute(
          path: '/store',
          builder: (context, state) => const StoreScreen(),
        ),
        GoRoute(
          path: '/cabinet',
          builder: (context, state) => const CabinetScreen(),
        ),
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/recommend',
          builder: (context, state) => const RecommendScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
  ],
);

// Bottom Navigation Bar Scaffold (5개 탭, 순서 맞춤)
class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;

  const ScaffoldWithNavBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    int currentIndex = 0;
    if (location.startsWith('/store')) currentIndex = 0;
    if (location.startsWith('/cabinet')) currentIndex = 1;
    if (location.startsWith('/home')) currentIndex = 2;
    if (location.startsWith('/recommend')) currentIndex = 3;
    if (location.startsWith('/profile')) currentIndex = 4;

    return Scaffold(
      body: child,
      floatingActionButton:
          currentIndex ==
              2 // 홈 화면(인덱스 2)에서만 FAB 보이게
          ? FloatingActionButton(
              onPressed: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('새 영양제 추가 준비중')));
              },
              backgroundColor: const Color(0xFF4CAF50),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/store');
              break;
            case 1:
              context.go('/cabinet');
              break;
            case 2:
              context.go('/home');
              break;
            case 3:
              context.go('/recommend');
              break;
            case 4:
              context.go('/profile');
              break;
          }
        },
        selectedItemColor: const Color(0xFF4CAF50),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed, // 5개 탭일 때 아이콘+라벨 모두 보이게
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: '스토어',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: '캐비닛'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.recommend), label: '추천'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '프로필'),
        ],
      ),
    );
  }
}
