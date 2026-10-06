import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Service Layer: ติดต่อ REST API แบบไร้สถานะ (Stateless) — ไม่รู้จัก UI หรือ ViewModel เลย
/// รับฟังก์ชันขอ Access Token ผ่าน constructor เพื่อแนบ Authorization header อัตโนมัติทุก request
class ApiClient {
  // ตั้งชื่อพารามิเตอร์เป็น getAccessToken (ไม่ใช่ _getAccessToken) เพราะพารามิเตอร์แบบ named
  // ที่ขึ้นต้นด้วย _ จะเรียกใช้จากไฟล์อื่นไม่ได้ — initializing formal จึงใช้ไม่ได้ในเคสนี้
  ApiClient({required Future<String?> Function() getAccessToken})
      // ignore: prefer_initializing_formals
      : _getAccessToken = getAccessToken {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Future<String?> Function() _getAccessToken;
  final Dio dio = Dio(BaseOptions(baseUrl: _baseUrl));

  static String get _baseUrl {
    // Android emulator เรียกเครื่องโฮสต์ผ่าน 10.0.2.2 — เผื่อไว้ถึงแม้โจทย์เน้น Flutter Web
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api';
    }
    return 'http://127.0.0.1:8000/api';
  }

  Future<Response<T>> get<T>(String path,
          {Map<String, dynamic>? queryParameters}) =>
      dio.get<T>(path, queryParameters: queryParameters);

  Future<Response<T>> post<T>(String path, {dynamic data}) =>
      dio.post<T>(path, data: data);

  Future<Response<T>> put<T>(String path, {dynamic data}) =>
      dio.put<T>(path, data: data);

  Future<Response<T>> delete<T>(String path) => dio.delete<T>(path);
}

/// แปลง DioException เป็นข้อความอ่านง่ายสำหรับแสดงบน UI
String dioErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data.isNotEmpty) {
      final msg = data['detail'] ?? data['non_field_errors'] ?? data.values.first;
      return (msg is List ? msg.join('\n') : msg).toString();
    }
    if (error.response == null) return 'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้';
    return 'เกิดข้อผิดพลาด (${error.response?.statusCode})';
  }
  return error.toString();
}
