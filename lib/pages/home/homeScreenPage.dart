import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:gtlmd/api/HttpCalls.dart';
import 'package:gtlmd/base/BaseRepository.dart';
import 'package:gtlmd/bottomSheet/NotificationOptionBottomSheet/notificationOptionBottomSheet.dart';
import 'package:gtlmd/bottomSheet/datePicker.dart';
import 'package:gtlmd/common/Environment.dart';
import 'package:gtlmd/common/Utils.dart';
import 'package:gtlmd/common/alertBox/commonAlertDialog.dart';
import 'package:gtlmd/common/alertBox/loadingAlertWithCancel.dart';
import 'package:gtlmd/common/colors.dart';
import 'package:gtlmd/common/commonModel/pageLinkJsonParams.dart';
import 'package:gtlmd/common/navDrawer/navDrawer.dart';
import 'package:gtlmd/common/toast.dart';
import 'package:gtlmd/design_system/size_config.dart';
import 'package:gtlmd/navigateRoutes/Routes.dart';
import 'package:gtlmd/navigateRoutes/RoutesName.dart';
import 'package:gtlmd/pages/attendance/attendanceScreen.dart';
import 'package:gtlmd/pages/attendance/models/attendanceModel.dart';
import 'package:gtlmd/pages/dashboard/userDashboard/userDashboardPage.dart';
import 'package:gtlmd/pages/home/Model/allotedRouteModel.dart';
import 'package:gtlmd/pages/home/Model/moduleModel.dart';
import 'package:gtlmd/pages/home/Model/notificationCountModel.dart';
import 'package:gtlmd/pages/home/homeViewModel.dart';
import 'package:gtlmd/pages/midmile/midMileTripList/midMileTripList.dart';
import 'package:gtlmd/pages/offlineView/dbHelper.dart';
import 'package:gtlmd/pages/offlineView/offlineDrsBottomSheet.dart';
import 'package:gtlmd/pages/orders/drsSelection/drsSelectionBottomSheet.dart';
import 'package:gtlmd/pages/routes/routesList/allotedRouteWidget.dart';
import 'package:gtlmd/pages/runningTrips/runningTrips.dart';
import 'package:gtlmd/pages/trips/tripDetail/Model/currentDeliveryModel.dart';
import 'package:gtlmd/pages/trips/tripDetail/Model/tripModel.dart';
import 'package:gtlmd/pages/updateVersionScreen/updateVersionScreen.dart';
import 'package:gtlmd/service/locationService/locationService.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:url_launcher/url_launcher.dart';

enum DashboardTabs { ALLOTEDROUTES, CURRENTDELIVERY }

class HomeScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomeScreen();
}

