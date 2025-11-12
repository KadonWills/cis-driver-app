import 'package:cloud_firestore/cloud_firestore.dart';

class LocationModel {
  final double latitude;
  final double longitude;
  final String address;
  final String postcode;
  final String city;
  final String? county;
  final String country;

  LocationModel({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.postcode,
    required this.city,
    this.county,
    required this.country,
  });

  factory LocationModel.fromMap(Map<String, dynamic> map) {
    return LocationModel(
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      address: map['address'] ?? '',
      postcode: map['postcode'] ?? '',
      city: map['city'] ?? '',
      county: map['county'],
      country: map['country'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'postcode': postcode,
      'city': city,
      if (county != null) 'county': county,
      'country': country,
    };
  }

  factory LocationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LocationModel.fromMap(data);
  }
}

