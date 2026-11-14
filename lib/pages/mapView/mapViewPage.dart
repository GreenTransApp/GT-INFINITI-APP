import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gtlmd/base/BaseRepository.dart';
import 'package:gtlmd/common/Toast.dart';
import 'package:gtlmd/common/Utils.dart';
import 'package:gtlmd/common/alertBox/loadingAlertWithCancel.dart';
import 'package:gtlmd/common/Colors.dart';
import 'package:gtlmd/pages/home/Model/allotedRouteModel.dart';
import 'package:gtlmd/pages/mapView/mapRouteViewModel.dart';
import 'package:gtlmd/pages/mapView/models/mapConfigDetailModel.dart';
import 'package:gtlmd/pages/mapView/models/mapConfigJsonModel.dart';

import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:ui' as ui;

import 'models/MapRouteModel.dart';

class MapViewPage extends StatefulWidget {
  final dynamic model;
  // final List<RouteDetailModel> routeDetailList;
  MapViewPage({
    super.key,
    // required this.routeDetailList,
    required this.model,
  });

  @override
  State<MapViewPage> createState() => _MapViewPageState();
}

class _MapViewPageState extends State<MapViewPage> {
  late LoadingAlertService loadingAlertService;

  // List<RouteDetailModel> _routeDetailList = List.empty(growable: true);
  List<MapRouteModel> _routeDetailList = List.empty(growable: true);
  // AllotedRouteModel _routeDetail = AllotedRouteModel();
  dynamic _routeDetail;
  AllotedRouteModel routeHeaderDetails = AllotedRouteModel();
  BaseRepository _baseRepo = BaseRepository();
  MapRouteViewModel viewModel = MapRouteViewModel();
  Location _locationController = Location();
  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();
  LatLng? _currentLocation;
  double _zoom = 13.0;
  double _tilt = 0;
  double _bearing = 0;
  List<LatLng> locations = List.empty(growable: true);
  Set<Marker> markers = Set();
  Set<Polyline> polylines = {}; // Changed to Set<Polyline>
  TravelMode selectedMode = TravelMode.driving;
  MapConfigJsonModel? mapconfig = MapConfigJsonModel();

  final List<TravelMode> travelModes = [
    TravelMode.driving,
    TravelMode.walking,
    TravelMode.bicycling,
    TravelMode.transit
  ];

