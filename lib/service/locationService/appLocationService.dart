import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gtlmd/api/HttpCalls.dart';
import 'package:gtlmd/common/Utils.dart';
import 'package:gtlmd/common/commonResponse.dart';
import 'package:http/http.dart' as http;

class AppLocationService {
  static final AppLocationService _instance = AppLocationService._internal();
  factory AppLocationService() => _instance;
  AppLocationService._internal();

  /// Fetches the current physical address.
  /// Handles permissions, coordinate fetching, and reverse geocoding.
  Future<String?> getCurrentAddress() async {
    try {
      // 1. Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
        return null;
      }

      // 2. Handle permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied.');
        await Geolocator.openAppSettings();
        return null;
      }

      // 3. Get current position
      Position position = await Geolocator.getCurrentPosition(
          // ignore: deprecated_member_use
          desiredAccuracy: LocationAccuracy.high);

      // 4. Ensure API Key is available for fallback
      if (GOOGLE_MAPS_API_KEY.isEmpty) {
        await _fetchGoogleMapApiKey();
      }

      // 5. Reverse Geocoding
      String? address =
          await getAddressFromLatLng(position.latitude, position.longitude);

      return address;
    } catch (e) {
      debugPrint('Error in AppLocationService.getCurrentAddress: $e');
      return null;
    }
  }

  /// Internal method to fetch API key if missing
  Future<void> _fetchGoogleMapApiKey() async {
    try {
      Map<String, String> params = {
        "keyNo": "73",
        "prmcompanyid": savedLogin.companyid.toString(),
      };
      CommonResponse resp = await apiGet("${bookingUrl}GetKey", params);
      if (resp.commandStatus == 1 && resp.message != null) {
        GOOGLE_MAPS_API_KEY = resp.message.toString();
        debugPrint('Fetched Google Maps API Key');
      }
    } catch (e) {
      debugPrint('Error fetching Google Maps API Key: $e');
    }
  }

  // /// Reverse geocoding with fallback to Google API
  // Future<String?> getAddressFromLatLng(double lat, double lng) async {
  //   // Stage 1: Try with geocoding package
  //   try {
  //     List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
  //     if (placemarks.isNotEmpty) {
  //       Placemark p = placemarks[0];
  //       return '${p.street}, ${p.subLocality}, ${p.subAdministrativeArea}, ${p.postalCode}';
  //     }
  //   } catch (e) {
  //     debugPrint('geocoding package failed, trying Google API fallback: $e');
  //   }

  //   // Stage 2: Fallback to Google Geocoding API if key is available
  //   if (GOOGLE_MAPS_API_KEY.isNotEmpty) {
  //     try {
  //       String host = 'https://maps.google.com/maps/api/geocode/json';
  //       final url =
  //           '$host?key=$GOOGLE_MAPS_API_KEY&language=en&latlng=$lat,$lng';
  //       var response = await http.get(Uri.parse(url));
  //       if (response.statusCode == 200) {
  //         Map data = jsonDecode(response.body);
  //         if (data["results"] != null && data["results"].isNotEmpty) {
  //           return data["results"][0]["formatted_address"];
  //         }
  //       }
  //     } catch (e) {
  //       debugPrint('Google API fallback also failed: $e');
  //     }
  //   }

  //   return "Location Not Captured";
  // }
  Future<String?> getAddressFromLatLng(double lat, double lng) async {
    // Stage 1: Try with geocoding package
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark p = placemarks[0];
        return '${p.street}, ${p.subLocality}, ${p.subAdministrativeArea}, ${p.postalCode}';
      }
    } catch (e) {
      debugPrint('geocoding package failed, trying Google API fallback: $e');
    }

    // Stage 2: Fallback to Google Geocoding API if key is available
    if (GOOGLE_MAPS_API_KEY.isNotEmpty && ENABLE_GOOGLE_MAPS) {
      try {
        String host = 'https://maps.google.com/maps/api/geocode/json';
        final url =
            '$host?key=$GOOGLE_MAPS_API_KEY&language=en&latlng=$lat,$lng';
        var response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          Map data = jsonDecode(response.body);
          if (data["results"] != null && data["results"].isNotEmpty) {
            return data["results"][0]["formatted_address"];
          }
        }
      } catch (e) {
        debugPrint('Google API fallback also failed: $e');
      }
    }else{
        try {
          final url = Uri.https('nominatim.openstreetmap.org','/reverse',{
              'format': 'jsonv2',
              'lat': lat.toString(),
              'lon': lng.toString(),
              'zoom': '18',
              'addressdetails': '1',
              'accept-language': 'en',
            },
          );

    final response = await http.get(url,headers: {'User-Agent': 'GTInfiniti/1.0',},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data =
          jsonDecode(response.body);

      final address = data['display_name'];

      if (address != null &&
          address.toString().trim().isNotEmpty) {
        return address.toString();
      }
    } else {
      debugPrint(
          'OSM API failed: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('OSM reverse geocoding failed: $e');
  }

    }

    return "Location Not Captured";
  }

  
}
