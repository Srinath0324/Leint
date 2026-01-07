import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:csv/csv.dart';
import '../models/lead_model.dart';

/// Service for parsing CSV files into Lead models
class CsvService {
  /// Parse CSV content and return list of LeadModel
  /// Handles both organic produce and leadstal CSV formats
  /// Also removes duplicate rows based on content hash
  static List<LeadModel> parseCsv(String csvContent) {
    final List<List<dynamic>> rows = const CsvToListConverter().convert(csvContent);
    
    if (rows.isEmpty) return [];

    // Get headers from first row - normalize to lowercase
    final headers = rows.first.map((h) => _normalizeHeader(h.toString())).toList();
    
    // Map column indices
    final columnMap = _mapColumns(headers);
    
    final leads = <LeadModel>[];
    final seenHashes = <String>{};
    
    // Process each row (skip header)
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty || row.every((cell) => cell.toString().trim().isEmpty)) {
        continue; // Skip empty rows
      }
      
      // Generate hash for duplicate detection
      final rowHash = _generateRowHash(row);
      if (seenHashes.contains(rowHash)) {
        continue; // Skip duplicate rows
      }
      seenHashes.add(rowHash);
      
      final lead = _parseRow(row, headers, columnMap, 'lead_$i');
      leads.add(lead);
    }
    
    return leads;
  }

  /// Normalize header - lowercase, remove special chars, trim
  static String _normalizeHeader(String header) {
    return header
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[_\-\s]+'), ' ')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .trim();
  }

  /// Generate hash for a row to detect duplicates
  static String _generateRowHash(List<dynamic> row) {
    final content = row.map((e) => e.toString().trim().toLowerCase()).join('|');
    return md5.convert(utf8.encode(content)).toString();
  }

  /// Map standard column names to indices
  /// Uses flexible matching to handle variations
  static Map<String, int> _mapColumns(List<String> headers) {
    final map = <String, int>{};
    
    for (int i = 0; i < headers.length; i++) {
      final header = headers[i];
      
      // Name/Title - primary identifier
      if (map['name'] == null && _matchesNameField(header)) {
        map['name'] = i;
      }
      // Categories/Category (NOT Type)
      else if (map['categories'] == null && _matchesCategoriesField(header)) {
        map['categories'] = i;
      }
      // Address/Fulladdress/Location
      else if (map['address'] == null && _matchesAddressField(header)) {
        map['address'] = i;
      }
      // Website
      else if (map['website'] == null && _matchesWebsiteField(header)) {
        map['website'] = i;
      }
      // Email
      else if (map['email'] == null && _matchesEmailField(header)) {
        map['email'] = i;
      }
      // Phone
      else if (map['phone'] == null && _matchesPhoneField(header)) {
        map['phone'] = i;
      }
      // Latitude
      else if (map['latitude'] == null && _matchesLatitudeField(header)) {
        map['latitude'] = i;
      }
      // Longitude
      else if (map['longitude'] == null && _matchesLongitudeField(header)) {
        map['longitude'] = i;
      }
      // Reviews
      else if (map['reviews'] == null && _matchesReviewsField(header)) {
        map['reviews'] = i;
      }
      // Ratings
      else if (map['ratings'] == null && _matchesRatingsField(header)) {
        map['ratings'] = i;
      }
      // Google Maps URL
      else if (map['googleMapsUrl'] == null && _matchesGoogleMapsField(header)) {
        map['googleMapsUrl'] = i;
      }
      // Social Media fields
      else if (map['socialMedias'] == null && _matchesSocialMediaField(header)) {
        map['socialMedias'] = i;
      }
      else if (map['facebook'] == null && _matchesFacebookField(header)) {
        map['facebook'] = i;
      }
      else if (map['instagram'] == null && _matchesInstagramField(header)) {
        map['instagram'] = i;
      }
      else if (map['twitter'] == null && _matchesTwitterField(header)) {
        map['twitter'] = i;
      }
      else if (map['linkedin'] == null && _matchesLinkedInField(header)) {
        map['linkedin'] = i;
      }
      else if (map['yelp'] == null && _matchesYelpField(header)) {
        map['yelp'] = i;
      }
    }
    
    return map;
  }

  // Field matchers - flexible and case-insensitive
  static bool _matchesNameField(String h) {
    return h == 'name' || h == 'title' || h == 'business name' || 
           h == 'company' || h == 'company name' || h == 'store name' ||
           h == 'shop name' || h == 'business';
  }

  static bool _matchesCategoriesField(String h) {
    return h == 'categories' || h == 'category' || h == 'business type' ||
           h == 'industry' || h == 'sector';
  }

  static bool _matchesAddressField(String h) {
    return h == 'address' || h == 'fulladdress' || h == 'full address' ||
           h == 'location' || h == 'street address' || h == 'street' ||
           h == 'place' || h == 'addr';
  }

  static bool _matchesWebsiteField(String h) {
    return h == 'website' || h == 'url' || h == 'web' || h == 'site' ||
           h == 'webpage' || h == 'web page' || h == 'homepage';
  }

  static bool _matchesEmailField(String h) {
    return h == 'email' || h == 'e mail' || h == 'mail' || 
           h == 'email address' || h == 'e mail address';
  }

  static bool _matchesPhoneField(String h) {
    return h == 'phone' || h == 'phones' || h == 'telephone' || 
           h == 'tel' || h == 'contact' || h == 'mobile' ||
           h == 'phone number' || h == 'contact number';
  }

  static bool _matchesLatitudeField(String h) {
    return h == 'latitude' || h == 'lat';
  }

  static bool _matchesLongitudeField(String h) {
    return h == 'longitude' || h == 'long' || h == 'lng' || h == 'lon';
  }

  static bool _matchesReviewsField(String h) {
    return h == 'reviews' || h == 'review count' || h == 'total review' ||
           h == 'total reviews' || h == 'review' || h == 'num reviews';
  }

  static bool _matchesRatingsField(String h) {
    return h == 'rating' || h == 'ratings' || h == 'average rating' ||
           h == 'avg rating' || h == 'stars' || h == 'score';
  }

  static bool _matchesGoogleMapsField(String h) {
    return h == 'google maps url' || h == 'googlemapsurl' || 
           h == 'maps url' || h == 'google maps' || h == 'map url' ||
           h == 'gmap' || h == 'gmaps' || h == 'google map url';
  }

  static bool _matchesSocialMediaField(String h) {
    return h == 'social media' || h == 'social medias' || h == 'social' ||
           h == 'socials' || h == 'social links';
  }

  static bool _matchesFacebookField(String h) {
    return h == 'facebook' || h == 'fb';
  }

  static bool _matchesInstagramField(String h) {
    return h == 'instagram' || h == 'insta' || h == 'ig';
  }

  static bool _matchesTwitterField(String h) {
    return h == 'twitter' || h == 'x';
  }

  static bool _matchesLinkedInField(String h) {
    return h == 'linkedin' || h == 'linked in';
  }

  static bool _matchesYelpField(String h) {
    return h == 'yelp';
  }

  /// Parse a single row into a LeadModel
  static LeadModel _parseRow(
    List<dynamic> row,
    List<String> headers,
    Map<String, int> columnMap,
    String id,
  ) {
    String getValue(String key) {
      final index = columnMap[key];
      if (index == null || index >= row.length) return 'Not Found';
      return _normalizeValue(row[index]);
    }

    double? getDouble(String key) {
      final index = columnMap[key];
      if (index == null || index >= row.length) return null;
      final value = row[index];
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      return double.tryParse(value.toString().replaceAll(',', ''));
    }

    // Build social medias map
    final socialMedias = <String, String>{};
    for (final platform in ['facebook', 'instagram', 'twitter', 'linkedin', 'yelp']) {
      final value = getValue(platform);
      if (value != 'Not Found') {
        socialMedias[platform] = value;
      }
    }
    
    // General social media field
    final generalSocial = getValue('socialMedias');
    if (generalSocial != 'Not Found') {
      socialMedias['general'] = generalSocial;
    }

    // Collect extra fields (columns not in standard mapping)
    final extraFields = <String, dynamic>{};
    final mappedIndices = columnMap.values.toSet();
    
    for (int i = 0; i < headers.length; i++) {
      if (!mappedIndices.contains(i) && i < row.length) {
        final value = _normalizeValue(row[i]);
        if (value != 'Not Found') {
          // Get original header name for extra fields
          extraFields[headers[i]] = value;
        }
      }
    }

    return LeadModel(
      id: id,
      name: getValue('name'),
      categories: getValue('categories'),
      address: getValue('address'),
      website: getValue('website'),
      email: getValue('email'),
      phone: getValue('phone'),
      latitude: getDouble('latitude'),
      longitude: getDouble('longitude'),
      reviews: getValue('reviews'),
      ratings: getValue('ratings'),
      googleMapsUrl: getValue('googleMapsUrl'),
      socialMedias: socialMedias,
      extraFields: extraFields,
      status: LeadStatus.unreached,
    );
  }

  /// Normalize value - handle N/A, empty, null values
  static String _normalizeValue(dynamic value) {
    if (value == null) return 'Not Found';
    final str = value.toString().trim();
    if (str.isEmpty ||
        str.toLowerCase() == 'n/a' ||
        str.toLowerCase() == 'null' ||
        str.toLowerCase() == 'na' ||
        str.toLowerCase() == 'none' ||
        str.contains('*** Visible after upgrade ***')) {
      return 'Not Found';
    }
    // Remove extra quotes
    String result = str;
    while (result.startsWith('"') && result.endsWith('"') && result.length > 1) {
      result = result.substring(1, result.length - 1).trim();
    }
    return result;
  }
}
