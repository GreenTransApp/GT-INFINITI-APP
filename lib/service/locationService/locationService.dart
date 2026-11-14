import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gtlmd/common/Utils.dart';
import 'package:gtlmd/firebase_options.dart';
import 'package:gtlmd/pages/login/models/userModel.dart';
import 'package:gtlmd/pages/trips/tripDetail/Model/tripModel.dart';
import 'package:gtlmd/service/fireBaseService/fireBase.dart';
import 'package:gtlmd/service/fireBaseService/firebaseLocationUpload.dart';
import 'package:gtlmd/service/locationService/locationRepository.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamSubscription<Position>? _position;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initialize foreground task and notifications
  Future<void> init() async {
    await _initNotifications();

    debugPrint('Location Interval $locationUpdateInterval');
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'location_channel',
        channelName: 'Live Location Service',
        channelDescription: 'Tracking user location in foreground',
        channelImportance: NotificationChannelImportance.HIGH,
        priority: NotificationPriority.HIGH,
      ),
      iosNotificationOptions:
          const IOSNotificationOptions(showNotification: true),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(locationUpdateInterval),
        // eventAction: ForegroundTaskEventAction.repeat(30000),
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  /// Initialize local notifications
  Future<void> _initNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _notificationsPlugin.initialize(settings);
  }

  /// Request notification & location permissions
  Future<void> requestPermissions() async {
    await requestAppPermission(Permission.notification);

    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.whileInUse) {
      permission = await Geolocator.requestPermission(); // allow "Always"
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return;
    }

    // await Geolocator.getCurrentPosition(
    //   locationSettings: AppleSettings(
    //     accuracy: LocationAccuracy.best,
    //     distanceFilter: 0,
    //     pauseLocationUpdatesAutomatically: false,
    //   ),
    // );

    print('Location permission granted');
  }

  Future<Position> getCurrentLocation() async {
  await requestPermissions();

  return await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.medium,
    ),
  );
}

  /// Show iOS specific notification
  Future<void> _showIosTrackingNotification() async {
    if (!Platform.isIOS) return;
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
    );
    const notificationDetails = NotificationDetails(iOS: iosDetails);
    await _notificationsPlugin.show(
      0,
      'Location Tracking Active',
      'Your location is being tracked for trips.',
      notificationDetails,
    );
  }

  /// Start the foreground service
  Future<void> startService(
      List<TripModel> activeTripList, UserModel userdata) async {
    if (kDebugMode) {
      print('Debug mode: Location service tracking disabled to prevent hang');
      return;
    }

    if (activeTripList.isEmpty) {
      print('No trips → service not started');
      return;
    }

    await requestPermissions();

    final tripList =
        activeTripList.map((trip) => trip.tripid.toString()).toList();
    final dataToPass = {'tripList': tripList, 'userData': userdata.toJson()};

    if (!await FlutterForegroundTask.isRunningService) {
      print('Starting foreground service');
      await FlutterForegroundTask.startService(
        notificationTitle: 'Location Tracking Active',
        notificationText: 'Your location is being tracked.',
        callback: startCallback,
      );

      await _showIosTrackingNotification();

      // Give isolate a short delay to initialize
      Future.delayed(const Duration(milliseconds: 500), () {
        FlutterForegroundTask.sendDataToTask(dataToPass);
      });
    } else {
      print('Service already running → updating trip list');
      FlutterForegroundTask.sendDataToTask(dataToPass);
    }
  }

  /// Stop the foreground service
  Future<void> stopService() async {
    if (Platform.isIOS) await _notificationsPlugin.cancel(0);
    if (await FlutterForegroundTask.isRunningService) {
      await _position?.cancel();
      _position = null;
      await FlutterForegroundTask.stopService();
      print("Foreground service stopped");
    } else {
      print("No foreground service running");
    }
  }
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(LocationTaskHandler());
}

@pragma('vm:entry-point')
class LocationTaskHandler extends TaskHandler {
  StreamSubscription<Position>? _positionStream;
  final LocationRepository _repo = LocationRepository();

  List<String> tripList = [];
  UserModel? userData;
  bool _dataReceived = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print('[ForegroundTask] onStart');

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
      print('Firebase initialized in foreground task.');
    }

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
    );

    _positionStream = Geolocator.getPositionStream(
            locationSettings: locationSettings)
        .listen((position) => print(
            '[ForegroundTask] Location: ${position.latitude}, ${position.longitude}'));
  }

  @override
  void onReceiveData(Object data) {
    if (data is Map) {
      try {
        if (data['tripList'] is List) {
          final newTripList = List<String>.from(data['tripList']);
          if (!listEquals(tripList, newTripList)) {
            tripList = newTripList;
            print('[ForegroundTask] Updated tripList: $tripList');
          }
        }
        if (data['userData'] != null) {
          userData =
              UserModel.fromJson(Map<String, dynamic>.from(data['userData']));
        }
        _dataReceived = true;
      } catch (e) {
        print('[ForegroundTask] Error parsing data: $e');
      }
    }
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    if (!_dataReceived || tripList.isEmpty || userData == null) {
      print('[ForegroundTask] No data to upload → skipping');
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        ),
      );
      final time = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      final firebaseData = FireBase(
        timeStamp: time,
        latitude: position.latitude.toString(),
        longitude: position.longitude.toString(),
        headingNorth: position.heading.toString(),
      );

      // await FirebaseLocationUpload()
      //     .saveToServer(userData!, tripList, firebaseData);
     _updateDriverLocation(userData!, tripList, firebaseData);

      print(
          '[ForegroundTask] Location uploaded: ${position.latitude}, ${position.longitude} → $tripList');
    } catch (e) {
      print('[ForegroundTask] Error uploading location: $e');
    }
  }

  void _updateDriverLocation(
      UserModel userData, List<String> trips, FireBase firebase) {
    final tripStr = trips.join(",") + ",";

    // Map<String, dynamic> params = {
    //   "prmcompanyid": userData.companyid.toString(),
    //   "prmusercode": userData.usercode.toString(),
    //   "prmbranchcode": userData.loginbranchcode.toString(),
    //   "prmboyid": userData.executiveid.toString(),
    //   "prmtripidstr": tripStr,
    //   "prmlatposition": firebase.latitude,
    //   "prmlongposition": firebase.longitude,
    //   "prmtimestamp": DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
    //   "prmheadingnorth": firebase.headingNorth,
    //   "prmsessionid": userData.sessionid.toString()
    // };

    final params = {
      "prmcompanyid": userData.companyid.toString(),
      "prmusercode": userData.usercode.toString(),
      "prmbranchcode": userData.loginbranchcode.toString(),
      "prmboyid": isNullOrEmpty(userData.executiveid.toString())?0:userData.executiveid.toString(),
      "prmtripidstr": tripStr,
      "prmlatitude": firebase.latitude,
      "prmlongitude": firebase.longitude,
      "prmsessionid": userData.sessionid.toString(),
      "prmtimestamp": DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      "prmdrivercode": userData.drivercode.toString(),
      "prmheadingnorth": firebase.headingNorth
    };
    _repo.upsertDriverLocation(params);
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isRetrying) async {
    await _positionStream?.cancel();
    _positionStream = null;
    print('[ForegroundTask] Destroyed. Retrying: $isRetrying');

    if (isRetrying) await FlutterForegroundTask.stopService();
  }


  
}
