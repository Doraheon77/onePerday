import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:simcap/features/chatbot/presentation/chatbot_screen.dart';
import 'package:simcap/features/home/presentation/home_screen.dart';
import 'package:simcap/features/cabinet/presentation/cabinet_screen.dart';
import 'package:simcap/features/cabinet/presentation/cabinet_detail_screen.dart';
import 'package:simcap/features/cabinet/presentation/add_supplement_screen.dart';
import 'package:simcap/features/cabinet/presentation/barcode_scan_screen.dart';
import 'package:simcap/features/cabinet/domain/dataModels/supplement_model.dart';
import 'package:simcap/features/profile/presentation/login_screen.dart';
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
      GoRoute(
        path: '/',
        redirect:(context, state) => '/splash',
      ),
      GoRoute(
        path: '/splash',
        builder:(context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
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
                  // extra로 초기 검색어 전달 가능 (선물 카테고리 탭 등)
                  final keyword = state.extra is String
                      ? state.extra as String
                      : '';
                  return _slideRight(
                    context,
                    state,
                    SearchScreen(initialKeyword: keyword),
                  );
                },
              ),
              GoRoute(
                path: 'basket',
                pageBuilder: (context, state) =>
                    _slideRight(context, state, const BasketScreen()),
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
                  // extra로 Supplement 전달 시 편집 모드
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