  @override
  void initState() {
    super.initState();
    // getLocationUpdates();
    // _routeDetailList = widget.routeDetailList;
    _routeDetail = widget.model;
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => loadingAlertService = LoadingAlertService(context: context));
    setObservers();
    _getGoogleMapApiKey();
    getRouteDetails();
    getMapConfig();
  }

  setObservers() {
    _baseRepo.accResp.stream.listen((resp) async {
      if (isNullOrEmpty(resp)) {
        failToast("Unable To Fetch Google Map Api key, please Try Again.");
      } else {
        GOOGLE_MAPS_API_KEY = resp;
      }
    });
    viewModel.mapRouteLiveData.stream.listen((resp) {
      if (resp.elementAt(0).commandstatus == 1) {
        setState(() async {
          _routeDetailList = resp;
          fetchDistanceFromGoogleApi(_routeDetailList);
          await getConsignmentLocation();
          _createPolylines(); // Call this after locations are fetched
        });
      }
    });
    viewModel.routeDetailLiveData.stream.listen((resp) {
      if (resp.commandstatus == 1) {
        setState(() async {
          routeHeaderDetails = resp;
        });
      }
    });
    // viewModel.mapConfigDetailLiveData.stream.listen((resp) {
    //   if (resp.commandStatus == 1) {
    //     setState(() async {
    //       mapconfig = resp.mapConfigData;
    //     });
    //   }
    // });

    _baseRepo.mapConfigDetail.stream.listen((resp) {
      if (resp.commandStatus == 1) {
        // Handle map config detail response
        debugPrint("Map Config Detail: ${resp.mapConfigData}");
        mapconfig = resp.mapConfigData ?? MapConfigJsonModel();
      } else {
        failToast(resp.commandMessage ?? "Failed to fetch map config details");
      }
    });
  }

  getMapConfig() {
    Map<String, String> params = {
      "prmcompanyid": savedLogin.companyid.toString(),
      "prmusercode": savedUser.usercode.toString(),
      "prmbranchcode": savedUser.loginbranchcode.toString(),
      "prmplanningid": _routeDetail.planningid.toString(),
      "prmsessionid": savedUser.sessionid.toString(),
    };

    printParams(params);
    // viewModel.getMapConfig(params);
    _baseRepo.getMapConfig(params);
  }

  @override
  void dispose() {
    // _timer?.cancel();
    super.dispose();
  }

  void getRouteDetails() {
    // failToast('data not found');
    Map<String, String> params = {
      "prmcompanyid": savedLogin.companyid.toString(),
      "prmusercode": savedUser.usercode.toString(),
      "prmbranchcode": savedUser.password.toString(),
      "prmplanningid": _routeDetail.planningid.toString(),
      "prmsessionid": savedUser.sessionid.toString(),
    };

    printParams(params);
    viewModel.getMapRouteDetails(params);
  }

  _getGoogleMapApiKey() {
    Map<String, String> params = {
      "keyNo": "73",
      "prmcompanyid": savedLogin.companyid.toString(),
    };

    printParams(params);
    _baseRepo.getValueFromAccPara(params);
  }

  // Removed getPolylinesPoints and generatePolylineFromPoints as we will create segments directly

  Future<void> _cameraToPosition(LatLng pos) async {
    final GoogleMapController controller = await _mapController.future;
    CameraPosition _newCameraPosition = CameraPosition(
      target: pos,
      zoom: _zoom,
      tilt: _tilt,
      bearing: _bearing,
    );
    await controller
        .animateCamera(CameraUpdate.newCameraPosition(_newCameraPosition));
  }

  // checks if lcoation service is enabled and if service is not enabled, it enables it
  // checks if app has permission to access current location, if not requests permission
  // onLocationChanged method gives us live update about users currnet location and here we update the map camera to users current location.
  Future<void> getLocationUpdates() async {
    bool _serviceEnabled = await _locationController.serviceEnabled();

    _serviceEnabled = await _locationController.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _locationController.requestService();

      if (!_serviceEnabled) {
        // Show dialog to force user to enable location
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("GPS Disabled"),
            content: const Text("Please enable GPS to get your location."),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await Geolocator.openLocationSettings();
                  await getLocationUpdates(); // Re-try
                },
                child: const Text("Open Settings"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Cancel"),
              ),
            ],
          ),
        );
        return;
      }
    }

    // Check permission
    PermissionStatus _permissionGranted =
        await _locationController.hasPermission();

    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _locationController.requestPermission();
    }

    if (_permissionGranted == PermissionStatus.deniedForever) {
      // Guide user to app settings if denied forever
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Location Permission Required"),
          content:
              const Text("Please grant location access from app settings."),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await Geolocator.openAppSettings();
                await getLocationUpdates(); // Re-try
              },
              child: const Text("Open Settings"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
          ],
        ),
      );
      return;
    }

    if (_permissionGranted != PermissionStatus.granted) {
      return;
    }

    // Start listening to location
    _locationController.onLocationChanged.listen((location) {
      if (location.latitude != null && location.longitude != null) {
        setState(() {
          _currentLocation = LatLng(location.latitude!, location.longitude!);
          markers.add(
            Marker(
              markerId: const MarkerId("currentLocation"),
              position: _currentLocation!,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen),
              infoWindow: const InfoWindow(title: "Current Location"),
            ),
          );
          _cameraToPosition(_currentLocation!);
          _createPolylines();
        });
      }
    });
  }

  Future<BitmapDescriptor> _createCustomMarkerBitmap(String markerText) async {
    const double width = 200;
    const double height = 80;
    const double borderRadius = 12;
    const double triangleHeight = 15;

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    final Paint backgroundPaint = Paint()..color = Colors.blue;
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final RRect rRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, width, height),
      Radius.circular(borderRadius),
    );

    // Draw main rounded rectangle background
    canvas.drawRRect(rRect, backgroundPaint);

    // Optional: draw border
    canvas.drawRRect(rRect, borderPaint);

    // Draw the triangle pointer (like a speech bubble tail)
    final Path trianglePath = Path();
    trianglePath.moveTo(width / 2 - 10, height);
    trianglePath.lineTo(width / 2 + 10, height);
    trianglePath.lineTo(width / 2, height + triangleHeight);
    trianglePath.close();

    canvas.drawPath(trianglePath, backgroundPaint);
    canvas.drawPath(trianglePath, borderPaint);

    // Draw text
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      maxLines: 1,
      textAlign: TextAlign.center,
    );

    textPainter.text = TextSpan(
      text: markerText,
      style: const TextStyle(
        fontSize: 28,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );

    textPainter.layout(minWidth: 0, maxWidth: width - 20);
    textPainter.paint(
      canvas,
      Offset(
        (width - textPainter.width) / 2,
        (height - textPainter.height) / 2 - 5,
      ),
    );

    // Convert canvas to image
    final ui.Image markerAsImage = await pictureRecorder
        .endRecording()
        .toImage(width.toInt(), (height + triangleHeight).toInt());

    final ByteData? byteData =
        await markerAsImage.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(uint8List);
  }

  // extracts and stores latitude and longitutde of all the consignments fom _routeDetailList

  getLocations() {
    for (var i = 0; i < _routeDetailList.length; i++) {
      if (_routeDetailList[i].deliverylat != null &&
          _routeDetailList[i].deliverylong != null) {
        if (i + 1 < _routeDetailList.length &&
            _routeDetailList[i].deliverylat ==
                _routeDetailList[i + 1].deliverylat &&
            _routeDetailList[i].deliverylong ==
                _routeDetailList[i + 1].deliverylong) {
          continue;
        }

        LatLng newLocation = LatLng(_routeDetailList[i].deliverylat!,
            _routeDetailList[i].deliverylong!);
        locations.add(newLocation);
      }
    }

    setState(() {});
  }