class _HomeScreen extends State<HomeScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  String fromDt = "";
  String toDt = "";
  String viewFromDt = "";
  String viewToDt = "";
  late DateTime todayDateTime;
  late String smallDateTime;
  late LoadingAlertService loadingAlertService;
  final HomeViewModel viewModel = HomeViewModel();
  List<AllotedRouteModel> routeList = List.empty(growable: true);
  List<CurrentDeliveryModel> deliveryList = List.empty(growable: true);
  List<CurrentDeliveryModel> activeDrsList = List.empty(growable: true);
  List<TripModel> tripsList = List.empty(growable: true);

  List<CurrentDeliveryModel> activeDrsLiveData = List.empty(growable: true);
  List<ModulesModel> modulesList = List.empty(growable: true);
  bool menuCardVisibility = true;
  String menuTitle = "";
  // DateTime? nowTime;
  String formattedDate = '';
  late AttendanceModel attendanceModel = AttendanceModel();
  Color? cardColor;
  DashboardTabs channel = DashboardTabs.ALLOTEDROUTES;
  late TabController _tabController;
  int offlinePodCount = 0;
  int offlineUndeliveryCount = 0;
  final locationService = LocationService();
  // final authService = AuthenticationService();
  bool showLocationWarning = false;
  int _selectedIndex = 0;
  GlobalKey<AllocatedRouteWidgetState> allotedRouteKey = GlobalKey();
  GlobalKey<DrsselectionBottomSheetState> drsSelectionKey = GlobalKey();
  GlobalKey<RunningTripsState> runningTripsKey = GlobalKey();
  GlobalKey<MidMileTripListState> midMileTripsKey = GlobalKey();
  final List<StreamSubscription> _subscriptions = [];
  final BaseRepository _baseRepo = BaseRepository();
  NotificationCountModel countModel = NotificationCountModel();
  String deviceId = "";
  static const String portalUrl = "https://gtjinni.com";
  String JINNI_URL = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => loadingAlertService = LoadingAlertService(context: context));
    getLoginPrefs();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((timestamp) {
      ScreenDimension.width = MediaQuery.of(context).size.width;
      ScreenDimension.height = MediaQuery.of(context).size.height;
    });

    formattedDate = formatDate(DateTime.now().millisecondsSinceEpoch);
    debugPrint('Formatted date $formattedDate');
    todayDateTime = DateTime.now();
    smallDateTime = DateFormat('yyyy-MM-dd').format(todayDateTime);
    fromDt = smallDateTime.toString();
    toDt = smallDateTime.toString();
    DateTime fromdt = DateTime.parse(fromDt);
    DateTime todt = DateTime.parse(toDt);
    viewFromDt = DateFormat('dd-MM-yyyy').format(fromdt);
    viewToDt = DateFormat('dd-MM-yyyy').format(todt);
    fetchOfflineDrsCounts();
    // fetchLocationStartTimeInterval(); // Moved to getLoginPrefs
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        refreshScreen();
      }
    });
    // Bluetooth().scan();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }

  @override
  void didPopNext() {
    refreshScreen();
  }

  Future<void> refreshScreen() async {
    // Fluttertoast.showToast(msg: 'Refreshing');
    getDashboardDetails();
    fetchOfflineDrsCounts();
    // getNotifiocaionCount();
  }

  fetchLocationStartTimeInterval() {
    Map<String, String> params = {
      "prmvarname": "GLMDLIVETRACKINGREFRESHRATE   ",
      "prmcompanyid": savedLogin.companyid.toString(),
    };

    printParams(params);
    _baseRepo.getValueFromCompAccPara(params);
  }

  openActionCentre() {
    PageLinkJsonParams param = PageLinkJsonParams(
      drivercode: savedUser.drivercode.toString(),
      grno: "",
    );
    Map<String, String> params = {
      "prmlinkpagemenucode": "GTI_LINKPAGEACTIONCENTRE",
      "prmjsondatastr": jsonEncode(param),
      "prmusercode": savedUser.usercode.toString(),
      "prmmenucode": "GTAPP_NOTIFICATIONPANEL",
      "prmsessionid": savedUser.sessionid.toString(),
      "prmloginbranchcode": savedUser.loginbranchcode.toString(),
      "prmloginbranchtype": savedUser.loginbranchtype.toString(),
    };

    printParams(params);
    _baseRepo.getInfinitiOpsLink(params);
  }

  openFuelForm() {
    PageLinkJsonParams param = PageLinkJsonParams(
      drivercode: savedUser.drivercode.toString(),
      grno: "",
    );
    Map<String, String> params = {
      "prmlinkpagemenucode": "GTI_FUELINGDETAILMASTER",
      "prmjsondatastr": jsonEncode(param),
      "prmusercode": savedUser.usercode.toString(),
      "prmmenucode": "GTAPP_FUELINGDETAIL",
      "prmsessionid": savedUser.sessionid.toString(),
      "prmloginbranchcode": savedUser.loginbranchcode.toString(),
      "prmloginbranchtype": savedUser.loginbranchtype.toString(),
    };

    printParams(params);
    _baseRepo.getInfinitiOpsLink(params);
  }

  fetchOfflineDrsCounts() async {
    try {
      int pod = await DBHelper.getPodEntryCount();
      int undelivery = await DBHelper.getUndeliveryCount();

      setState(() {
        offlinePodCount = pod;
        offlineUndeliveryCount = undelivery;
      });
    } catch (err) {
      failToast(err.toString());
    }
  }

  setObservers() {
    _subscriptions
        .add(viewModel.routeDashboardLiveData.stream.listen((dashboard) {
      debugPrint('dashboard List Length: ${dashboard.length}');
      if (dashboard.isNotEmpty && dashboard.elementAt(0).commandstatus == 1) {
        setState(() {
          routeList = dashboard;
        });
      }
    }));
    _subscriptions
        .add(viewModel.deliveryDashboardLiveData.stream.listen((dashboard) {
      debugPrint('dashboard List Length: ${dashboard.length}');

      if (dashboard.isNotEmpty && dashboard.elementAt(0).commandstatus == 1) {
        setState(() {
          deliveryList = dashboard;
        });
      }
    }));
    _subscriptions.add(viewModel.attendanceLiveData.stream.listen((attendance) {
      debugPrint('dashboard List Length: ${attendance}');

      if (attendance.commandstatus == 1) {
        setState(() {
          attendanceModel = attendance;
          todayAttendance = attendance;
          cardColor = attendanceModel.attendancestatus == "Present"
              ? CommonColors.successColor!
              : CommonColors.dangerColor!;
        });
      }
    }));
    _subscriptions.add(viewModel.viewDialog.stream.listen((showLoading) {
      if (showLoading) {
        loadingAlertService.showLoading();
      } else {
        loadingAlertService.hideLoading();
      }
    }));

    _subscriptions.add(viewModel.tripsListData.stream.listen((tripData) {
      if (tripData == null || tripData.isEmpty) {
        debugPrint('Trip data is empty, stopping location service...');
        locationService.stopService();
        tripsList.clear();
        return;
      } else {
        if (tripData.elementAt(0).commandstatus == 1) {
          setState(() {
            tripsList = tripData;
            checkAuthenticatedUserForRunService(tripData);
          });
        }
      }
      // checkAuthenticatedUserForRunService(tripData);
    }));

    _subscriptions
        .add(viewModel.validateDeviceLiveData.stream.listen((validate) {
      setState(() {
        if (validate.validlogin == "N" || validate.singledevice == "N") {
          failToast(validate.commandmessage.toString());
          authService.logout(context);
        } else if (validate.requiredaupdate == "Y") {
          failToast(validate.commandmessage.toString());
          _updateScreen(context);
          // } else if (validate.executiveid == null ||
          //     validate.employeeid == null) {
          // } else if (validate.executiveid == null) {
          //   failToast("Invalid User details");
          //   authService.logout(context);
        } else{
           if(isNullOrEmpty(savedUser.drivercode)){
              // Get.off(UserDashboardPage());
            // failToast("Driver Details Not Found Please Contact Admin.");
            // authService.logout(context);
           }

        } 
        // else if (isNullOrEmpty(validate.executiveid.toString()) == false &&
        //     int.parse(validate.executiveid.toString()) > 0) {
        //   // getNotifiocaionCount();
        //   // getDashboardDetails();
        // }
      });
    }));

    _subscriptions.add(viewModel.isErrorLiveData.stream.listen((errMsg) {
      failToast(errMsg);
    }));
    _subscriptions.add(_baseRepo.isErrorLiveData.stream.listen((errMsg) {
      failToast(errMsg);
    }));

    _subscriptions.add(_baseRepo.viewDialog.stream.listen((showLoading) {
      if (showLoading) {
        loadingAlertService.showLoading();
      } else {
        loadingAlertService.hideLoading();
      }
    }));

    _subscriptions.add(
        viewModel.drsDateTimeUpdateLiveData.stream.listen((drsUpdate) async {
      if (drsUpdate.commandstatus == 1) {
        // if(drsUpdate.drsstatus == "O"){
        //     locationService.startService(activeDrsList,savedUser);
        // }else if(drsUpdate.drsstatus == "C"){
        //     locationService.stopService();
        // }
        //  else
        if (drsUpdate.commandmessage != null) {
          successToast(drsUpdate.commandmessage!);
        } else {
          successToast("Date time updated successfully");
        }
        getDashboardDetails();
      } else {
        if (drsUpdate.commandmessage != null) {
          failToast(drsUpdate.commandmessage!);
        } else {
          failToast("Something went wrong");
        }
      }
    }));

    _subscriptions.add(_baseRepo.compAccPara.stream.listen((value) async {
      if (!isNullOrEmpty(value)) {
        int newInterval = int.parse(value) * 1000;
        if (locationUpdateInterval != newInterval) {
          debugPrint(
              '[Service] Location interval changed: $locationUpdateInterval -> $newInterval');
          locationUpdateInterval = newInterval;

          // Re-initialize and restart if running
          await locationService.init();
          if (await FlutterForegroundTask.isRunningService) {
            debugPrint('[Service] Restarting service to apply new interval');
            checkAuthenticatedUserForRunService(tripsList);
          }
        }
      }
    }));

    _subscriptions
        .add(viewModel.notificationCountLiveData.stream.listen((value) {
      if (value.commandstatus == 1) {
        setState(() {
          countModel = value;
          notificationCountModel = countModel;
        });
      } else {
        if (value.commandmessage != null) {
          failToast(value.commandmessage!);
        } else {
          failToast("Something went wrong");
        }
      }
    }));

    _subscriptions.add(_baseRepo.urlModel.stream.listen((value) async {
      // if (value != null) {
      if (value != null && value.commandstatus == 1) {
        var url = value.pageLink;
        debugPrint(url);
        if (url != null && url.isNotEmpty) {
          try {
            await launchUrl(
              Uri.parse(url),
              mode: LaunchMode.externalApplication,
            );
          } catch (_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Could not launch URL',
                  ),
                ),
              );
            }
          }
        }
      } else {
        failToast(
            value.commandmessage ?? "Unable To Open Action Centre,INVALID URL");
      }
    }));
  }

  Future<void> checkAuthenticatedUserForRunService(
      List<TripModel> tripData) async {
    try {
      final bool isRunning = await FlutterForegroundTask.isRunningService;

      // Stop if not authenticated
      if (authService.isAuthenticated.value != true) {
        debugPrint('[Service] User not authenticated → stop');
        if (isRunning) await locationService.stopService();
        return;
      }

      // Stop if no trips
      if (tripData.isEmpty) {
        debugPrint('[Service] Trip list empty → stop');
        if (isRunning) await locationService.stopService();
        return;
      }

      // Stop if command status invalid
      if (tripData.first.commandstatus != 1) {
        debugPrint('[Service] Invalid command status → stop');
        if (isRunning) await locationService.stopService();
        return;
      }

      // Stop if no dispatched trips
      final hasDispatchedTrip = tripData.any(
        (trip) =>
            trip.tripdispatchdatetime != null &&
            trip.tripdispatchdatetime.toString().isNotEmpty,
      );
      if (!hasDispatchedTrip) {
        debugPrint('[Service] No dispatched trips → stop');
        if (isRunning) await locationService.stopService();
        return;
      }

      // Prepare data to send
      final tripList = tripData.map((trip) => trip.tripid.toString()).toList();
      final dataToPass = {
        'tripList': tripList,
        'userData': savedUser.toJson(),
      };

      if (!isRunning) {
        debugPrint(
            '[Service] Starting foreground service with interval: $locationUpdateInterval');

        final accepted = await _showLocationDisclosure();

        if (!accepted) {
          debugPrint('[Service] User did not accept location disclosure');
          return;
        }
        await locationService.requestPermissions();

        await locationService.init(); // Ensure latest interval is used
        await FlutterForegroundTask.startService(
          notificationTitle: 'Location Tracking Active',
          notificationText: 'Your location is being tracked.',
          callback: startCallback,
        );

        // Send data after service starts
        Future.delayed(const Duration(milliseconds: 300), () {
          FlutterForegroundTask.sendDataToTask(dataToPass);
        });
      } else {
        debugPrint('[Service] Updating foreground service data');
        FlutterForegroundTask.sendDataToTask(dataToPass);
      }
    } catch (e, stack) {
      debugPrint('[Service] Error: $e');
      debugPrint(stack.toString());
    }
  }

  Future<bool> _showLocationDisclosure() async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Location Access Required'),
        content: const Text(
          'This app uses your device location to provide live trip tracking '
          'and trip monitoring. Your location may be collected while the app '
          'is in use and, when required for an active or dispatched trip, '
          'while the app is running in the background.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(
              'Cancel',
              style: TextStyle(color: CommonColors.colorPrimary2),
            ),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: Text(
              'Continue',
              style: TextStyle(color: CommonColors.colorPrimary2),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    return result ?? false;
  }

  getLoginPrefs() {
    try {
      getLoginData().then((login) => {
            if (login.commandstatus == null || login.commandstatus == -1)
              {_goToLogin()}
            else
              {
                companyId = login.companyid.toString(),
                getUserData().then((user) => {
                      if (user.commandstatus == null ||
                          user.commandstatus == -1)
                        throw Exception("")
                      else
                        {
                          setObservers(),
                          validateDevice(),
                          getDashboardDetails(),
                          fetchLocationStartTimeInterval()
                        }
                    })
              }
          });
    } catch (err) {
      debugPrint(err.toString());
      _goToLogin();
    }
  }

  _goToLogin() {
    Routes.goToPage(RoutesName.login, "Login");
  }

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   if (state == AppLifecycleState.resumed) {
  //     setState(() {
  //       // getLoginPref().then((value) => {refreshData()});
  //       getLoginData();
  //       getDashboardDetails();
  //     });
  //   }
  // }

  void _updateScreen(BuildContext context) {
    // storageClear();
    // Routes.goToPage(RoutesName.update, "Update");
    Get.offAll(const UpdateVersionScreen());
  }

  logout() {
    commonAlertDialog(context, "ALERT!", "Are you sure you want to logout?", "",
        const Icon(Icons.logout), okayCallBack,
        cancelCallBack: cancelPopup);
  }

  okayCallBack() {
    Future.delayed(Duration.zero, () {
      // Get.off(const LoginPage());
      // authService.storageRemove(ENV.userPrefTag);
      // authService.storageRemove(ENV.loginPrefTag);
      authService.logout(context);
    });
  }

  void cancelPopup() {
    // Navigator.pop(context);
    Get.back();
  }

  Future<void> validateDevice() async {
    // failToast('data not found');
    String deviceId = await getDeviceId();
    Map<String, String> params = {
      "prmconstring": savedLogin.companyid.toString(),
      "prmusercode": savedUser.usercode.toString(),
      "prmpassword": savedUser.password.toString(),
      "prmappversion": ENV.appVersion,
      "prmapp": ENV.appName,
      // "prmdeviceid": getUuid(),
      "prmdeviceid": deviceId,
      "prmsessionid": savedUser.sessionid.toString(),
      "prmappplatform": Platform.isAndroid ? "ANDROID" : "IOS",
    };
    debugPrint("Validating Device: ");
    printParams(params);
    viewModel.callValidateDeviceData(params);
  }

  void getDashboardDetails() {
    // failToast('data not found');
    deliveryList.clear();
    routeList.clear();

    Map<String, String> params = {
      "prmcompanyid": savedLogin.companyid.toString(),
      "prmusercode": savedUser.usercode.toString(),
      "prmbranchcode": savedUser.loginbranchcode.toString(),
      "prmemployeeid": savedUser.employeeid.toString(),
      // "prmfromdt": ENV.isDebugging == true ? "2025-01-01" : fromDt,
      "prmfromdt": convert2SmallDateTime(dashboardFromDt.toString()),
      "prmtodt": convert2SmallDateTime(dashboardToDt.toString()),
      "prmsessionid": savedUser.sessionid.toString(),
    };

    printParams(params);
    viewModel.callDashboardDetail(params);
  }

  void getNotifiocaionCount() {
    Map<String, String> params = {
      "prmcompanyid": savedLogin.companyid.toString(),
      "prmloginbranchcode": savedUser.loginbranchcode.toString(),
      "prmloginbranchtype": savedUser.loginbranchtype.toString(),
      "prmlogindt": convert2SmallDateTime(savedUser.logindatetime.toString()),
      "prmusercode": savedUser.usercode.toString(),
      "prmdivisionid": savedUser.logindivisionid.toString(),
      "prmsessionid": savedUser.sessionid.toString(),
    };

    printParams(params);
    viewModel.getNotificationCount(params);
  }

  void _dateChanged(String fromDt, String toDt) {
    // debugPrint("fromDt ${fromDt}");
    // debugPrint("toDt ${toDt}");

    this.fromDt = fromDt;
    this.toDt = toDt;

    DateTime fromdt = DateTime.parse(this.fromDt);
    DateTime todt = DateTime.parse(this.toDt);
    dashboardFromDt = fromdt;
    dashboardToDt = todt;
    viewFromDt = DateFormat('dd-MM-yyyy').format(fromdt);
    viewToDt = DateFormat('dd-MM-yyyy').format(todt);
    // getDashboardDetails();
    if (_selectedIndex == 0) {
      allotedRouteKey.currentState?.onRefresh();
    } else if (_selectedIndex == 1) {
      drsSelectionKey.currentState?.refreshScreen();
    } else if (_selectedIndex == 2) {
      runningTripsKey.currentState?.onRefresh();
    } else if (_selectedIndex == 3) {
      midMileTripsKey.currentState?.onRefresh();
    }
  }

  Widget attendanceInfo() {
    // double screenWidth = MediaQuery.of(context).size.width;
    // bool isSmallDevice = screenWidth <= 360;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, // Starts at the top
          end: Alignment.bottomCenter, // Ends at the bottom
          colors: [
            CommonColors.colorPrimary!, // Top color
            CommonColors.colorPrimary!
                .withAlpha((0.50 * 255).toInt()!), // Bottom color
            // You can add more colors here if needed
          ],
        ),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.smallHorizontalPadding,
            vertical: SizeConfig.smallVerticalPadding),
        margin: EdgeInsets.symmetric(
            horizontal: SizeConfig.horizontalPadding,
            vertical: SizeConfig.smallVerticalPadding),
        decoration: BoxDecoration(
          color: CommonColors.colorPrimary2,
          borderRadius: BorderRadius.circular(SizeConfig.largeRadius),
        ),
        child: Column(
          children: [
            Visibility(
              visible: employeeid != null,
              child: InkWell(
                onTap: () {
                  Get.to(() => const AttendanceScreen())?.then((_) {
                    getDashboardDetails();
                    validateDevice();
                  });
                },
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig.extraSmallHorizontalPadding,
                        vertical: SizeConfig.extraSmallVerticalPadding),
                    decoration: BoxDecoration(
                      // color: CommonColors.colorPrimary,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: CommonColors.white!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      // mainAxisAlignment: MainAxisAlignment.spaceAround,

                      children: [
                        // Status indicator dot
                        // Container(
                        //   // width: SizeConfig.smallIconSize,
                        //   // height: SizeConfig.smallIconSize,
                        //   margin: const EdgeInsets.only(right: 6),
                        //   decoration: BoxDecoration(
                        //     color:
                        //         attendanceModel.attendancestatus == "Absent"
                        //             ? CommonColors.dangerColor
                        //             : CommonColors.successColor,
                        //     shape: BoxShape.circle,
                        //   ),
                        // ),
                        Icon(Icons.circle,
                            size: SizeConfig.smallIconSize,
                            color: attendanceModel.attendancestatus == "Absent"
                                ? CommonColors.dangerColor
                                : CommonColors.successColor),
                        Text(
                          attendanceModel.attendancestatus == 'Present'
                              // ? "${attendanceModel.attendancedisplaytxt!.substring(0, 10)}${attendanceModel.attendancedisplaytxt!.substring(attendanceModel.attendancedisplaytxt!.length - 8)}"
                              ? "Online".toString().toUpperCase()
                              : "Offline",
                          style: TextStyle(
                            fontSize: SizeConfig.extraSmallTextSize,
                            color: CommonColors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.person_pin,
                      color: CommonColors.White,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Driver',
                      style: TextStyle(
                        fontSize: SizeConfig.smallTextSize,
                        color: CommonColors.White,
                      ),
                    ),
                  ],
                ),
                // SizedBox(height: SizeConfig.smallVerticalSpacing),
                Text(
                  // formattedDate,
                  '  • ${savedLogin.displayname.toString().toUpperCase()}',
                  style: TextStyle(
                    fontSize: SizeConfig.smallTextSize,
                    fontWeight: FontWeight.w800,
                    color: CommonColors.White,
                  ),
                ),
              ],
            )
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //   children: [
            //     Row(
            //       children: [
            //         Column(
            //           crossAxisAlignment: CrossAxisAlignment.start,
            //           children: [
            //             Text(
            //               'Current Date',
            //               style: TextStyle(
            //                 fontSize: SizeConfig.smallTextSize,
            //                 color: CommonColors.White,
            //               ),
            //             ),
            //             SizedBox(height: SizeConfig.smallVerticalSpacing),
            //             Text(
            //               formattedDate,
            //               style: TextStyle(
            //                 fontSize: SizeConfig.smallTextSize,
            //                 fontWeight: FontWeight.w500,
            //                 color: CommonColors.White,
            //               ),
            //             ),
            //           ],
            //         ),
            //         SizedBox(width: SizeConfig.mediumHorizontalSpacing),
            //         Visibility(
            //           visible: ENV.isDebugging,
            //           child: GestureDetector(
            //             onTap: () {
            //               // Get.to(const BluetoothScreen());
            //             },
            //             child: Container(
            //               padding: EdgeInsets.symmetric(
            //                   horizontal: SizeConfig.smallHorizontalSpacing,
            //                   vertical: SizeConfig.smallVerticalSpacing),
            //               decoration: BoxDecoration(
            //                 border: Border.all(color: CommonColors.white!),
            //                 shape: BoxShape.circle,
            //               ),
            //               child: Icon(Icons.bluetooth,
            //                   size: SizeConfig.extraLargeIconSize,
            //                   color: CommonColors.White),
            //             ),
            //           ),
            //         )
            //       ],
            //     ),
            //     Row(
            //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //       children: [
            //         GestureDetector(
            //           onTap: () async {
            //             showDatePickerBottomSheet(context, _dateChanged);
            //           },
            //           child: Container(
            //             padding: EdgeInsets.symmetric(
            //                 horizontal: SizeConfig.mediumHorizontalSpacing,
            //                 vertical: SizeConfig.mediumVerticalSpacing),
            //             decoration: BoxDecoration(
            //                 shape: BoxShape.circle,
            //                 color: CommonColors.colorPrimary,
            //                 border: Border.all(color: CommonColors.White!)),
            //             child: Icon(Icons.calendar_today,
            //                 size: SizeConfig.largeIconSize,
            //                 color: CommonColors.White),
            //           ),
            //         )
            //       ],
            //     ),
            //   ],
            // ),
            // SizedBox(height: SizeConfig.smallVerticalSpacing),
            // Visibility(
            //   visible: employeeid != null,
            //   child: InkWell(
            //     onTap: () {
            //       Get.to(() => const AttendanceScreen())?.then((_) {
            //         getDashboardDetails();
            //       });
            //     },
            //     child: Row(
            //       children: [
            //         // Punch status indicator with color based on status
            //         Container(
            //           padding: EdgeInsets.symmetric(
            //               horizontal: SizeConfig.horizontalPadding,
            //               vertical: SizeConfig.verticalPadding),
            //           decoration: BoxDecoration(
            //             color: CommonColors.colorPrimary,
            //             borderRadius:
            //                 BorderRadius.circular(SizeConfig.largeRadius),
            //             border: Border.all(color: Colors.white30),
            //           ),
            //           child: Row(
            //             children: [
            //               // Status indicator dot
            //               Container(
            //                 width: isSmallDevice ? 6 : 8,
            //                 height: isSmallDevice ? 6 : 8,
            //                 margin: const EdgeInsets.only(right: 6),
            //                 decoration: BoxDecoration(
            //                   color: attendanceModel.attendancestatus == "Absent"
            //                       ? CommonColors.dangerColor
            //                       : CommonColors.successColor,
            //                   shape: BoxShape.circle,
            //                 ),
            //               ),
            //               Text(
            //                 attendanceModel.attendancestatus == 'Present'
            //                     ? "${attendanceModel.attendancedisplaytxt!.substring(0, 10)}${attendanceModel.attendancedisplaytxt!.substring(attendanceModel.attendancedisplaytxt!.length - 8)}"
            //                         .toString()
            //                         .toUpperCase()
            //                     : "Absent",
            //                 style: TextStyle(
            //                   fontSize: SizeConfig.smallTextSize,
            //                   color: Colors.white,
            //                   fontWeight: FontWeight.w500,
            //                 ),
            //               ),
            //             ],
            //           ),
            //         ),
            //         // const SizedBox(width: 8),
            //         // Icon(
            //         //   Icons.chevron_right,
            //         //   size: isSmallDevice ? 16 : 20,
            //         //   color: Colors.white,
            //         // ),
            //       ],
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );

    // Container(
    //   padding: EdgeInsets.symmetric(
    //       horizontal: SizeConfig.mediumHorizontalSpacing,
    //       vertical: SizeConfig.mediumVerticalSpacing),
    //   margin: EdgeInsets.only(
    //       top: SizeConfig.mediumVerticalSpacing,
    //       bottom: SizeConfig.smallVerticalSpacing,
    //       left: SizeConfig.mediumHorizontalSpacing,
    //       right: SizeConfig.mediumHorizontalSpacing),
    //   decoration: BoxDecoration(
    //     color: CommonColors.colorPrimary,
    //     borderRadius: BorderRadius.circular(12),
    //     boxShadow: const [
    //       BoxShadow(
    //         color: Colors.black12,
    //         blurRadius: 4,
    //         offset: Offset(0, 2),
    //       ),
    //     ],
    //   ),
    //   child: Column(
    //     children: [
    //       Row(
    //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //         children: [
    //           Row(
    //             children: [
    //               Column(
    //                 crossAxisAlignment: CrossAxisAlignment.start,
    //                 children: [
    //                   Text(
    //                     'Current Date',
    //                     style: TextStyle(
    //                       fontSize: SizeConfig.smallTextSize,
    //                       color: CommonColors.White,
    //                     ),
    //                   ),
    //                   SizedBox(height: SizeConfig.smallVerticalSpacing),
    //                   Text(
    //                     formattedDate,
    //                     style: TextStyle(
    //                       fontSize: SizeConfig.smallTextSize,
    //                       fontWeight: FontWeight.w500,
    //                       color: CommonColors.White,
    //                     ),
    //                   ),
    //                 ],
    //               ),
    //               SizedBox(width: SizeConfig.mediumHorizontalSpacing),
    //               Visibility(
    //                 visible: ENV.isDebugging,
    //                 child: GestureDetector(
    //                   onTap: () {
    //                     // Get.to(const BluetoothScreen());
    //                   },
    //                   child: Container(
    //                     padding: EdgeInsets.symmetric(
    //                         horizontal: SizeConfig.smallHorizontalSpacing,
    //                         vertical: SizeConfig.smallVerticalSpacing),
    //                     decoration: BoxDecoration(
    //                       border: Border.all(color: CommonColors.white!),
    //                       shape: BoxShape.circle,
    //                     ),
    //                     child: Icon(Icons.bluetooth,
    //                         size: SizeConfig.extraLargeIconSize,
    //                         color: CommonColors.White),
    //                   ),
    //                 ),
    //               )
    //             ],
    //           ),
    //           Row(
    //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //             children: [
    //               GestureDetector(
    //                 onTap: () async {
    //                   showDatePickerBottomSheet(context, _dateChanged);
    //                 },
    //                 child: Container(
    //                   padding: EdgeInsets.symmetric(
    //                       horizontal: SizeConfig.mediumHorizontalSpacing,
    //                       vertical: SizeConfig.mediumVerticalSpacing),
    //                   decoration: BoxDecoration(
    //                       shape: BoxShape.circle,
    //                       color: CommonColors.colorPrimary,
    //                       border: Border.all(color: CommonColors.White!)),
    //                   child: Icon(Icons.calendar_today,
    //                       size: SizeConfig.largeIconSize,
    //                       color: CommonColors.White),
    //                 ),
    //               )
    //             ],
    //           ),
    //         ],
    //       ),
    //       SizedBox(height: SizeConfig.smallVerticalSpacing),
    //       Visibility(
    //         visible: employeeid != null,
    //         child: InkWell(
    //           onTap: () {
    //             Get.to(() => const AttendanceScreen())?.then((_) {
    //               getDashboardDetails();
    //             });
    //           },
    //           child: Row(
    //             children: [
    //               // Punch status indicator with color based on status
    //               Container(
    //                 padding: EdgeInsets.symmetric(
    //                     horizontal: SizeConfig.horizontalPadding,
    //                     vertical: SizeConfig.verticalPadding),
    //                 decoration: BoxDecoration(
    //                   color: CommonColors.colorPrimary,
    //                   borderRadius:
    //                       BorderRadius.circular(SizeConfig.largeRadius),
    //                   border: Border.all(color: Colors.white30),
    //                 ),
    //                 child: Row(
    //                   children: [
    //                     // Status indicator dot
    //                     Container(
    //                       width: isSmallDevice ? 6 : 8,
    //                       height: isSmallDevice ? 6 : 8,
    //                       margin: const EdgeInsets.only(right: 6),
    //                       decoration: BoxDecoration(
    //                         color: attendanceModel.attendancestatus == "Absent"
    //                             ? CommonColors.dangerColor
    //                             : CommonColors.successColor,
    //                         shape: BoxShape.circle,
    //                       ),
    //                     ),
    //                     Text(
    //                       attendanceModel.attendancestatus == 'Present'
    //                           ? "${attendanceModel.attendancedisplaytxt!.substring(0, 10)}${attendanceModel.attendancedisplaytxt!.substring(attendanceModel.attendancedisplaytxt!.length - 8)}"
    //                               .toString()
    //                               .toUpperCase()
    //                           : "Absent",
    //                       style: TextStyle(
    //                         fontSize: SizeConfig.smallTextSize,
    //                         color: Colors.white,
    //                         fontWeight: FontWeight.w500,
    //                       ),
    //                     ),
    //                   ],
    //                 ),
    //               ),
    //               // const SizedBox(width: 8),
    //               // Icon(
    //               //   Icons.chevron_right,
    //               //   size: isSmallDevice ? 16 : 20,
    //               //   color: Colors.white,
    //               // ),
    //             ],
    //           ),
    //         ),
    //       ),
    //     ],
    //   ),
    // );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isSmallDevice = screenWidth <= 360;

    if (attendanceModel == null) {
      return Scaffold(
          appBar: AppBar(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(SizeConfig.largeRadius),
                bottomRight: Radius.circular(SizeConfig.largeRadius),
              ),
            ),
            backgroundColor: CommonColors.colorPrimary,
            leading: Builder(builder: (context) {
              return IconButton(
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                  icon: Icon(
                    Icons.menu,
                    size: SizeConfig.mediumIconSize,
                    color: CommonColors.white,
                  ));
            }),
            title: Text(
              'Dashboard',
              style: TextStyle(
                  color: CommonColors.white,
                  fontSize: SizeConfig.extraLargeIconSize),
            ),
          ),
          drawer: const SideMenu(),
          body: Center(
            child: Text(
              "data not  found ".toUpperCase(),
              style: TextStyle(
                  color: CommonColors.successColor,
                  fontSize: SizeConfig.mediumTextSize),
            ),
          ));
    } else {
      return Scaffold(
          appBar: AppBar(
            // shape: RoundedRectangleBorder(
            //   borderRadius: BorderRadius.only(
            //     bottomLeft: Radius.circular(SizeConfig.largeRadius),
            //     bottomRight: Radius.circular(SizeConfig.largeRadius),
            //   ),
            // ),
            backgroundColor: CommonColors.colorPrimary,
            // title: Text(
            //   'Dashboard',
            //   style: TextStyle(
            //     fontSize: SizeConfig.extraLargeIconSize,
            //     fontWeight: FontWeight.w600,
            //     color: Colors.white,
            //   ),
            // ),
            leading: Builder(builder: (context) {
              return IconButton(
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                  icon: CircleAvatar(
                    backgroundColor: CommonColors.White,
                    child: Icon(
                      Icons.menu,
                      size: SizeConfig.largeIconSize,
                      color: CommonColors.colorPrimary,
                    ),
                  ));
            }),
            actions: [
              IconButton.outlined(
                style: ButtonStyle(
                  minimumSize: const WidgetStatePropertyAll(Size(40, 40)),
                  padding: const WidgetStatePropertyAll(EdgeInsets.all(12)),
                  backgroundColor:
                      WidgetStatePropertyAll(CommonColors.colorPrimary2),
                  side: WidgetStatePropertyAll(
                    BorderSide(color: CommonColors.colorPrimary2),
                  ),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
                color: CommonColors.white,
                onPressed: () async {
                  showDatePickerBottomSheet(context, _dateChanged);
                },
                icon: Icon(
                  Symbols.calendar_today_rounded,
                  size: SizeConfig.largeIconSize,
                  color: CommonColors.white,
                ),
              ),
              SizedBox(width: SizeConfig.smallHorizontalSpacing),
              Badge(
                backgroundColor: CommonColors.white,
                label: Text(
                  // '${countModel.totalcount ?? 0}',
                  '',
                  style: TextStyle(color: CommonColors.colorPrimary),
                ),
                offset: const Offset(-1, 1),
                child: IconButton.outlined(
                  style: ButtonStyle(
                    minimumSize: const WidgetStatePropertyAll(Size(40, 40)),
                    padding: const WidgetStatePropertyAll(EdgeInsets.all(12)),
                    backgroundColor:
                        WidgetStatePropertyAll(CommonColors.colorPrimary2),
                    side: WidgetStatePropertyAll(
                      BorderSide(color: CommonColors.colorPrimary2),
                    ),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                  color: CommonColors.colorPrimary,
                  onPressed: () async {
                    // await notificationOptionBottomSheet(context).then((value) {
                    //   refreshScreen();
                    // });
                    openActionCentre();
                  },
                  icon: Icon(
                    Symbols.notifications,
                    size: SizeConfig.largeIconSize,
                    color: CommonColors.white,
                  ),
                ),
              ),
              SizedBox(width: SizeConfig.smallHorizontalSpacing),
              // IconButton.outlined(
              //   style: ButtonStyle(
              //     minimumSize: const WidgetStatePropertyAll(Size(40, 40)),
              //     padding: const WidgetStatePropertyAll(EdgeInsets.all(12)),
              //     backgroundColor:
              //         WidgetStatePropertyAll(CommonColors.colorPrimary2),
              //     side: WidgetStatePropertyAll(
              //       BorderSide(color: CommonColors.colorPrimary2),
              //     ),
              //     shape: WidgetStatePropertyAll(
              //       RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(18),
              //       ),
              //     ),
              //   ),
              //   color: CommonColors.white,
              //   onPressed: () async {
              //     // await showOfflineDrsBottomSheet(context).then((value) {
              //     //   refreshScreen();
              //     // });
              //     homePopupMenu();
              //   },
              //   icon: Icon(
              //     Symbols.more_vert,
              //     size: SizeConfig.largeIconSize,
              //     color: CommonColors.white,
              //   ),
              // ),
              Container(
                margin: EdgeInsets.symmetric(vertical: 6, horizontal: 7),
                decoration: BoxDecoration(
                  color: CommonColors.colorPrimary2,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.white,
                    size: SizeConfig.largeIconSize,
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'offlinesync':
                        {
                          showOfflineDrsBottomSheet(context).then((value) {
                            // refreshScreen();
                          });
                        }
                        break;
                      case 'fuelDetailEntry':
                        {
                          openFuelForm();
                        }
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'offlinesync',
                      child: Row(
                        children: [
                          Icon(
                            Icons.sync_rounded,
                            size: 15,
                          ),
                          SizedBox(
                            width: 4,
                          ),
                          Text('Offline Sync')
                        ],
                      ),
                    ),
                     const PopupMenuItem(
                      value: 'fuelDetailEntry',
                      child: Row(
                        children: [
                          Icon(
                            Icons.local_gas_station,
                            size: 15,
                          ),
                          SizedBox(
                            width: 4,
                          ),
                          Text('Fuel Detail Entry')
                        ],
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          // extendBody: true,
          bottomNavigationBar:
              //  NavigationBar(
              //   selectedIndex: _selectedIndex,
              //   onDestinationSelected: (value) {
              //     setState(() {
              //       _selectedIndex = value;
              //       // _pageController.jumpToPage(value);
              //       debugPrint("value $value");
              //       if (value == 0) {
              //         allotedRouteKey.currentState?.onRefresh();
              //       } else if (value == 1) {
              //         drsSelectionKey.currentState?.refreshScreen();
              //       } else if (value == 2) {
              //         runningTripsKey.currentState?.onRefresh();
              //       } else if (value == 3) {
              //         midMileTripsKey.currentState?.onRefresh();
              //       }
              //     });
              //   },
              //   labelTextStyle: WidgetStatePropertyAll(
              //       TextStyle(fontSize: SizeConfig.smallTextSize)),
              //   indicatorColor: CommonColors.colorPrimary!
              //       .withAlpha((0.15 * 255).toInt()), // light background
              //   destinations: [
              //     NavigationDestination(
              //       icon: Icon(Icons.route, size: SizeConfig.extraLargeIconSize),
              //       selectedIcon: Icon(
              //         Icons.route,
              //         size: SizeConfig.extraLargeIconSize,
              //         color: CommonColors.colorPrimary,
              //       ),
              //       label: "ROUTES",
              //     ),
              //     NavigationDestination(
              //       icon: Icon(Symbols.add_road_rounded,
              //           size: SizeConfig.extraLargeIconSize),
              //       selectedIcon: Icon(
              //         Symbols.add_road_rounded,
              //         size: SizeConfig.extraLargeIconSize,
              //         color: CommonColors.colorPrimary,
              //       ),
              //       label: "CREATE TRIP",
              //     ),
              //     NavigationDestination(
              //       icon: Icon(Symbols.local_shipping,
              //           size: SizeConfig.extraLargeIconSize),
              //       selectedIcon: Icon(
              //         Symbols.local_shipping,
              //         size: SizeConfig.extraLargeIconSize,
              //         color: CommonColors.colorPrimary,
              //       ),
              //       label: "TRIPS",
              //     ),
              //     NavigationDestination(
              //       icon: Icon(Symbols.alt_route_rounded,
              //           size: SizeConfig.extraLargeIconSize),
              //       selectedIcon: Icon(
              //         Symbols.alt_route_rounded,
              //         size: SizeConfig.extraLargeIconSize,
              //         color: CommonColors.colorPrimary,
              //       ),
              //       label: "MMT",
              //     ),
              //   ],
              // ),

              ClipRRect(
            borderRadius: BorderRadius.circular(30.0),
            child: BottomAppBar(
              color: CommonColors.colorPrimary2,
              shape: const CircularNotchedRectangle(),
              // shape: const InvertedCircularNotchedRectangle(),
              notchMargin: 10,
              elevation: 10,
              child: SizedBox(
                height: 65,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _navItem(
                      // image: 'assets/images/routes.svg',
                      image: 'assets/images/routes_icon.png',
                      label: "Routes",
                      index: 0,
                    ),
                    _navItem(
                      image: 'assets/images/create_trip_icon.png',
                      // label: "Create Trip",
                      // label: "${"Create Trip".split(' ').join('\n')}",
                      label: "${"CreateTrip".split(' ').join('\n')}",
                      index: 1,
                    ),
                    FloatingActionButton(
                      elevation: 2,

                      shape: const CircleBorder(),

                      backgroundColor: Colors.transparent,
                      highlightElevation: 10.0,
                      child: Transform.scale(
                        scale: 1.2,
                        child: Image.asset(
                          'assets/images/jinni_icon.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                      // Container(
                      //   decoration: const BoxDecoration(
                      //     shape: BoxShape.circle,
                      //     // color:Color.fromARGB(255, 246, 87, 1)
                      //     color:Color.fromARGB(255, 254, 89, 1)
                      //   ),
                      //   child: ClipOval(
                      //     child: Image.asset(
                      //       'assets/images/jinni_icon.png',
                      //       fit: BoxFit.cover,
                      //       // width: 50,
                      //       // height: 50,
                      //     ),
                      //   ),
                      // ),
                      onPressed: () async {
                        // center button action
                        deviceId = await getDeviceId();
                        if (isNullOrEmpty(deviceId)) {
                          // failToast("Unable to get Device ID");
                          JINNI_URL = portalUrl;
                        } else {
                          JINNI_URL =
                              "$portalUrl/loginbysessionid?companyid=${savedUser.companyid}&sessionid=${savedUser.sessionid}&id=$deviceId &routename=chat&theme=dark";
                        }

                        // url = "https://gtjinni.com/";
                        if (JINNI_URL != null && JINNI_URL.isNotEmpty) {
                          try {
                            await launchUrl(
                              Uri.parse(JINNI_URL),
                              mode: LaunchMode.externalApplication,
                            );
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Could not launch URL',
                                  ),
                                ),
                              );
                            }
                          }
                        }
                      },
                    ),
                    _navItem(
                      // image: 'assets/images/trip.svg',
                      image: 'assets/images/trips_icon.png',
                      label: "Trips",
                      index: 2,
                    ),
                    _navItem(
                      // image: 'assets/images/mmt.svg',
                      image: 'assets/images/mmt_icon.png',
                      label: "MMT",
                      index: 3,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // floatingActionButtonLocation:
          //     FloatingActionButtonLocation.centerDocked,
          // floatingActionButton: FloatingActionButton(
          //   elevation: 2,

          //   shape: const CircleBorder(),

          //   backgroundColor: Colors.transparent,
          //   highlightElevation: 10.0,
          //   child: Transform.scale(
          //     scale: 1.2,
          //     child: Image.asset(
          //       'assets/images/jinni_icon.png',
          //       fit: BoxFit.cover,
          //     ),
          //   ),
          //   // Container(
          //   //   decoration: const BoxDecoration(
          //   //     shape: BoxShape.circle,
          //   //     // color:Color.fromARGB(255, 246, 87, 1)
          //   //     color:Color.fromARGB(255, 254, 89, 1)
          //   //   ),
          //   //   child: ClipOval(
          //   //     child: Image.asset(
          //   //       'assets/images/jinni_icon.png',
          //   //       fit: BoxFit.cover,
          //   //       // width: 50,
          //   //       // height: 50,
          //   //     ),
          //   //   ),
          //   // ),
          //   onPressed: () async {
          //     // center button action
          //     deviceId = await getDeviceId();
          //     if (isNullOrEmpty(deviceId)) {
          //       // failToast("Unable to get Device ID");
          //       JINNI_URL = portalUrl;
          //     } else {
          //       JINNI_URL =
          //           "$portalUrl/loginbysessionid?companyid=${savedUser.companyid}&sessionid=${savedUser.sessionid}&id=$deviceId &routename=chat&theme=dark";
          //     }

          //     // url = "https://gtjinni.com/";
          //     if (JINNI_URL != null && JINNI_URL.isNotEmpty) {
          //       try {
          //         await launchUrl(
          //           Uri.parse(JINNI_URL),
          //           mode: LaunchMode.externalApplication,
          //         );
          //       } catch (_) {
          //         if (context.mounted) {
          //           ScaffoldMessenger.of(context).showSnackBar(
          //             const SnackBar(
          //               content: Text(
          //                 'Could not launch URL',
          //               ),
          //             ),
          //           );
          //         }
          //       }
          //     }
          //   },
          // ),
          drawer: const SideMenu(),
          // floatingActionButton: AvatarGlow(
          //     glowColor: CommonColors.colorPrimary ?? Colors.blue,
          //     repeat: true,
          //     child: FloatingActionButton(
          //       onPressed: () async {
          //         deviceId = await getDeviceId();
          //         if (isNullOrEmpty(deviceId)) {
          //           // failToast("Unable to get Device ID");
          //           JINNI_URL = portalUrl;
          //         } else {
          //           JINNI_URL =
          //               "$portalUrl/loginbysessionid?companyid=${savedUser.companyid}&sessionid=${savedUser.sessionid}&id=$deviceId &routename=chat&theme=dark";
          //         }

          //         // url = "https://gtjinni.com/";
          //         if (JINNI_URL != null && JINNI_URL.isNotEmpty) {
          //           try {
          //             await launchUrl(
          //               Uri.parse(JINNI_URL),
          //               mode: LaunchMode.externalApplication,
          //             );
          //           } catch (_) {
          //             if (context.mounted) {
          //               ScaffoldMessenger.of(context).showSnackBar(
          //                 const SnackBar(
          //                   content: Text(
          //                     'Could not launch URL',
          //                   ),
          //                 ),
          //               );
          //             }
          //           }
          //         }
          //       },
          //       shape: const CircleBorder(),
          //       backgroundColor: CommonColors.indigoshade50,
          //       highlightElevation: 20.0,
          //       child: Container(
          //         decoration: BoxDecoration(
          //           shape: BoxShape.circle,
          //           border: Border.all(
          //             color: CommonColors.colorPrimary ??
          //                 Colors.blue, // Border color
          //             width: 2, // Border thickness
          //           ),
          //         ),
          //         child: ClipOval(
          //           child: Image.asset(
          //             'assets/images/jinnilogo.png',
          //             fit: BoxFit.cover,
          //             // width: 50,
          //             // height: 50,
          //           ),
          //         ),
          //       ),
          //     )),

          body: Container(
            color: CommonColors.blueGrey?.withOpacity(0.1),
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                Column(
                  children: [
                    attendanceInfo(),
                    // const SizedBox(height: 16),
                    // Visibility(
                    //   visible: ENV.isDebugging,
                    //   child: GestureDetector(
                    //     onTap: () async {
                    //       Get.to(const MidMileTripList());
                    //     },
                    //     child: Container(
                    //       padding: EdgeInsets.symmetric(
                    //           horizontal: isSmallDevice ? 8 : 16,
                    //           vertical: isSmallDevice ? 8 : 12),
                    //       margin: EdgeInsets.only(
                    //           top: 16,
                    //           bottom: 4,
                    //           left: isSmallDevice ? 8 : 16,
                    //           right: isSmallDevice ? 8 : 16),
                    //       decoration: BoxDecoration(
                    //         color: CommonColors.colorPrimary,
                    //         borderRadius: BorderRadius.circular(12),
                    //         boxShadow: const [
                    //           BoxShadow(
                    //             color: Colors.black12,
                    //             blurRadius: 4,
                    //             offset: Offset(0, 2),
                    //           ),
                    //         ],
                    //       ),
                    //       child: Text(
                    //         'Test',
                    //         style: TextStyle(
                    //           fontSize: isSmallDevice ? 12 : 14,
                    //           fontWeight: FontWeight.w500,
                    //           color: Colors.white,
                    //         ),
                    //       ),
                    //     ),
                    //   ),
                    // ),

                    Expanded(
                      child: AllocatedRouteWidget(
                        key: allotedRouteKey,
                        attendanceModel: attendanceModel,
                        // routeList: routeList,
                        // onRefresh: refreshScreen,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    attendanceInfo(),
                    Expanded(
                      child: DrsselectionBottomSheet(
                        key: drsSelectionKey,
                        tripId: 0,
                        showTripInfoUpdate: true,
                        onRefresh: refreshScreen,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    attendanceInfo(),
                    Expanded(
                      child: RunningTrips(
                        key: runningTripsKey,
                        // deliveryList: tripsList,
                        attendanceModel: attendanceModel,
                        // onRefresh: refreshScreen
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    attendanceInfo(),
                    Expanded(
                      child: MidMileTripList(
                        key: midMileTripsKey,
                      ),
                    ),
                  ],
                )
              ],
            ),
          )
          // PageView(
          //   physics: const NeverScrollableScrollPhysics(),
          //   controller: _pageController,
          //   children: [
          // Column(
          //   children: [
          //     attendanceInfo(),
          //     Expanded(
          //       child: AllocatedRouteWidget(
          //         attendanceModel: attendanceModel,
          //         // routeList: routeList,
          //         // onRefresh: refreshScreen,
          //       ),
          //     ),
          //   ],
          // ),
          //     Column(
          //       children: [
          //         attendanceInfo(),
          //         Expanded(
          //           child: DrsselectionBottomSheet(
          //             tripId: 0,
          //             showTripInfoUpdate: false,
          //             onRefresh: refreshScreen,
          //           ),
          //         ),
          //       ],
          //     ),
          //     Column(
          //       children: [
          //         attendanceInfo(),
          //         Expanded(
          //           child: AssignTripWidget(
          //               deliveryList: tripsList,
          //               attendanceModel: attendanceModel,
          //               onRefresh: refreshScreen),
          //         ),
          //       ],
          //     ),
          //     Column(
          //       children: [
          //         attendanceInfo(),
          //         const Expanded(child: ProfileScreen()),
          //       ],
          //     ),
          //   ],
          // )
          );
    }
  }

  Widget _navItem({
    required String image,
    required String label,
    required int index,
  }) {
    bool selected = _selectedIndex == index;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;

          debugPrint("value $_selectedIndex");
          if (_selectedIndex == 0) {
            allotedRouteKey.currentState?.onRefresh();
          } else if (_selectedIndex == 1) {
            drsSelectionKey.currentState?.refreshScreen();
          } else if (_selectedIndex == 2) {
            runningTripsKey.currentState?.onRefresh();
          } else if (_selectedIndex == 3) {
            midMileTripsKey.currentState?.onRefresh();
          }
        });
      },
      child: SizedBox(
        width: 65,
        height: 65,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              image,
              width: SizeConfig.extraLargeIconSize,
              height: SizeConfig.extraLargeIconSize,
              color: selected
                  ? CommonColors.colorPrimary
                  : CommonColors.white, // remove if your image has fixed colors
            ),
            const SizedBox(height: 1),
            Text(
              label,
              maxLines: 2,
              softWrap: true,
              textAlign: TextAlign.center,
              overflow: TextOverflow.clip,
              style: TextStyle(
                color:
                    selected ? CommonColors.colorPrimary : CommonColors.white,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

//   Widget _navItem({
//   required String image,
//   required String label,
//   required int index,
// }) {
//   bool selected = _selectedIndex == index;

//   return InkWell(
//     onTap: () {
//       setState(() {
//         _selectedIndex = index;
//       });
//     },
//     child: Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         SvgPicture.asset(
//           image,
//           width: 20,
//           height: 20,
//           colorFilter: ColorFilter.mode(
//             selected
//                 ? CommonColors.colorPrimary!
//                 : CommonColors.blueGrey600!,
//             BlendMode.srcIn,
//           ),
//         ),
//         // const SizedBox(height: 4),
//         Text(
//           label,
//           style: TextStyle(
//             color: selected
//                 ? CommonColors.colorPrimary
//                 : CommonColors.blueGrey600,
//             fontSize: 12,
//           ),
//         ),
//       ],
//     ),
//   );
// }
}

class InvertedCircularNotchedRectangle extends NotchedShape {
  const InvertedCircularNotchedRectangle();

  @override
  Path getOuterPath(Rect host, Rect? guest) {
    if (guest == null || !host.overlaps(guest)) {
      return Path()..addRect(host);
    }

    final double radius = guest.width / 2;

    // FAB center
    final double centerX = guest.center.dx;

    // How high the inverted curve rises above the bar
    final double curveHeight = radius * 0.99;

    final Path path = Path();

    path.moveTo(host.left, host.top);

    // Left side before inverted curve
    path.lineTo(centerX - radius - 20, host.top);

    // Smooth left transition going upward (∩)
    path.cubicTo(
      centerX - radius,
      host.top,
      centerX - radius,
      host.top - curveHeight,
      centerX,
      host.top - curveHeight,
    );

    // Top circular curve
    path.cubicTo(
      centerX + radius,
      host.top - curveHeight,
      centerX + radius,
      host.top,
      centerX + radius + 20,
      host.top,
    );

    // Right side
    path.lineTo(host.right, host.top);
    path.lineTo(host.right, host.bottom);
    path.lineTo(host.left, host.bottom);

    path.close();

    return path;
  }
}

// class InvertedCircularNotchedRectangle extends NotchedShape {

  
//   const InvertedCircularNotchedRectangle({
//     this.notchMargin = 8.0,
//   });

//   final double notchMargin;

//   @override
//   Path getOuterPath(Rect host, Rect? guest) {
//     if (guest == null || !host.overlaps(guest)) {
//       return Path()..addRect(host);
//     }

//     // Radius of the FAB + margin, so the curve clears the button nicely
//     final double r = (guest.width / 2.0);
//     final double cx = guest.center.dx;

//     // How far above the bar's top edge the curve peaks
//     final double peakOffset = r * 1.15;

//     // Width of the flat shoulders on either side before curving starts
//     final double shoulder = r * 1.6;

//     return Path()
//       ..moveTo(host.left, host.top)
//       ..lineTo(cx - shoulder, host.top)
//       // Left curve up — cubic bezier for a smoother, rounder shoulder
//       ..cubicTo(
//         cx - shoulder + r * 0.60, host.top, // control point 1
//         cx - r, host.top - peakOffset * 0.85, // control point 2
//         cx - r * 0.15, host.top - peakOffset, // near peak, left side
//       )
//       // Smooth peak/top of the arc
//       ..cubicTo(
//         cx - r * 0.15 + r * 0.15,
//         host.top - peakOffset - r * 0.1,
//         cx + r * 0.15 - r * 0.15,
//         host.top - peakOffset - r * 0.1,
//         cx + r * 0.15,
//         host.top - peakOffset,
//       )
//       // Right curve down — mirrors the left cubic
//       ..cubicTo(
//         cx + r,
//         host.top - peakOffset * 0.85,
//         cx + shoulder - r * 0.50,
//         host.top,
//         cx + shoulder,
//         host.top,
//       )
//       ..lineTo(host.right, host.top)
//       ..lineTo(host.right, host.bottom)
//       ..lineTo(host.left, host.bottom)
//       ..close();
//   }
// }



