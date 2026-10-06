import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/api/api_client.dart';
import 'core/auth/auth_service.dart';
import 'core/auth/secure_storage_service.dart';
import 'core/theme/theme_mode_controller.dart';
import 'features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'features/booking/data/booking_repository_remote.dart';
import 'features/booking/domain/booking_repository.dart';
import 'router/app_router.dart';

/// จุดฉีด Dependency ระดับ Root ของแอป (Dependency Injection ตามแนว MVVM สัปดาห์ที่ 15)
/// Service -> Repository -> ViewModel -> View เรียงชั้นลงมา ผ่าน MultiProvider ตัวเดียว
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // --- Services (stateless, ฉีดจาก constructor) ---
        Provider<SecureStorageService>(create: (_) => SecureStorageService()),
        ChangeNotifierProvider<ThemeModeController>(
          create: (_) => ThemeModeController(),
        ),
        Provider<AuthService>(
          create: (context) => AuthService(context.read<SecureStorageService>()),
        ),

        // --- Auth ViewModel (ต้องมาก่อน ApiClient เพราะ ApiClient ต้องใช้ accessToken getter) ---
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) => AuthViewModel(context.read<AuthService>()),
        ),

        // --- ApiClient ฉีด accessToken getter จาก AuthViewModel ---
        Provider<ApiClient>(
          create: (context) => ApiClient(
            getAccessToken: () => context.read<AuthService>().accessToken,
          ),
        ),
        Provider<BookingRepository>(
          create: (context) =>
              BookingRepositoryRemote(apiClient: context.read<ApiClient>()),
        ),

        // สร้าง GoRouter ครั้งเดียว (lazy: false) แล้วให้มันฟัง AuthViewModel เอง
        // ผ่าน refreshListenable — ไม่สร้างใหม่ทุกครั้งที่ auth เปลี่ยนสถานะ
        Provider<GoRouter>(
          create: (context) => buildRouter(context.read<AuthViewModel>()),
          lazy: false,
        ),
      ],
      child: Consumer<ThemeModeController>(
        builder: (context, themeController, _) => MaterialApp.router(
          title: 'จองห้อง มอ.',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          themeMode: themeController.isDark ? ThemeMode.dark : ThemeMode.light,
          routerConfig: context.read<GoRouter>(),
        ),
      ),
    );
  }
}
