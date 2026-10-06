import 'package:flutter/foundation.dart';

import '../../domain/booking_repository.dart';
import '../../domain/models/booking.dart';
import '../../../../utils/result.dart';

enum BookingFilter { all, confirmed, cancelled }

class MyBookingsViewModel extends ChangeNotifier {
  MyBookingsViewModel(this._repository) {
    load();
  }

  final BookingRepository _repository;

  List<Booking> bookings = [];
  bool isLoading = false;
  String? errorMessage;
  String? actionErrorMessage;
  BookingFilter filter = BookingFilter.all;

  List<Booking> get filteredBookings => bookings.where((booking) {
        return switch (filter) {
          BookingFilter.all => true,
          BookingFilter.confirmed => !booking.isCancelled,
          BookingFilter.cancelled => booking.isCancelled,
        };
      }).toList();

  void setFilter(BookingFilter value) {
    filter = value;
    notifyListeners();
  }

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final result = await _repository.loadMyBookings();
    switch (result) {
      case Ok<List<Booking>>():
        bookings = result.value;
      case Failure<List<Booking>>():
        errorMessage = result.error.toString().replaceFirst('Exception: ', '');
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> cancel(int id) async {
    actionErrorMessage = null;
    final result = await _repository.cancelBooking(id);
    switch (result) {
      case Ok():
        await load();
      case Failure():
        actionErrorMessage = result.error.toString().replaceFirst('Exception: ', '');
        notifyListeners();
    }
  }

  Future<bool> delete(int id) async {
    actionErrorMessage = null;
    final result = await _repository.deleteBooking(id);
    switch (result) {
      case Ok():
        await load();
        return true;
      case Failure():
        actionErrorMessage = result.error.toString().replaceFirst('Exception: ', '');
        notifyListeners();
        return false;
    }
  }
}
