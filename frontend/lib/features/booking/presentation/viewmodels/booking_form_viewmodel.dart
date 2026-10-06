import 'package:flutter/foundation.dart';

import '../../domain/booking_repository.dart';
import '../../../../utils/result.dart';

class BookingFormViewModel extends ChangeNotifier {
  BookingFormViewModel(this._repository);

  final BookingRepository _repository;

  bool isSaving = false;
  String? errorMessage;

  /// คืนค่า true เมื่อจองสำเร็จ
  Future<bool> submit({
    int? bookingId,
    required int roomId,
    required DateTime startTime,
    required DateTime endTime,
    required String purpose,
  }) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();

    final result = bookingId == null
        ? await _repository.createBooking(
            roomId: roomId,
            startTime: startTime,
            endTime: endTime,
            purpose: purpose,
          )
        : await _repository.updateBooking(
            id: bookingId,
            roomId: roomId,
            startTime: startTime,
            endTime: endTime,
            purpose: purpose,
          );

    isSaving = false;
    switch (result) {
      case Ok():
        notifyListeners();
        return true;
      case Failure():
        errorMessage = result.error.toString().replaceFirst('Exception: ', '');
        notifyListeners();
        return false;
    }
  }
}
