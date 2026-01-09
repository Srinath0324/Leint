/// Lead status enum for tracking lead progress
enum LeadStatus {
  unreached,
  selected,
  followUp,
  noResponse,
  accepted,
  rejected;


  String get displayName {
    switch (this) {
      case LeadStatus.unreached:
        return 'Unreached';
      case LeadStatus.selected:
        return 'Selected';  
      case LeadStatus.followUp:
        return 'Follow Up';
      case LeadStatus.noResponse:
        return 'No Response';
      case LeadStatus.accepted:
        return 'Accepted';
      case LeadStatus.rejected:
        return 'Rejected';
    }
  }

  static LeadStatus fromString(String value) {
    switch (value.toLowerCase().replaceAll(' ', '').replaceAll('_', '')) {
      case 'selected':
        return LeadStatus.selected;
      case 'followup':
        return LeadStatus.followUp;
      case 'noresponse':
        return LeadStatus.noResponse;
      case 'accepted':
        return LeadStatus.accepted;
      case 'rejected':
        return LeadStatus.rejected;
      default:
        return LeadStatus.unreached;
    }
  }

  String toFirestore() {
    return name;
  }
}

/// Individual lead model from CSV data
class LeadModel {
  final String id;
  final String name;
  final String categories;
  final String address;
  final String website;
  final String email;
  final String phone;
  final double? latitude;
  final double? longitude;
  final String reviews;
  final String ratings;
  final String googleMapsUrl;
  final Map<String, String> socialMedias;
  final Map<String, dynamic> extraFields;
  final LeadStatus status;

  LeadModel({
    required this.id,
    required this.name,
    this.categories = 'Not Found',
    this.address = 'Not Found',
    this.website = 'Not Found',
    this.email = 'Not Found',
    this.phone = 'Not Found',
    this.latitude,
    this.longitude,
    this.reviews = 'Not Found',
    this.ratings = 'Not Found',
    this.googleMapsUrl = '',
    this.socialMedias = const {},
    this.extraFields = const {},
    this.status = LeadStatus.unreached,
  });

  factory LeadModel.fromMap(Map<String, dynamic> map, String id) {
    return LeadModel(
      id: id,
      name: _parseField(map['name']),
      categories: _parseField(map['categories']),
      address: _parseField(map['address']),
      website: _parseField(map['website']),
      email: _parseField(map['email']),
      phone: _parseField(map['phone']),
      latitude: _parseDouble(map['latitude']),
      longitude: _parseDouble(map['longitude']),
      reviews: _parseField(map['reviews']),
      ratings: _parseField(map['ratings']),
      googleMapsUrl: map['googleMapsUrl'] ?? '',
      socialMedias: Map<String, String>.from(map['socialMedias'] ?? {}),
      extraFields: Map<String, dynamic>.from(map['extraFields'] ?? {}),
      status: LeadStatus.fromString(map['status'] ?? 'unreached'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'categories': categories,
      'address': address,
      'website': website,
      'email': email,
      'phone': phone,
      'latitude': latitude,
      'longitude': longitude,
      'reviews': reviews,
      'ratings': ratings,
      'googleMapsUrl': googleMapsUrl,
      'socialMedias': socialMedias,
      'extraFields': extraFields,
      'status': status.toFirestore(),
    };
  }

  LeadModel copyWith({
    String? name,
    String? categories,
    String? address,
    String? website,
    String? email,
    String? phone,
    double? latitude,
    double? longitude,
    String? reviews,
    String? ratings,
    String? googleMapsUrl,
    Map<String, String>? socialMedias,
    Map<String, dynamic>? extraFields,
    LeadStatus? status,
  }) {
    return LeadModel(
      id: id,
      name: name ?? this.name,
      categories: categories ?? this.categories,
      address: address ?? this.address,
      website: website ?? this.website,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      reviews: reviews ?? this.reviews,
      ratings: ratings ?? this.ratings,
      googleMapsUrl: googleMapsUrl ?? this.googleMapsUrl,
      socialMedias: socialMedias ?? this.socialMedias,
      extraFields: extraFields ?? this.extraFields,
      status: status ?? this.status,
    );
  }

  static String _parseField(dynamic value) {
    if (value == null) return 'Not Found';
    final str = value.toString().trim();
    if (str.isEmpty || 
        str.toLowerCase() == 'n/a' || 
        str.toLowerCase() == 'null' ||
        str.contains('*** Visible after upgrade ***')) {
      return 'Not Found';
    }
    return str;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }
}
