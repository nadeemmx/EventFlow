class VenueModel {
  final int id;
  final String name;
  final String venueType;
  final int capacity;
  final String? description;
  final String? address;
  final double? latitude;
  final double? longitude;
  final double weekdayPrice;
  final double weekendPrice;
  final double peakPrice;
  final String status;
  final String? createdAt;

  VenueModel({
    required this.id,
    required this.name,
    required this.venueType,
    required this.capacity,
    this.description,
    this.address,
    this.latitude,
    this.longitude,
    required this.weekdayPrice,
    required this.weekendPrice,
    required this.peakPrice,
    required this.status,
    this.createdAt,
  });

  factory VenueModel.fromJson(Map<String, dynamic> json) {
    return VenueModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      venueType: json['venue_type'] as String? ?? '',
      capacity: json['capacity'] as int? ?? 0,
      description: json['description'] as String?,
      address: json['address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      weekdayPrice: (json['weekday_price'] as num?)?.toDouble() ?? 0,
      weekendPrice: (json['weekend_price'] as num?)?.toDouble() ?? 0,
      peakPrice: (json['peak_price'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'ACTIVE',
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'venue_type': venueType,
      'capacity': capacity,
      'description': description,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'weekday_price': weekdayPrice,
      'weekend_price': weekendPrice,
      'peak_price': peakPrice,
      'status': status,
      'created_at': createdAt,
    };
  }
}
