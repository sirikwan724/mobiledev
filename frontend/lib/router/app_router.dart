import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/auth/presentation/screens/callback_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../features/booking/domain/models/room.dart';
import '../features/booking/domain/models/booking.dart';
import '../features/booking/presentation/screens/booking_screen.dart';
import '../features/booking/presentation/screens/my_bookings_screen.dart';
import '../features/booking/presentation/screens/rooms_screen.dart';
import '../features/booking/presentation/screens/dashboard_screen.dart';
import '../features/booking/domain/booking_repository.dart';
import '../features/booking/presentation/viewmodels/booking_form_viewmodel.dart';
import '../features/booking/presentation/viewmodels/my_bookings_viewmodel.dart';
import '../features/booking/presentation/viewmodels/rooms_viewmodel.dart';
import '../features/booking/presentation/viewmodels/dashboard_viewmodel.dart';

/// Route Guard: หน้าเนื้อหาทุกหน้าเข้าถึงได้หลังล็อกอินเท่านั้น
/// สร้างใหม่ทุกครั้งที่ AuthViewModel เปลี่ยนสถานะ (refreshListenable) เพื่อ redirect ทันที
GoRouter buildRouter(AuthViewModel auth) {
  return GoRouter(
    refreshListenable: auth,
    redirect: (context, state) {
      // Use the browser URI path so the OIDC callback is recognized even when
      // Flutter Web starts from a deep link containing an authorization code.
      final path = state.uri.path;

      // ระหว่างกู้คืน session ตอนเปิดแอป ให้รอที่หน้าเดิมก่อน (มักเป็น '/' หน้า splash)
      if (auth.status == AuthStatus.unknown) return null;

      // หน้า callback ต้องได้รับอนุญาตเสมอ เพื่อให้ประมวลผล authorization code ได้
      if (path == '/callback') return null;

      final authenticated = auth.status == AuthStatus.authenticated;

      if (path == '/') return authenticated ? '/rooms' : '/login';
      if (!authenticated && path != '/login') return '/login';
      if (authenticated && path == '/login') return '/rooms';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/callback',
        builder: (context, state) => CallbackScreen(callbackUri: state.uri),
      ),
      GoRoute(
        path: '/rooms',
        builder: (context, state) => ChangeNotifierProvider(
          create: (context) => RoomsViewModel(context.read<BookingRepository>()),
          child: const RoomsScreen(),
        ),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => ChangeNotifierProvider(
          create: (context) => DashboardViewModel(context.read<BookingRepository>()),
          child: const DashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/booking',
        builder: (context, state) {
          final room = state.extra as Room;
          return ChangeNotifierProvider(
            create: (context) =>
                BookingFormViewModel(context.read<BookingRepository>()),
            child: BookingScreen(room: room),
          );
        },
      ),
      GoRoute(
        path: '/booking/edit',
        builder: (context, state) {
          final booking = state.extra as Booking;
          final room = Room(
            id: booking.roomId,
            name: booking.roomName,
            location: '',
            capacity: 1,
            description: '',
          );
          return ChangeNotifierProvider(
            create: (context) => BookingFormViewModel(context.read<BookingRepository>()),
            child: BookingScreen(room: room, booking: booking),
          );
        },
      ),
      GoRoute(
        path: '/my-bookings',
        builder: (context, state) => ChangeNotifierProvider(
          create: (context) =>
              MyBookingsViewModel(context.read<BookingRepository>()),
          child: const MyBookingsScreen(),
        ),
      ),
    ],
  );
}