/* 
  getConsignmentLocation() async {
    debugPrint("Route details length: ${_routeDetailList.length}");
    String markerText = "";
    String pickUpMarkerText = "";
    for (var i = 0; i < _routeDetailList.length; i++) {
      if (_routeDetailList[i].deliverylat != null &&
          _routeDetailList[i].deliverylong != null) {
        if (_routeDetailList[i].grno!.contains('Pickup')) {
          markerText += "P";
        } else if (_routeDetailList[i].grno!.contains('Final')) {
          markerText += "D";
        } else {
          markerText += "$i";
        }

        if (i + 1 < _routeDetailList.length &&
            _routeDetailList[i].deliverylat ==
                _routeDetailList[i + 1].deliverylat &&
            _routeDetailList[i].deliverylong ==
                _routeDetailList[i + 1].deliverylong) {
          markerText += ",";
          continue;
        }

        debugPrint(
            "Location: ${_routeDetailList[i].deliverylat} ${_routeDetailList[i].deliverylong}");

        if (i == _routeDetailList.length - 1 &&
            _routeDetailList[0].deliverylat ==
                _routeDetailList[_routeDetailList.length - 1].deliverylat &&
            _routeDetailList[0].deliverylong ==
                _routeDetailList[_routeDetailList.length - 1].deliverylong) {
          markerText = "$pickUpMarkerText,$markerText";
        }
        final markerIcon = await _createCustomMarkerBitmap(markerText);
        LatLng newLocation = LatLng(_routeDetailList[i].deliverylat!,
            _routeDetailList[i].deliverylong!);

        if (locations.isEmpty) {
          pickUpMarkerText = markerText;
        }
        // if (!locations.contains(newLocation)) {
        locations.add(newLocation);
        String markerId = "position$i";

        markers.add(Marker(
            markerId: MarkerId(markerId),
            position: newLocation,
            infoWindow: InfoWindow(
                title: _routeDetailList[i].grno!.contains('Pickup') ||
                        _routeDetailList[i].grno!.contains('Final')
                    ? "Address: ${_routeDetailList[i].address}"
                    : "Cnge Name: ${_routeDetailList[i].cnge.toString()}",
                snippet: !_routeDetailList[i].grno!.contains('Pickup') &&
                        !_routeDetailList[i].grno!.contains('Final')
                    ? "Address: ${_routeDetailList[i].address}"
                    : ""),
            icon: markerIcon));
        debugPrint("New location and route added");
        // }
      }
      markerText = "";
    }

    setState(() {
      debugPrint("Markers list len: ${markers.length}");
      debugPrint("Location list len: ${locations.length}");
    });
    debugPrint(
        'Updated locations: ${locations.map((e) => '${e.latitude}, ${e.longitude}').toList()}');
  }

 */

  getConsignmentLocation() async {
    debugPrint("Route details length: ${_routeDetailList.length}");

    Map<String, List<int>> locationIndexMap = {};
    Map<String, List<String>> markerTextMap = {};

    // Step 1: Group route entries by lat/lng string key
    for (int i = 0; i < _routeDetailList.length; i++) {
      final lat = _routeDetailList[i].deliverylat;
      final lng = _routeDetailList[i].deliverylong;

      if (lat != null && lng != null) {
        final key = "$lat,$lng";

        // Marker text logic
        String markerText;
        if (_routeDetailList[i].grno!.contains('Pickup')) {
          markerText = "P";
        } else if (_routeDetailList[i].grno!.contains('Final')) {
          markerText = "D";
        } else {
          markerText = "$i";
        }

        locationIndexMap.putIfAbsent(key, () => []).add(i);
        markerTextMap.putIfAbsent(key, () => []).add(markerText);
      }
    }

    // Set<String> processedKeys = {};

    for (var entry in locationIndexMap.entries) {
      final key = entry.key;
      final indices = entry.value;

      // if (processedKeys.contains(key)) continue;
      // processedKeys.add(key);

      final latLngParts = key.split(',');
      final lat = double.parse(latLngParts[0]);
      final lng = double.parse(latLngParts[1]);

      final markerText = markerTextMap[key]!.join(',');

      final markerIcon = await _createCustomMarkerBitmap(markerText);
      LatLng newLocation = LatLng(lat, lng);
      // locations.add(newLocation);

      int representativeIndex =
          indices.first; // You can customize how to pick this
      final routeEntry = _routeDetailList[representativeIndex];

      String title = routeEntry.grno!.contains('Pickup') ||
              routeEntry.grno!.contains('Final')
          ? "Address: ${routeEntry.address}"
          : "Cnge Name: ${routeEntry.cnge.toString()}";

      String snippet = !routeEntry.grno!.contains('Pickup') &&
              !routeEntry.grno!.contains('Final')
          ? "Address: ${routeEntry.address}"
          : "";

      markers.add(Marker(
        markerId: MarkerId("position$key"),
        position: newLocation,
        infoWindow: InfoWindow(title: title, snippet: snippet),
        icon: markerIcon,
      ));

      debugPrint("Added marker for $key with text $markerText");
    }

    getLocations();

    setState(() {
      debugPrint("Markers list len: ${markers.length}");
      debugPrint("Location list len: ${locations.length}");
    });

    debugPrint(
        'Updated locations: ${locations.map((e) => '${e.latitude}, ${e.longitude}').toList()}');
  }

  Future<Map<String, dynamic>> getDirections(
      String origin, String destination, String apiKey) async {
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&mode=$selectedMode&key=$GOOGLE_MAPS_API_KEY';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load directions');
    }
  }

  List<LatLng> decodePolyline(String encoded) {
    List<LatLng> polylineCoordinates = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      polylineCoordinates.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return polylineCoordinates;
  }
