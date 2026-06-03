import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:simcap/core/constant/app_constants.dart';
import 'package:simcap/features/chatbot/presentation/chatbot_screen.dart';
import 'package:simcap/features/home/presentation/home_screen.dart';
import 'package:simcap/features/cabinet/presentation/cabinet_screen.dart';
import 'package:simcap/features/cabinet/presentation/cabinet_detail_screen.dart';
import 'package:simcap/features/cabinet/presentation/add_supplement_screen.dart';
import 'package:simcap/features/cabinet/presentation/supplement_info_screen.dart';
import 'package:simcap/features/cabinet/presentation/barcode_scan_screen.dart';
import 'package:simcap/features/cabinet/presentation/label_camera_screen.dart';
import 'package:simcap/features/cabinet/domain/dataModels/supplement_model.dart';
import 'package:simcap/features/profile/presentation/login_screen.dart';
import 'package:simcap/features/profile/presentation/terms_agreement_screen.dart';
import 'package:simcap/features/store/presentation/purchase_screen.dart';
import 'package:simcap/features/profile/presentation/onboarding_survey_screen.dart';
import 'package:simcap/features/profile/presentation/profile_screen.dart';
import 'package:simcap/features/profile/presentation/purchase_history_screen.dart';
import 'package:simcap/features/store/presentation/my_reviews_screen.dart';
import 'package:simcap/features/store/presentation/review_screen.dart';
import 'package:simcap/features/store/presentation/store_screen.dart';
import 'package:simcap/features/store/presentation/search_screen.dart';
import 'package:simcap/features/store/presentation/basket_screen.dart';
import 'package:simcap/features/store/presentation/supplement_detail_screen.dart';
import 'package:simcap/main.dart';
import 'package:simcap/features/profile/presentation/splash_screen.dart';

// 슬라이드 업 전환 (모달성 화면용)
CustomTransitionPage<T> _slideUp<T>(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: FadeTransition(opacity: animation, child: child),
      );
    },
  );
}

// 슬라이드 좌→우 전환 (서브 화면용)
CustomTransitionPage<T> _slideRight<T>(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: child,
      );
    },
  );
}

class AppRouter {
  static final navigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/', redirect: (context, state) => '/splash'),
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/terms',
        builder: (context, state) => const TermsAgreementScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingSurveyScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => ScaffoldWithNavBar(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/store',
            builder: (context, state) => const StoreScreen(),
            routes: [
              GoRoute(
                path: 'search',
                pageBuilder: (context, state) {
                  String keyword = '';
                  List<String> initialCategories = [];
                  List<String> initialIngredients = [];
                  String? initialPriceRange;

                  if (state.extra is String) {
                    keyword = state.extra as String;
                  } else if (state.extra is Map<String, dynamic>) {
                    final map = state.extra as Map<String, dynamic>;
                    keyword = map['keyword'] as String? ?? '';
                    initialCategories =
                        (map['categories'] as List<dynamic>?)?.cast<String>() ??
                        [];
                    initialIngredients =
                        (map['ingredients'] as List<dynamic>?)
                            ?.cast<String>() ??
                        [];
                    initialPriceRange = map['priceRange'] as String?;
                  }

                  return _slideRight(
                    context,
                    state,
                    SearchScreen(
                      initialKeyword: keyword,
                      initialCategories: initialCategories,
                      initialIngredients: initialIngredients,
                      initialPriceRange: initialPriceRange,
                    ),
                  );
                },
              ),
              GoRoute(
                path: 'basket',
                pageBuilder: (context, state) =>
                    _slideRight(context, state, const BasketScreen()),
              ),
              GoRoute(
                path: 'purchase',
                pageBuilder: (context, state) {
                  final product = state.extra as StoreProduct;
                  return _slideUp(
                    context,
                    state,
                    PurchaseScreen(product: product),
                  );
                },
              ),
              GoRoute(
                path: 'detail',
                pageBuilder: (context, state) {
                  final product = state.extra is StoreProduct
                      ? state.extra as StoreProduct
                      : dummyProduct;
                  return _slideRight(
                    context,
                    state,
                    SupplementDetailScreen(product: product),
                  );
                },
              ),
              GoRoute(
                path: 'review',
                pageBuilder: (context, state) {
                  final product = state.extra is StoreProduct
                      ? state.extra as StoreProduct
                      : dummyProduct;
                  return _slideRight(
                    context,
                    state,
                    ReviewScreen(product: product),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/cabinet',
            builder: (context, state) => const CabinetScreen(),
            routes: [
              GoRoute(
                path: 'purchase',
                pageBuilder: (context, state) {
                  final product = state.extra as StoreProduct;
                  return _slideUp(
                    context,
                    state,
                    PurchaseScreen(product: product),
                  );
                },
              ),
              GoRoute(
                path: 'detail',
                pageBuilder: (context, state) {
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
                  return _slideRight(
                    context,
                    state,
                    CabinetDetailScreen(item: supplement),
                  );
                },
              ),
              GoRoute(
                path: 'add',
                pageBuilder: (context, state) {
                  final item = state.extra is Supplement
                      ? state.extra as Supplement
                      : null;
                  return _slideUp(
                    context,
                    state,
                    AddSupplementScreen(initialItem: item),
                  );
                },
              ),
              GoRoute(
                path: 'scan',
                pageBuilder: (context, state) =>
                    _slideUp(context, state, const BarcodeScanScreen()),
              ),
              GoRoute(
                path: 'info',
                pageBuilder: (context, state) {
                  final supplement = state.extra as Supplement;
                  return _slideUp(
                    context,
                    state,
                    SupplementInfoScreen(supplement: supplement),
                  );
                },
              ),
              GoRoute(
                path: 'label-camera',
                builder: (context, state) => const LabelCameraScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: 'purchases',
                pageBuilder: (context, state) =>
                    _slideRight(context, state, const PurchaseHistoryScreen()),
              ),
              GoRoute(
                path: 'my-reviews',
                pageBuilder: (context, state) =>
                    _slideRight(context, state, const MyReviewsScreen()),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/chatbot',
        pageBuilder: (context, state) =>
            _slideUp(context, state, const ChatbotScreen()),
      ),
    ],
  );
}

// ── 바텀 네비게이션 바 래퍼 ────────────────────────────────────────────────────
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
