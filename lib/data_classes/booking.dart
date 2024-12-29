import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String? id;
  final String podId;
  final String userId;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime createdAt;
  final int price;
  final String notes;
  String status;

  Booking({
    this.id,
    required this.podId,
    required this.userId,
    required this.startTime,
    required this.endTime,
    required this.createdAt,
    required this.price,
    required this.notes,
    required this.status,
  });

  /// Factory method to create a Booking from Firestore data
  factory Booking.fromFirestore(String id, Map<String, dynamic> data) {
    // Validate and sanitize Firestore data
    if (data['pod_id'] is! String || data['pod_id'] == null) {
      throw FormatException("Invalid pod_id");
    }
    if (data['user_id'] is! String || data['user_id'] == null) {
      throw FormatException("Invalid user_id");
    }
    if (data['start_time'] is! Timestamp || data['start_time'] == null) {
      throw FormatException("Invalid start_time");
    }
    if (data['end_time'] is! Timestamp || data['end_time'] == null) {
      throw FormatException("Invalid end_time");
    }
    if (data['created_at'] != null && data['created_at'] is! Timestamp) {
      throw FormatException("Invalid created_at");
    }
    if (data['price'] is! int || data['price'] == null) {
      throw FormatException("Invalid price");
    }
    if (data['notes'] is! String) {
      throw FormatException("Invalid notes");
    }
    if (data['status'] is! String ||
        !['confirmed', 'pending', 'cancelled'].contains(data['status'])) {
      throw FormatException("Invalid status");
    }

    return Booking(
      id: id,
      podId: data['pod_id'],
      userId: data['user_id'],
      startTime: (data['start_time'] as Timestamp).toDate(),
      endTime: (data['end_time'] as Timestamp).toDate(),
      createdAt: data['created_at'] != null
          ? (data['created_at'] as Timestamp).toDate()
          : DateTime.now(),
      price: data['price'],
      notes: data['notes'] ?? "",
      status: data['status'],
    );
  }

  /// Convert Booking to a Firestore-ready map
  Map<String, dynamic> toFirestore() {
    return {
      'pod_id': podId,
      'user_id': userId,
      'start_time': Timestamp.fromDate(startTime),
      'end_time': Timestamp.fromDate(endTime),
      'created_at': Timestamp.fromDate(createdAt),
      'price': price,
      'notes': notes,
      'status': status,
    };
  }

  @override
  String toString() {
    return {
      'pod_id': podId,
      'user_id': userId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'price': price,
      'notes': notes,
      'status': status,
    }.toString();
  }
}
