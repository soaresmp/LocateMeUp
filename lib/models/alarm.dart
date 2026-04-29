import 'dart:math';

import 'package:uuid/uuid.dart';

class Alarm {
  final String id;
  final String title;
  final String subtitle;
  final double latitude;
  final double longitude;
  final double radius; // meters
  bool isOn;

  Alarm({
    String? id,
    required this.title,
    required this.subtitle,
    required this.latitude,
    required this.longitude,
    this.radius = 1000,
    this.isOn = true,
  }) : id = id ?? const Uuid().v4();

  /// Haversine distance in metres between this alarm's centre and [lat]/[lng].
  double distanceMeters(double lat, double lng) {
    const double earthRadius = 6371000;
    final double dLat = (lat - latitude) * pi / 180;
    final double dLng = (lng - longitude) * pi / 180;
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(latitude * pi / 180) * cos(lat * pi / 180) * sin(dLng / 2) * sin(dLng / 2);
    return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  bool isInRegion(double lat, double lng) => distanceMeters(lat, lng) <= radius;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
        'isOn': isOn,
      };

  factory Alarm.fromJson(Map<String, dynamic> json) => Alarm(
        id: json['id'] as String,
        title: json['title'] as String,
        subtitle: json['subtitle'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        radius: (json['radius'] as num?)?.toDouble() ?? 1000,
        isOn: json['isOn'] as bool? ?? true,
      );
}
