class Trip {
  final int id;
  final String timestamp;
  final String city;
  final String startPoint;
  final String endPoint;
  final double totalKm;
  final int totalDurationSec;
  final int totalPauseSec;
  final double totalCost;
  final List<String> points;
  final List<String> waypointCoords;
  final List<String> waypointLabels;
  final String? username;

  Trip({
    required this.id,
    required this.timestamp,
    required this.city,
    required this.startPoint,
    required this.endPoint,
    required this.totalKm,
    required this.totalDurationSec,
    required this.totalPauseSec,
    required this.totalCost,
    required this.points,
    required this.waypointCoords,
    required this.waypointLabels,
    this.username,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as int,
      timestamp: json['timestamp'] as String,
      city: json['city'] as String,
      startPoint: json['start_point'] as String,
      endPoint: json['end_point'] as String,
      totalKm: (json['total_km'] as num).toDouble(),
      totalDurationSec: json['total_duration_sec'] as int,
      totalPauseSec: json['total_pause_sec'] as int,
      totalCost: (json['total_cost'] as num).toDouble(),
      points: List<String>.from(json['points'] as List),
      waypointCoords: List<String>.from(json['waypoint_coords'] as List? ?? []),
      waypointLabels: List<String>.from(json['waypoint_labels'] as List? ?? []),
      username: json['username'] as String?,
    );
  }
}
