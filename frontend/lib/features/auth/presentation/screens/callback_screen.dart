import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';

/// หน้าที่ OIDC Server redirect กลับมาหลังล็อกอิน (redirect_uri = http://localhost:50000/callback)
/// แลก authorization code เป็น token แล้วให้ router guard พาไปหน้าถัดไปเอง
class CallbackScreen extends StatefulWidget {
  const CallbackScreen({super.key, required this.callbackUri});

  final Uri callbackUri;

  @override
  State<CallbackScreen> createState() => _CallbackScreenState();
}

class _CallbackScreenState extends State<CallbackScreen> {
  @override
  void initState() {
    super.initState();
    // เรียกครั้งเดียวตอนหน้าโหลด ไม่ใช่ทุกครั้งที่ build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _completeSignIn();
    });
  }

  Future<void> _completeSignIn() async {
    final auth = context.read<AuthViewModel>();
    await auth.handleCallback(widget.callbackUri);
    if (!mounted) return;

    // /callback ถูกยกเว้นจาก router guard เพื่อให้แลก code ได้ก่อน
    // ดังนั้นเมื่อล็อกอินสำเร็จต้องพาออกจาก callback อย่างชัดเจน
    if (auth.status == AuthStatus.authenticated) {
      context.go('/rooms');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (auth.errorMessage == null) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('กำลังยืนยันตัวตน...'),
            ] else ...[
              Icon(Icons.error_outline, color: Colors.red.shade400, size: 48),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(auth.errorMessage!, textAlign: TextAlign.center),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('กลับไปหน้าเข้าสู่ระบบ'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
