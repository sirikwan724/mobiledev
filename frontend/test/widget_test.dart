// เทสพื้นฐาน: แอปต้องบูตขึ้นมาได้และแสดงหน้าจอเริ่มต้น (splash/login) โดยไม่ crash
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/main.dart';

void main() {
  testWidgets('App boots without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    // ตอนเริ่มแอปต้องเจอ CircularProgressIndicator (หน้า splash ระหว่างกู้คืน session)
    // หรือหน้าล็อกอินถ้ากู้คืนเสร็จเร็ว — อย่างใดอย่างหนึ่งต้องเจอ ไม่ crash
    final hasSpinner = find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
    final hasLoginButton = find.text('เข้าสู่ระบบ').evaluate().isNotEmpty;
    expect(hasSpinner || hasLoginButton, isTrue);
  });
}
