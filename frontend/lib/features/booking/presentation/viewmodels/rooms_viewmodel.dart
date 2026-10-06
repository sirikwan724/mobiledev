import 'package:flutter/foundation.dart';

import '../../domain/booking_repository.dart';
import '../../domain/models/room.dart';
import '../../../../utils/result.dart';

class RoomsViewModel extends ChangeNotifier {
  RoomsViewModel(this._repository) {
    load();
  }

  final BookingRepository _repository;

  List<Room> rooms = [];
  bool isLoading = false;
  String? errorMessage;
  String query = '';
  DateTime availabilityStart = DateTime.now().add(const Duration(hours: 1));
  DateTime availabilityEnd = DateTime.now().add(const Duration(hours: 2));
  bool isAvailabilityFilterActive = false;

  List<Room> get filteredRooms {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return rooms;
    return rooms.where((room) =>
      room.name.toLowerCase().contains(normalized) ||
      room.location.toLowerCase().contains(normalized) ||
      room.description.toLowerCase().contains(normalized)
    ).toList();
  }

  void search(String value) {
    query = value;
    notifyListeners();
  }

  void setAvailability(DateTime start, DateTime end) {
    availabilityStart = start;
    availabilityEnd = end;
    notifyListeners();
  }

  Future<void> searchAvailable() async {
    if (!availabilityStart.isBefore(availabilityEnd)) {
      errorMessage = 'เวลาสิ้นสุดต้องอยู่หลังเวลาเริ่มต้น';
      notifyListeners();
      return;
    }
    isAvailabilityFilterActive = true;
    await load();
  }

  Future<void> clearAvailability() async {
    isAvailabilityFilterActive = false;
    await load();
  }

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final result = await _repository.loadRooms(
      startTime: isAvailabilityFilterActive ? availabilityStart : null,
      endTime: isAvailabilityFilterActive ? availabilityEnd : null,
    );
    switch (result) {
      case Ok<List<Room>>():
        rooms = result.value;
      case Failure<List<Room>>():
        errorMessage = result.error.toString().replaceFirst('Exception: ', '');
    }

    isLoading = false;
    notifyListeners();
  }
}
