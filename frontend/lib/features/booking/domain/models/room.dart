/// Pure Domain Model — ไม่ผูกกับ dio/JSON โดยตรง (แยกจาก API shape ของ backend)
class Room {
  const Room({
    required this.id,
    required this.name,
    required this.location,
    required this.capacity,
    required this.description,
  });

  final int id;
  final String name;
  final String location;
  final int capacity;
  final String description;

  factory Room.fromJson(Map<String, dynamic> json) => Room(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        location: json['location'] as String? ?? '',
        capacity: json['capacity'] as int? ?? 0,
        description: json['description'] as String? ?? '',
      );
}
