import '../../../utils/result.dart';
import 'models/booking.dart';
import 'models/room.dart';

/// สัญญา (contract) ของ Repository — ViewModel รู้จักแค่ชั้นนี้ ไม่รู้จัก ApiClient/dio โดยตรง
/// ทำให้สลับไปใช้ Fake Repository ตอนเทสได้ง่าย (Dependency Inversion)
abstract class BookingRepository {
  Future<Result<List<Room>>> loadRooms({DateTime? startTime, DateTime? endTime});

  Future<Result<List<Booking>>> loadMyBookings();

  Future<Result<Booking>> createBooking({
    required int roomId,
    required DateTime startTime,
    required DateTime endTime,
    required String purpose,
  });

  Future<Result<Booking>> updateBooking({
    required int id,
    required int roomId,
    required DateTime startTime,
    required DateTime endTime,
    required String purpose,
  });

  Future<Result<void>> cancelBooking(int id);

  Future<Result<void>> deleteBooking(int id);
}
