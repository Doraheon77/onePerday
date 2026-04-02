import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
import 'package:simcap/main.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    routes: [
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
}
