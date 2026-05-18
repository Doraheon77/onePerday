import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:simcap/core/theme/app_theme.dart';
import 'package:simcap/providers/supplement_provider.dart';
import 'package:simcap/routes/app_router.dart';
import 'package:simcap/services/notification_service.dart';
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

  runApp(MyApp(notifier: notifier));
}

class MyApp extends StatelessWidget {
  final SupplementNotifier notifier;
  const MyApp({super.key, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return SupplementProvider(
      notifier: notifier,
      child: MaterialApp.router(
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
      ),
    );
  }
}
