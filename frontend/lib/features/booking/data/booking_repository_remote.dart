import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../utils/result.dart';
import '../domain/booking_repository.dart';
import '../domain/models/booking.dart';
import '../domain/models/room.dart';

/// ดึงข้อมูลจริงจาก Django REST API ผ่าน ApiClient (Resource Server ที่ป้องกันด้วย OIDC Access Token)
class BookingRepositoryRemote implements BookingRepository {
  // พารามิเตอร์ named ต้องไม่ขึ้นต้นด้วย _ เพื่อให้เรียกจากไฟล์อื่นได้ จึงใช้ initializing formal ไม่ได้
  BookingRepositoryRemote({required ApiClient apiClient})
      // ignore: prefer_initializing_formals
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<Result<List<Room>>> loadRooms({DateTime? startTime, DateTime? endTime}) async {
    try {
      final query = <String, dynamic>{};
      if (startTime != null && endTime != null) {
        query['start_time'] = startTime.toUtc().toIso8601String();
        query['end_time'] = endTime.toUtc().toIso8601String();
      }
      final response = await _apiClient.get<List<dynamic>>(
        '/rooms/',
        queryParameters: query.isEmpty ? null : query,
      );
      final rooms = (response.data ?? [])
          .map((e) => Room.fromJson(e as Map<String, dynamic>))
          .toList();
      return Result.ok(rooms);
    } on DioException catch (e) {
      return Result.error(Exception(dioErrorMessage(e)));
    }
  }

  @override
  Future<Result<List<Booking>>> loadMyBookings() async {
    try {
      final response = await _apiClient.get<List<dynamic>>('/bookings/');
      final bookings = (response.data ?? [])
          .map((e) => Booking.fromJson(e as Map<String, dynamic>))
          .toList();
      return Result.ok(bookings);
    } on DioException catch (e) {
      return Result.error(Exception(dioErrorMessage(e)));
    }
  }

  @override
  Future<Result<Booking>> createBooking({
    required int roomId,
    required DateTime startTime,
    required DateTime endTime,
    required String purpose,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/bookings/',
        data: {
          'room': roomId,
          'start_time': startTime.toUtc().toIso8601String(),
          'end_time': endTime.toUtc().toIso8601String(),
          'purpose': purpose,
        },
      );
      return Result.ok(Booking.fromJson(response.data!));
    } on DioException catch (e) {
      return Result.error(Exception(dioErrorMessage(e)));
    }
  }

  @override
  Future<Result<Booking>> updateBooking({
    required int id,
    required int roomId,
    required DateTime startTime,
    required DateTime endTime,
    required String purpose,
  }) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        '/bookings/$id/',
        data: {
          'room': roomId,
          'start_time': startTime.toUtc().toIso8601String(),
          'end_time': endTime.toUtc().toIso8601String(),
          'purpose': purpose,
        },
      );
      return Result.ok(Booking.fromJson(response.data!));
    } on DioException catch (e) {
      return Result.error(Exception(dioErrorMessage(e)));
    }
  }

  @override
  Future<Result<void>> cancelBooking(int id) async {
    try {
      await _apiClient.post('/bookings/$id/cancel/');
      return Result.ok(null);
    } on DioException catch (e) {
      return Result.error(Exception(dioErrorMessage(e)));
    }
  }

  @override
  Future<Result<void>> deleteBooking(int id) async {
    try {
      await _apiClient.delete('/bookings/$id/');
      return Result.ok(null);
    } on DioException catch (e) {
      return Result.error(Exception(dioErrorMessage(e)));
    }
  }
}
