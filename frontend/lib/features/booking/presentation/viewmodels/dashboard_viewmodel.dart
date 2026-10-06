import 'package:flutter/foundation.dart';

import '../../../../utils/result.dart';
import '../../domain/booking_repository.dart';
import '../../domain/models/booking.dart';
import '../../domain/models/room.dart';

class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel(this._repository) {
    load();
  }

  final BookingRepository _repository;

  List<Room> rooms = [];
  List<Booking> bookings = [];
  bool isLoading = false;
  String? errorMessage;

  int get upcomingCount => bookings
      .where((booking) =>
          !booking.isCancelled && booking.startTime.isAfter(DateTime.now()))
      .length;

  int get cancelledCount => bookings.where((booking) => booking.isCancelled).length;

  Booking? get nextBooking {
    final now = DateTime.now();
    final upcoming = bookings
        .where((booking) => !booking.isCancelled && booking.endTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final results = await Future.wait([
      _repository.loadRooms(),
      _repository.loadMyBookings(),
    ]);
    final roomResult = results[0];
    final bookingResult = results[1];

    if (roomResult case Ok<List<Room>>(:final value)) {
      rooms = value;
    } else if (roomResult case Failure<List<Room>>(:final error)) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
    }

    if (bookingResult case Ok<List<Booking>>(:final value)) {
      bookings = value;
    } else if (bookingResult case Failure<List<Booking>>(:final error)) {
      errorMessage ??= error.toString().replaceFirst('Exception: ', '');
    }

    isLoading = false;
    notifyListeners();
  }
}
