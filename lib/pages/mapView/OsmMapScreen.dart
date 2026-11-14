import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:get/get.dart';

import 'package:gtlmd/base/BaseRepository.dart';
import 'package:gtlmd/common/Colors.dart';
import 'package:gtlmd/common/Toast.dart';
import 'package:gtlmd/common/Utils.dart';
import 'package:gtlmd/common/alertBox/loadingAlertWithCancel.dart';
import 'package:gtlmd/pages/home/Model/allotedRouteModel.dart';
import 'package:gtlmd/pages/mapView/mapRouteViewModel.dart';
import 'package:gtlmd/pages/mapView/models/mapConfigJsonModel.dart';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'dart:ui' as ui;
import 'package:gtlmd/pages/mapView/models/MapRouteModel.dart';

class OsmMapScreen extends StatefulWidget {
  final dynamic model;
  const OsmMapScreen({super.key, this.model});

  @override
  State<OsmMapScreen> createState() => _OsmMapScreenState();
}

class _OsmMapScreenState extends State<OsmMapScreen> {
  late LoadingAlertService loadingAlertService;
  List<MapRouteModel> _routeDetailList = List.empty(growable: true);
  dynamic _routeDetail;
  AllotedRouteModel routeHeaderDetails = AllotedRouteModel();
  BaseRepository _baseRepo = BaseRepository();
  MapRouteViewModel viewModel = MapRouteViewModel();
  Location _locationController = Location();
  // final Completer<GoogleMapController> _mapController =
  //     Completer<GoogleMapController>();

  LatLng? _currentLocation;
  double _zoom = 13.0;
  double _tilt = 0;
  double _bearing = 0;
  // List<LatLng> locations = List.empty(growable: true);
  // Set<Marker> markers = Set();
  // Set<Polyline> polylines = {}; // Changed to Set<Polyline>
  List<LatLng> locations = <LatLng>[];

  List<Marker> markers = <Marker>[];

  List<Polyline> polylines = <Polyline>[];

  TravelMode selectedMode = TravelMode.driving;
  MapConfigJsonModel? mapconfig = MapConfigJsonModel();

  final List<TravelMode> travelModes = [
    TravelMode.driving,
    TravelMode.walking,
    TravelMode.bicycling,
    TravelMode.transit
  ];

  // static const LatLng pickup = LatLng(28.6139, 77.2090);
  // static const LatLng destination = LatLng(28.4595, 77.0266);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => loadingAlertService = LoadingAlertService(context: context));
    _routeDetail = widget.model;
    setObservers();

    getRouteDetails();
    getMapConfig();
  }

  setObservers() {
    viewModel.mapRouteLiveData.stream.listen((resp) {
      if (resp.elementAt(0).commandstatus == 1) {
        setState(()  {
          _routeDetailList = resp;
          fetchDistanceFromApi(_routeDetailList);
           getConsignmentLocation();
          _createPolylines(); // Call this after locations are fetched
        });
      }
    });
    viewModel.routeDetailLiveData.stream.listen((resp) {
      if (resp.commandstatus == 1) {
        setState((){
          routeHeaderDetails = resp;
        });
      }
    });

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
      // "prmplanningid": "772",
      "prmsessionid": savedUser.sessionid.toString(),
    };

    printParams(params);
    // viewModel.getMapConfig(params);
    _baseRepo.getMapConfig(params);
  }

  // @override
  // void dispose() {
  //   // _timer?.cancel();
  //   super.dispose();
  // }

  void getRouteDetails() {
    // failToast('data not found');
    Map<String, String> params = {
      "prmcompanyid": savedLogin.companyid.toString(),
      "prmusercode": savedUser.usercode.toString(),
      "prmbranchcode": savedUser.password.toString(),
      "prmplanningid": _routeDetail.planningid.toString(),
      // "prmplanningid":"772",
      "prmsessionid": savedUser.sessionid.toString(),
    };

    printParams(params);
    viewModel.getMapRouteDetails(params);
  }

  Future<void> _createPolylines() async {
    if (locations.length < 2) {
      debugPrint('At least two locations are required for routing.');
      return;
    }

    try {
      // OSRM requires longitude,latitude order.
      final coordinates = locations
          .map((point) => '${point.longitude},${point.latitude}')
          .join(';');

      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '$coordinates?overview=full&geometries=geojson&steps=true',
      );

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        debugPrint('OSRM error: ${response.statusCode}');
        debugPrint(response.body);
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['code'] != 'Ok') {
        debugPrint('OSRM route failed: ${data['code']}');
        return;
      }

      final routes = data['routes'] as List<dynamic>;

      if (routes.isEmpty) {
        debugPrint('No route found.');
        return;
      }

      final route = routes.first as Map<String, dynamic>;

      final geometry = route['geometry'] as Map<String, dynamic>;

      final coordinatesList = geometry['coordinates'] as List<dynamic>;

      final routePoints = coordinatesList.map((coordinate) {
        final point = coordinate as List<dynamic>;

        // GeoJSON coordinates are [longitude, latitude].
        return LatLng(
          (point[1] as num).toDouble(),
          (point[0] as num).toDouble(),
        );
      }).toList();

      // OSRM returns distance in metres.
      final distanceMeters = (route['distance'] as num).toDouble();
      final distanceKm = distanceMeters / 1000.0;

      if (!mounted) return;

      setState(() {
        polylines = [
          Polyline(
            points: routePoints,
            color: Colors.blue,
            strokeWidth: 5,
          ),
        ];

        routeHeaderDetails.totdistance = distanceKm.toStringAsFixed(2);
      });

      debugPrint('OSRM distance: $distanceKm km');
    } catch (e, stackTrace) {
      debugPrint('Error fetching OSRM route: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  fetchDistanceFromApi(List<MapRouteModel> routeDetail) async {
    // double totalDistance = await fetchTotalRouteDistance(routeDetail);
    List<int> totalDistanceList =
        await fetchTotalRouteDistanceWithOSM(routeDetail, mapconfig!);
    double totalDistance = totalDistanceList[0]
        .toDouble(); // because total distance will be at index 0
    routeHeaderDetails.totdistance = totalDistance.toString();
  }

  Future<void> getConsignmentLocation() async {
    debugPrint('Route details length: ${_routeDetailList.length}');

    final Map<String, List<int>> locationIndexMap = {};
    final Map<String, List<String>> markerTextMap = {};

    // Clear markers before rebuilding them.
    final List<Marker> newMarkers = [];

    for (int i = 0; i < _routeDetailList.length; i++) {
      final item = _routeDetailList[i];
      final lat = item.deliverylat;
      final lng = item.deliverylong;
      final grno = item.grno ?? '';

      if (lat == null || lng == null) continue;

      // Avoid invalid coordinates.
      if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
        debugPrint('Invalid coordinates: $lat, $lng');
        continue;
      }

      final key = '$lat,$lng';

      final String markerText;
      if (grno.contains('Pickup')) {
        markerText = 'P';
      } else if (grno.contains('Final')) {
        markerText = 'D';
      } else {
        markerText = '$i';
      }

      locationIndexMap.putIfAbsent(key, () => []).add(i);
      markerTextMap.putIfAbsent(key, () => []).add(markerText);
    }

    for (final entry in locationIndexMap.entries) {
      final parts = entry.key.split(',');
      final lat = double.parse(parts[0]);
      final lng = double.parse(parts[1]);

      final markerText = markerTextMap[entry.key]!.join(',');

      newMarkers.add(
        Marker(
          point: LatLng(lat, lng),
          width: 100,
          height: 50,
          alignment: Alignment.topCenter,
          child: _buildCustomMarker(markerText),
        ),
      );

      debugPrint('Added marker: $markerText at $lat, $lng');
    }

    // Update the marker list only after building all markers.
    if (!mounted) return;

    setState(() {
      markers = newMarkers;
    });

    getLocations();

    debugPrint('Markers count: ${markers.length}');
    debugPrint('Locations count: ${locations.length}');
  }

