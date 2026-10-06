enum BookingStatus { confirmed, cancelled }

/// Pure Domain Model ของการจองห้อง
class Booking {
  const Booking({
    required this.id,
    required this.roomId,
    required this.roomName,
    required this.startTime,
    required this.endTime,
    required this.purpose,
    required this.status,
  });

  final int id;
  final int roomId;
  final String roomName;
  final DateTime startTime;
  final DateTime endTime;
  final String purpose;
  final BookingStatus status;

  bool get isCancelled => status == BookingStatus.cancelled;

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id'] as int,
        roomId: json['room'] as int,
        roomName: json['room_name'] as String? ?? '',
        startTime: DateTime.parse(json['start_time'] as String).toLocal(),
        endTime: DateTime.parse(json['end_time'] as String).toLocal(),
        purpose: json['purpose'] as String? ?? '',
        status: json['status'] == 'cancelled'
            ? BookingStatus.cancelled
            : BookingStatus.confirmed,
      );
}
