import 'dart:convert';

enum TravelStatus { pending, loaded, unloaded, missing }

class TravelItemDetail {
  final String id;
  final String name;
  TravelStatus status;

  TravelItemDetail({required this.id, required this.name, this.status = TravelStatus.pending});
}

class TravelItemStatus {
  final String boxId;
  final String boxName;
  final String location;
  TravelStatus status;
  final List<TravelItemDetail> itemStatuses; // List of items

  TravelItemStatus({
    required this.boxId,
    required this.boxName,
    required this.location,
    this.status = TravelStatus.pending,
    this.itemStatuses = const [],
  });

  Map<String, dynamic> toMap(String sessionId) => {
    'session_id': sessionId,
    'box_id': boxId,
    'status': status.name,
  };

  factory TravelItemStatus.fromMap(Map<String, dynamic> map, {String? boxName, String? location, List<TravelItemDetail>? items}) => TravelItemStatus(
    boxId: map['box_id'] ?? map['boxId'] ?? '',
    boxName: boxName ?? map['boxName'] ?? '',
    location: location ?? map['location'] ?? '',
    status: TravelStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'pending'),
        orElse: () => TravelStatus.pending,
    ),
    itemStatuses: items ?? const [],
  );
}

class TravelModel {
  final String id;
  final String tripName;
  final String fromLocation;
  final String toLocation;
  final DateTime startTime;
  final DateTime? endTime;
  final String status;
  final String? notes;
  final List<TravelItemStatus> itemStatuses;

  TravelModel({
    required this.id,
    required this.tripName,
    required this.fromLocation,
    required this.toLocation,
    required this.startTime,
    this.endTime,
    required this.status,
    this.notes,
    required this.itemStatuses,
  });

  bool get isCompleted => status == 'completed';

  Map<String, dynamic> toSessionMap() {
    return {
      'id': id,
      'trip_name': tripName,
      'from_location': fromLocation,
      'to_location': toLocation,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'status': status,
      'notes': notes,
    };
  }

  factory TravelModel.fromSessionMap(Map<String, dynamic> map, List<TravelItemStatus> items) {
    return TravelModel(
      id: map['id'],
      tripName: map['trip_name'] ?? map['name'] ?? '',
      fromLocation: map['from_location'] ?? map['fromLocation'] ?? '',
      toLocation: map['to_location'] ?? map['toLocation'] ?? '',
      startTime: DateTime.tryParse(map['start_time'] ?? map['timestamp'] ?? '') ?? DateTime.now(),
      endTime: map['end_time'] != null ? DateTime.tryParse(map['end_time']) : null,
      status: map['status'] ?? (map['isCompleted'] == 1 ? 'completed' : 'active'),
      notes: map['notes'],
      itemStatuses: items,
    );
  }
}
