import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:simcap/features/home/presentation/home_screen.dart';
import 'package:simcap/features/cabinet/presentation/cabinet_screen.dart';
import 'package:simcap/features/cabinet/presentation/cabinet_detail_screen.dart';
import 'package:simcap/features/cabinet/presentation/add_supplement_screen.dart';
import 'package:simcap/features/cabinet/domain/dataModels/supplement_model.dart';
import 'package:simcap/features/profile/presentation/login_screen.dart';
import 'package:simcap/features/profile/presentation/onboarding_survey_screen.dart';
import 'package:simcap/features/profile/presentation/profile_screen.dart';
import 'package:simcap/features/store/presentation/store_screen.dart';
import 'package:simcap/features/store/presentation/search_screen.dart';
import 'package:simcap/features/store/presentation/basket_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);

  KakaoSdk.init(
    nativeAppKey: '여기에_카카오_네이티브_앱키',
  );

  runApp(const ProviderScope(
      child: MyApp(),
    ),
  );
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
      supportedLocales: const [Locale('ko', 'KR')],
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

final GoRouter _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (context, state) => LoginScreen()),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingSurveyScreen(),
    ),

    ShellRoute(
      builder: (context, state, child) => ScaffoldWithNavBar(child: child),
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),

        GoRoute(
          path: '/store',
          builder: (context, state) => const StoreScreen(),
          routes: [
            GoRoute(
              path: 'search',
              builder: (context, state) => const SearchScreen(),
            ),
            GoRoute(
              path: 'basket',
              builder: (context, state) => const BasketScreen(),
            ),
          ],
        ),

        GoRoute(
          path: '/cabinet',
          builder: (context, state) => const CabinetScreen(),
          routes: [
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
                  supplement = Supplement(
                    name: '정보 없음',
                    brand: '',
                    remaining: 0,
                    total: 0,
                    nutrients: [],
                    analysisGuide: '',
                    aiSummary: '',
                  );
                }
                return CabinetDetailScreen(item: supplement);
              },
            ),
            GoRoute(
              path: 'add',
              builder: (context, state) => const AddSupplementScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),

    GoRoute(
      path: '/chatbot',
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: const Text('AI 영양사 챗봇'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: Text('챗봇 서비스 준비 중입니다.')),
      ),
    ),
  ],
);

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
        child: const Icon(Icons.smart_toy_outlined, color: Colors.white),
        onPressed: () => context.push('/chatbot'),
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
              Icons.shopping_bag_outlined,
              '스토어',
              '/store',
            ),
            const SizedBox(width: 40),
            _buildNavItem(
              context,
              Icons.inventory_2_outlined,
              '내 영양제',
              '/cabinet',
            ),
            _buildNavItem(context, Icons.person_outline, '프로필', '/profile'),
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
    final String currentUri = GoRouterState.of(context).uri.toString();
    final bool isSelected =
        currentUri == path || currentUri.startsWith('$path/');

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
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF4CAF50) : Colors.grey,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