// Future<List<int>> fetchTotalRouteDistance(
//   List<dynamic> routeDetail,
//   MapConfigJsonModel mapconfig,
// ) async {
//   final List<int> updatedDistances = [];

//   // At least two locations are required.
//   if (routeDetail.length < 2) {
//     debugPrint('At least two route locations are required.');
//     return [];
//   }

//   try {
//     // OSRM requires coordinates in longitude,latitude order.
//     final List<String> coordinates = [];

//     for (final item in routeDetail) {
//       final lat = item.deliverylat;
//       final lng = item.deliverylong;

//       if (lat == null || lng == null) {
//         debugPrint('A route location has missing coordinates.');
//         return [];
//       }

//       coordinates.add('$lng,$lat');
//     }

//     final url = Uri.parse(
//   'https://router.project-osrm.org/route/v1/driving/'
//   '${coordinates.join(';')}?overview=full&geometries=geojson&steps=true',
// );
//     final response = await http.get(url);

//     if (response.statusCode != 200) {
//       debugPrint('OSRM HTTP error: ${response.statusCode}');
//       debugPrint(response.body);
//       return [];
//     }

//     final data = json.decode(response.body);

//     if (data['code'] != 'Ok' ||
//         data['routes'] == null ||
//         (data['routes'] as List).isEmpty) {
//       debugPrint('OSRM route error: ${data['code']}');
//       return [];
//     }

//     final route = data['routes'][0];

//     // Total distance in meters.
//     final int totalDistanceInMeters =
//         (route['distance'] as num).round();

//     // Individual leg distances in meters.
//     for (final leg in route['legs']) {
//       updatedDistances.add(
//         (leg['distance'] as num).round(),
//       );
//     }

//     // Preserve the existing return structure.
//     updatedDistances.insert(0, totalDistanceInMeters);

//     debugPrint(
//       'Total route distance: $totalDistanceInMeters meters',
//     );

//     return updatedDistances;
//   } catch (e) {
//     debugPrint('Error calculating route distance: $e');
//     return [];
//   }
// }

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
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: markers.isNotEmpty
                              ? markers.first.point
                              : locations.first,
                          initialZoom: 13,
                        ),
                        children: [
                          // OpenStreetMap tiles
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.greensoft.gtinfiniti',
                          ),

                          // Draw the route between consignment locations
                          if (polylines.isNotEmpty)
                            PolylineLayer(
                              polylines: polylines,
                            ),

                          // Display all consignment markers
                          MarkerLayer(
                            markers: markers,
                          ),

                          // OpenStreetMap attribution
                          const RichAttributionWidget(
                            attributions: [
                              TextSourceAttribution(
                                '© OpenStreetMap contributors',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

Widget _buildCustomMarker(String markerText) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 80,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
        ),
        child: Text(
          markerText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      CustomPaint(
        size: const ui.Size(16, 8),
        painter: _MarkerTrianglePainter(),
      ),
    ],
  );
}

class _MarkerTrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, ui.Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final ui.Path path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