/* 
  Future<void> _createPolylines() async {
    List<LatLng> allPoints = [...locations];
    Set<Polyline> tempPolylines = {};
    List<LatLng> waypoints = allPoints.sublist(1, allPoints.length - 1);
    String waypointsstring =
        waypoints.map((e) => '${e.latitude},${e.longitude}').join('|');

    String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${allPoints[0].latitude},${allPoints[0].longitude}&destination=${allPoints[allPoints.length - 1].latitude},${allPoints[allPoints.length - 1].longitude}&waypoints=$waypointsstring&mode=$selectedMode&key=$GOOGLE_MAPS_API_KEY&waypoints=optimize:true|$waypointsstring&avoid=highways';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if ((data['routes'] as List).isNotEmpty) {
        final route = data['routes'][0];

        List<LatLng> polylineCoordinates = [];

        // Parse each step in each leg for accurate path
        for (var leg in route['legs']) {
          for (var step in leg['steps']) {
            final encoded = step['polyline']['points'];
            polylineCoordinates.addAll(_decodePolyline(encoded));
          }
        }

        final polyline = Polyline(
          polylineId: PolylineId('route'),
          color: Colors.blue,
          width: 5,
          points: polylineCoordinates,
        );

        setState(() {
          polylines.clear();
          polylines.add(polyline);
        });
      } else {
        debugPrint("No routes found.");
      }
    } else {
      debugPrint("Failed to fetch directions: ${response.body}");
    }
  }

 */

  Future<void> _createPolylines() async {
    List<LatLng> allPoints = [...locations];
    List<LatLng> waypoints = allPoints.sublist(1, allPoints.length - 1);

    final url =
        Uri.parse('https://routes.googleapis.com/directions/v2:computeRoutes');
    // final response = await http.get(Uri.parse(url));
    String accessToken = GOOGLE_MAPS_API_KEY;

    final headers = {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': accessToken,
      'X-Goog-FieldMask':
          '*', // Use field mask to specify which parts of the response you want
    };

    final body = {
      "origin": {
        "location": {
          "latLng": {
            "latitude": allPoints[0].latitude,
            "longitude": allPoints[0].longitude
          }
        }
      },
      "destination": {
        "location": {
          "latLng": {
            "latitude": allPoints[allPoints.length - 1].latitude,
            "longitude": allPoints[allPoints.length - 1].longitude
          }
        }
      },
      "intermediates": List.generate(
        waypoints.length,
        (index) => {
          "location": {
            "latLng": {
              "latitude": waypoints[index].latitude,
              "longitude": waypoints[index].longitude
            }
          }
        },
      ),
      "routeModifiers": {
        "avoidTolls": mapconfig!.avoidtolls == 'Y',
        "avoidHighways": mapconfig!.avoidhighways == 'Y',
        "avoidFerries": mapconfig!.avoidferries == 'Y'
      },
      "routingPreference": mapconfig!.trafficmode!.toString().toUpperCase(),
      "travelMode": mapconfig!.travelmode!.toUpperCase(),
      "computeAlternativeRoutes": mapconfig!.alternativeroutes == 'Y',
      // "polylineQuality": "HIGH_QUALITY",
      // "units": "METRIC"
    };

    final response =
        await http.post(url, headers: headers, body: jsonEncode(body));
    try {
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if ((data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];

          List<LatLng> polylineCoordinates = [];

          // Parse each step in each leg for accurate path
          for (var leg in route['legs']) {
            for (var step in leg['steps']) {
              final encoded = step['polyline']['encodedPolyline'];
              polylineCoordinates.addAll(_decodePolyline(encoded));
            }
          }

          final polyline = Polyline(
            polylineId: PolylineId('route'),
            color: Colors.blue,
            width: 5,
            points: polylineCoordinates,
          );

          setState(() {
            polylines.clear();
            polylines.add(polyline);
          });
        } else {
          debugPrint("No routes found.");
        }
      } else {
        debugPrint("Failed to fetch directions: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error while fetching directions: $e");
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return polyline;
  }

  fetchDistanceFromGoogleApi(List<MapRouteModel> routeDetail) async {
    // double totalDistance = await fetchTotalRouteDistance(routeDetail);
    List<int> totalDistanceList =
        await fetchTotalRouteDistance(routeDetail, mapconfig!);
    double totalDistance = totalDistanceList[0]
        as double; // because total distance will be at index 0
    routeHeaderDetails.totdistance = totalDistance.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: CommonColors.colorPrimary,
          title: Text(
            'Map View',
            style: TextStyle(color: CommonColors.White),
          ),
          leading: IconButton(
              onPressed: () {
                Get.back();
              },
              icon: Icon(
                Icons.arrow_back,
                color: CommonColors.White,
              )),
        ),
        body: _routeDetail == null
            ? Scaffold(
                body: Center(
                child: Text(
                  "data not  found ".toUpperCase(),
                  style:
                      TextStyle(color: CommonColors.successColor, fontSize: 20),
                ),
              ))
            : locations.isEmpty
                ? const Center(
                    child: Text(
                      'Loading...',
                      style: TextStyle(
                          color: CommonColors.appBarColor, fontSize: 18),
                    ),
                  )
                : Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 140,
                                  child: Text(
                                    "Zone",
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Text(
                                  ': ',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    "${routeHeaderDetails.routename}",
                                    style: TextStyle(
                                      color: CommonColors.colorPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 140,
                                  child: Text(
                                    "Total Consignment",
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Text(
                                  ': ',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    "${routeHeaderDetails.noofconsign.toString()}",
                                    style: TextStyle(
                                      color: CommonColors.colorPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 140,
                                  child: Text(
                                    "Total Distance",
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Text(
                                  ': ',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    "${routeHeaderDetails.totdistance.toString()}",
                                    style: TextStyle(
                                      color: CommonColors.colorPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 140,
                                  child: Text(
                                    "Total Weight",
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Text(
                                  ': ',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    "${routeHeaderDetails.totweight.toString()}",
                                    style: TextStyle(
                                      color: CommonColors.colorPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: GoogleMap(
                          onMapCreated: ((GoogleMapController controller) =>
                              _mapController.complete(controller)),
                          initialCameraPosition: CameraPosition(
                            target: /* _currentLocation ?? */
                                locations
                                    .first, // Use first location if current is null initially
                            zoom: _zoom,
                            tilt: _tilt,
                            bearing: _bearing,
                          ),
                          markers: markers,
                          polylines: polylines, // Use the Set<Polyline> here
                          onCameraMove: (position) => {
                            _zoom = position.zoom,
                            _tilt = position.tilt,
                            _bearing = position.bearing
                          },
                        ),
                      ),
                    ],
                  ));
  }
}
