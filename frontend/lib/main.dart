import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:simcap/features/home/presentation/home_screen.dart';
import 'package:simcap/features/cabinet/presentation/cabinet_screen.dart';
import 'package:simcap/features/cabinet/presentation/cabinet_detail_screen.dart';
import 'package:simcap/features/cabinet/presentation/add_supplement_screen.dart';
import 'package:simcap/features/cabinet/domain/dataModels/supplement_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '심캡 영양제 관리',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'), // 한국어 지원
      ],
      locale: const Locale('ko', 'KR'),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4CAF50)),
        useMaterial3: true,
        fontFamily: 'Pretendard',
      ),
      routerConfig: _router,
    );
  }
}

// 라우팅 설정
final GoRouter _router = GoRouter(
  initialLocation: '/home',
  routes: [
    ShellRoute(
      builder: (context, state, child) => ScaffoldWithNavBar(child: child),
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/cabinet',
          builder: (context, state) => const CabinetScreen(),
          routes: [
            // 2. 상세 페이지 경로
            GoRoute(
              path: 'detail',
              builder: (context, state) {
                final extra = state.extra;
                Supplement supplement;
                if (extra is Supplement) {
                  supplement = extra;
                } else if (extra is Map<String, dynamic>) {
                  supplement = Supplement.fromJson(extra);
                } else {
                  // 데이터 누락 시 기본값 객체 (새 필드들 추가)
                  supplement = Supplement(
                    name: '정보 없음',
                    brand: '',
                    remaining: 0,
                    total: 0,
                    nutrients: [],
                    analysisGuide: '', // 필드 추가
                    aiSummary: '', // 필드 추가
                  );
                }
                return CabinetDetailScreen(item: supplement);
              },
            ),
            // 3. 영양제 등록 페이지 경로 추가
            GoRoute(
              path: 'add',
              builder: (context, state) => const AddSupplementScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/recommend',
          builder: (context, state) => const RecommendScreen(),
        ),
        GoRoute(
          path: '/store',
          builder: (context, state) => const StoreScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/chatbot',
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('AI 영양사 챗봇')),
        body: const Center(child: Text('챗봇 서비스 준비 중입니다.')),
      ),
    ),
  ],
);

// 공통 레이아웃
class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;
  const ScaffoldWithNavBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
        onPressed: () => context.go('/chatbot'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 10,
        color: Colors.white,
        height: 70,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(context, Icons.home_filled, '홈', '/home'),
            _buildNavItem(
              context,
              Icons.inventory_2_outlined,
              '내 영양제',
              '/cabinet',
            ),
            const SizedBox(width: 40),
            _buildNavItem(
              context,
              Icons.thumb_up_alt_outlined,
              '추천',
              '/recommend',
            ),
            _buildNavItem(
              context,
              Icons.shopping_bag_outlined,
              '스토어',
              '/store',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    String path,
  ) {
    final bool isSelected = GoRouterState.of(
      context,
    ).uri.toString().startsWith(path);
    return InkWell(
      onTap: () => context.go(path),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF4CAF50) : Colors.grey,
            size: 24,
          ),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF4CAF50) : Colors.grey,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class RecommendScreen extends StatelessWidget {
  const RecommendScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('추천')));
}

class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('스토어')));
}
