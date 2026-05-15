import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:simcap/core/constant/app_constants.dart';
import 'package:simcap/core/theme/app_theme.dart';
import 'package:simcap/providers/supplement_provider.dart';
import 'package:simcap/routes/app_router.dart';
import 'package:simcap/services/notification_service.dart';
import 'package:simcap/features/home/presentation/home_screen.dart';
import 'package:simcap/features/cabinet/presentation/cabinet_screen.dart';
import 'package:simcap/features/cabinet/presentation/cabinet_detail_screen.dart';
import 'package:simcap/features/cabinet/presentation/add_supplement_screen.dart';
import 'package:simcap/features/cabinet/domain/dataModels/supplement_model.dart';
import 'package:simcap/features/profile/presentation/login_screen.dart';
import 'package:simcap/features/profile/presentation/onboarding_survey_screen.dart';
import 'package:simcap/features/profile/presentation/profile_screen.dart';
import 'package:simcap/features/profile/presentation/splash_screen.dart';
import 'package:simcap/features/store/presentation/store_screen.dart';
import 'package:simcap/features/store/presentation/search_screen.dart';
import 'package:simcap/features/store/presentation/basket_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);

  await Supabase.initialize(
    url: 'https://saibkbyicokuwdgjcmyy.supabase.co',
    anonKey: 'sb_publishable_exeVSswIS-6R1qiLm4L--Q_9LmesJbM',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  final notifier = SupplementNotifier();

  // 앱 시작 시 저장된 데이터 복원
  await notifier.loadFromStorage();

  runApp(
    ProviderScope(
      child: SupplementProvider(
        notifier: notifier,
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'OnePerDay 영양제 관리',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko', 'KR')],
      locale: const Locale('ko', 'KR'),
      theme: AppTheme.light,
      routerConfig: AppRouter.router,
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => LoginScreen(),
    ),
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
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: child,
      bottomNavigationBar: SizedBox(
        height: 70 + bottomPad,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 네비게이션 바 배경
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
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
                      const SizedBox(width: 64),
                      _buildNavItem(
                        context,
                        Icons.inventory_2_outlined,
                        '내 영양제',
                        '/cabinet',
                      ),
                      _buildNavItem(
                        context,
                        Icons.person_outline,
                        '프로필',
                        '/profile',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // FAB — 바 안에 완전히 위치
            Positioned(
              top: 0,
              bottom: MediaQuery.of(context).padding.bottom,
              left: 0,
              right: 0,
              child: Center(
                child: FloatingActionButton(
                  backgroundColor: AppColors.primary,
                  elevation: 4,
                  shape: const CircleBorder(),
                  child: const Icon(
                    Icons.smart_toy_outlined,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    context.push('/chatbot');
                  },
                ),
              ),
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
    final String currentUri = GoRouterState.of(context).uri.toString();
    final bool isSelected = currentUri.startsWith(path);

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        context.go(path);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.primary : Colors.grey,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primary : Colors.grey,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
