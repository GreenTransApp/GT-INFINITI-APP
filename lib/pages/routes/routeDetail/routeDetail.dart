import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gtlmd/api/HttpCalls.dart';
import 'package:gtlmd/base/BaseRepository.dart';
import 'package:gtlmd/common/Colors.dart';
import 'package:gtlmd/common/Utils.dart';
import 'package:gtlmd/common/alertBox/commonAlertDialog.dart';
import 'package:gtlmd/common/alertBox/loadingAlertWithCancel.dart';
import 'package:gtlmd/common/toast.dart';
import 'package:gtlmd/design_system/size_config.dart';

import 'package:gtlmd/pages/home/Model/allotedRouteModel.dart';
import 'package:gtlmd/pages/mapView/OsmMapScreen.dart';
import 'package:gtlmd/pages/mapView/mapViewPage.dart';
import 'package:gtlmd/pages/mapView/models/mapConfigJsonModel.dart';
import 'package:gtlmd/pages/receivedLoad/ReceivedLoadPage.dart';

import 'package:gtlmd/pages/routes/routeDetail/Model/routeDetailModel.dart';
import 'package:gtlmd/pages/routes/routeDetail/Model/routeDetailUpdateModel.dart';
import 'package:gtlmd/pages/routes/routeDetail/routeDetailViewModel.dart';
import 'package:gtlmd/tiles/routeDetailTile.dart';
import 'package:lottie/lottie.dart';

class Routedetail extends StatefulWidget {
  final AllotedRouteModel model;
  const Routedetail({super.key, required this.model});

  @override
  State<Routedetail> createState() => _RoutedetailState();
}

class _RoutedetailState extends State<Routedetail> {
  late LoadingAlertService loadingAlertService;
  final RouteDetailviewModel viewModel = RouteDetailviewModel();
  List<RouteDetailModel> routeDetailList = List.empty(growable: true);
  List<RouteDetailModel> originalRouteDetailList = List.empty(growable: true);
  bool showActionBtn = true;
  bool showUpdateBtn = false;
  AllotedRouteModel modelDetail = AllotedRouteModel();
  MapConfigJsonModel mapConfig = MapConfigJsonModel();
  RouteUpdateModel acceptRouteModel = RouteUpdateModel();
  RouteUpdateModel rejectRouteModel = RouteUpdateModel();
  BaseRepository _baseRepo = BaseRepository();
  double totalDistance = 0;
  List<StreamSubscription> _subscription = [];

  bool routeModifyAllowed = false;
  bool hasDeliveries = false;
  bool enableGoogleAPI = false;

  @override
  void initState() {
    super.initState();
    modelDetail = widget.model;

    WidgetsBinding.instance.addPostFrameCallback(
        (_) => loadingAlertService = LoadingAlertService(context: context));

    getUserData().then((user) => {
          if (user.commandstatus == null || user.commandstatus == -1)
            throw Exception("")
          else
            {
              // _getGoogleMapApiKey(),
              // getMapConfig()
              setObservers(),
              _getRouteChangeAllowedPara(),
              getRouteDetails(),
              getValueForGoogleMap()
            }
        });

    setState(() {
      if (isNullOrEmpty(todayAttendance.outtime)) {
        showActionBtn = true;
      } else {
        showActionBtn = false;
      }
    });
  }

  getValueForGoogleMap() async {
    final value = await _baseRepo.returnValueFromCompAccPara({
      "prmvarname": "GENABLEGOOGLEMAPAPI",
      "prmcompanyid": savedLogin.companyid.toString(),
    });
    if (!isNullOrEmpty(value)) {
      enableGoogleAPI = value == "Y" ? true : false;
      if (enableGoogleAPI) {
        getMapConfig();
        _getGoogleMapApiKey();
      }
    } else {
      enableGoogleAPI = false;
    }
  }

  @override
  void dispose() {
    for (var sub in _subscription) {
      sub.cancel();
    }
    super.dispose();
  }

  getMapConfig() {
    Map<String, String> params = {
      "prmcompanyid": savedLogin.companyid.toString(),
      "prmusercode": savedUser.usercode.toString(),
      "prmbranchcode": savedUser.loginbranchcode.toString(),
      "prmplanningid": modelDetail.planningid.toString(),
      "prmsessionid": savedUser.sessionid.toString(),
    };

    printParams(params);
    // viewModel.getMapConfig(params);
    _baseRepo.getMapConfig(params);
  }

  _getRouteChangeAllowedPara() {
    Map<String, String> params = {
      "prmvarname": "GALLOWLMDROUTEINMOBILEAPP",
      "prmcompanyid": savedLogin.companyid.toString(),
    };

    printParams(params);
    _baseRepo.getValueFromCompAccPara(params);
  }

  setObservers() {
    _subscription.add(viewModel.routeDetailLiveData.stream.listen((resp) {
      if (resp.elementAt(0).commandstatus == 1) {
        setState(() {
          routeDetailList = resp;

          if (originalRouteDetailList.isEmpty) {
            originalRouteDetailList = resp;
          }

          // debugPrint(
          //     "===========================BEFORE===========================");
          for (int i = 0; i < routeDetailList.length; i++) {
            RouteDetailModel route = routeDetailList[i];
            // debugPrint(
            //     "${route.grno} ${route.address} ${route.deliverylat} ${route.deliverylong} ${route.distance} ${route.sequenceid} ${route.planningdraftcode}");

            if (route.consignmenttype == 'D' &&
                route.grno != 'Pickup' &&
                route.grno != 'Final Point') {
              hasDeliveries = true;
              return;
            }
          }
          // debugPrint(
          //     "===========================AFTER===========================");
        });
      }
    }));
    _subscription.add(viewModel.routeDataLiveData.stream.listen((resp) {
      if (resp.commandstatus == 1) {
        setState(() async {
          modelDetail = resp;
          if (modelDetail.acceptedStatus! == "Y") {
            showUpdateBtn = true;
          } else {
            showUpdateBtn = false;
          }
        });
      }
    }));
    _subscription.add(viewModel.routeAcceptLiveData.stream.listen((resp) {
      if (resp.commandstatus == 1) {
        setState(() {
          acceptRouteModel = resp;
          successToast("PLANNING ACCEPTED SUCCESSFULLY");

          getRouteDetails();
        });
      } else {
        failToast(resp.commandmessage.toString() ?? "Something went wrong");
      }
    }));
    _subscription.add(viewModel.routeRejectLiveData.stream.listen((resp) {
      if (resp.commandstatus == 1) {
        setState(() {
          rejectRouteModel = resp;
          successToast("PLANNING REJECTED SUCCESSFULLY");
          okayCallBackForAlert();
        });
      } else {
        failToast(resp.commandmessage.toString() ?? "Something went wrong");
      }
    }));

    _subscription.add(viewModel.viewDialog.stream.listen((showLoading) {
      if (showLoading) {
        loadingAlertService.showLoading();
      } else {
        loadingAlertService.hideLoading();
      }
    }));

    _subscription.add(viewModel.isErrorLiveData.stream.listen((errMsg) {
      failToast(errMsg);
    }));

    _subscription
        .add(viewModel.updateRoutePlanning.stream.listen((updateRoute) {
      if (updateRoute.commandstatus == 1) {
        routeDetailList = [];
        successToast("Route updated successfully");
        getRouteDetails();
      }
    }));

    _subscription.add(_baseRepo.mapConfigDetail.stream.listen((resp) {
      if (resp.commandStatus == 1) {
        // Handle map config detail response
        debugPrint("Map Config Detail: ${resp.mapConfigData}");
        mapConfig = resp.mapConfigData ?? MapConfigJsonModel();
      } else {
        failToast(resp.commandMessage ?? "Failed to fetch map config details");
      }
    }));

    _subscription.add(_baseRepo.accResp.stream.listen((resp) async {
      if (isNullOrEmpty(resp)) {
        failToast("Unable To Fetch Google Map Api key, plese Try Again.");
      } else {
        GOOGLE_MAPS_API_KEY = resp;
      }
    }));

    _subscription.add(_baseRepo.compAccPara.stream.listen((resp) {
      routeModifyAllowed = resp == 'Y';
      setState(() {});
    }));

    // _subscription.add(_baseRepo.compAccPara.stream.listen((resp) {
    //   debugPrint(resp);
    //   if (!isNullOrEmpty(resp)) {
    //     enableGoogleAPI = resp == "Y" ? true : false;
    //     if (enableGoogleAPI) {
    //       getMapConfig();
    //       _getGoogleMapApiKey();
    //     }
    //   } else {
    //     enableGoogleAPI = false;
    //   }
    // }));
  }

  void okayCallBackForAlert() {
    Navigator.pop(context);
  }

  void getRouteDetails() {
    // failToast('data not found');
    Map<String, String> params = {
      "prmcompanyid": savedLogin.companyid.toString(),
      "prmusercode": savedUser.usercode.toString(),
      "prmbranchcode": savedUser.loginbranchcode.toString(),
      "prmplanningid": modelDetail.planningid.toString(),
      "prmsessionid": savedUser.sessionid.toString(),
    };
    printParams(params);
    viewModel.getRouteDetailData(params);
  }

  void updateRoute() {
    List<String> grnoList = List.empty(growable: true);
    List<String> addressList = List.empty(growable: true);
    List<String> deliverylatList = List.empty(growable: true);
    List<String> deliverylongList = List.empty(growable: true);
    List<String> pickuplatList = List.empty(growable: true);
    List<String> pickuplongList = List.empty(growable: true);
    List<String> distanceList = List.empty(growable: true);
    List<String> sequenceidList = List.empty(growable: true);
    List<String> planningdraftcodeList = List.empty(growable: true);
    List<String> orderTypeList = List.empty(growable: true);
    List<String> indentIdList = List.empty(growable: true);

    for (int i = 0; i < routeDetailList.length; i++) {
      RouteDetailModel route = routeDetailList[i];
      debugPrint(
          "${route.grno} ${route.address} ${route.deliverylat} ${route.deliverylong} ${route.distance} ${route.sequenceid} ${route.planningdraftcode}");
      grnoList.add(route.grno.toString());
      addressList.add(route.address.toString());
      deliverylatList.add(route.deliverylat.toString());
      deliverylongList.add(route.deliverylong.toString());
      pickuplatList.add(route.pickuplat.toString());
      pickuplongList.add(route.pickuplong.toString());
      distanceList.add(route.distance.toString() ?? '0');
      sequenceidList.add(route.sequenceid.toString() ?? '0');
      indentIdList.add(route.indentid.toString() ?? '0');
      orderTypeList.add(route.consignmenttype.toString() ?? 'D');
      planningdraftcodeList.add(route.planningdraftcode.toString());
    }

    Map<String, dynamic> params = {
      "prmcompanyid": savedLogin.companyid.toString(),
      "prmusercode": savedUser.usercode.toString(),
      "prmbranchcode": savedUser.loginbranchcode.toString(),
      "prmplanningid": modelDetail.planningid.toString(),
      "prmdraftcodestr": planningdraftcodeList.join(",") + ",",
      "prmsequenceidstr": sequenceidList.join(",") + ",",
      "prmgrnostr": grnoList.join(",") + ",",
      "prmaddressstr": addressList.join(",") + ",",
      "prmdeliverylatstr": deliverylatList.join(",") + ",",
      "prmdeliverylongstr": deliverylongList.join(",") + ",",
      "prmpickuplatstr": pickuplatList.join(",") + ",",
      "prmpickuplongstr": pickuplongList.join(",") + ",",
      "prmdistancestr": distanceList.join(",") + ",",
      "prmordertypestr": orderTypeList.join(",") + ",",
      "prmordertypestr": orderTypeList.join(",") + ",",
      "prmindentidstr": indentIdList.join(",") + ",",
      "prmsessionid": savedUser.sessionid.toString(),
    };

    debugPrint(savedLogin.companyid.toString());
    viewModel.updateRoute(params);
  }

  void alterForAccept() {
    commonAlertDialog(
        context,
        "Confirm!",
        "Are you sure you want to 'ACCEPT' route  ",
        //  ' $_currentAddress ' ,
        "",
        Icon(Icons.dangerous),
        _acceptRoute,
        cancelCallBack: okayCallBackForAlert,
        iconColor: CommonColors.successColor!,
        timer: 10);
  }

  void alterForReject() {
    commonAlertDialog(
        context,
        "Confirm!",
        "Are you sure you want to 'REJECT' route  ",
        //  ' $_currentAddress ' ,
        "",
        Icon(Icons.dangerous),
        _rejectRoute,
        cancelCallBack: okayCallBackForAlert,
        iconColor: CommonColors.dangerColor!,
        timer: 10);
  }

  void _acceptRoute() {
    // failToast('data not found');
    Map<String, String> params = {
      "prmcompanyid": savedLogin.companyid.toString(),
      "prmusercode": savedUser.usercode.toString(),
      "prmbranchcode": savedUser.loginbranchcode.toString(),
      "prmplanningid": modelDetail.planningid.toString(),
      "prmsessionid": savedUser.sessionid.toString(),
    };

    printParams(params);
    viewModel.acceptRouteUpdate(params);
  }

  _getGoogleMapApiKey() {
    Map<String, String> params = {
      "keyNo": "73",
      "prmcompanyid": savedLogin.companyid.toString(),
    };

    printParams(params);
    _baseRepo.getValueFromAccPara(params);
  }

  void _rejectRoute() {
    // failToast('data not found');
    Map<String, String> params = {
      "prmcompanyid": savedLogin.companyid.toString(),
      "prmusercode": savedUser.usercode.toString(),
      "prmbranchcode": savedUser.loginbranchcode.toString(),
      "prmplanningid": modelDetail.planningid.toString(),
      "prmsessionid": savedUser.sessionid.toString(),
    };

    printParams(params);
    viewModel.rejectRouteUpdate(params);
  }

  void updateSequenceBeforeSubmit(List<int> totalDistanceList) {
    for (int i = 1; i < routeDetailList.length; i++) {
      routeDetailList[i].sequenceid = i;
      if (i < totalDistanceList.length) {
        routeDetailList[i].distance =
            (totalDistanceList[i].toDouble() / 1000).toString();
      } else {
        routeDetailList[i].distance = "0.00";
      }
    }

    getLoginData().then((login) => {updateRoute()});
  }

  Future<void> refreshScreen() async {
    getRouteDetails();
    getValueForGoogleMap();
  }

  fetchDistanceFromGoogleApi(List<RouteDetailModel> routeDetail) async {
    try {
      // totalDistance = await fetchTotalRouteDistance(routeDetail);
      // loadingAlertService.showLoading();
      List<int> totalDistanceList =
          await fetchTotalRouteDistance(routeDetail, mapConfig);
      // loadingAlertService.hideLoading();
      if (totalDistanceList.isEmpty) {
        failToast('Unable to calculate route distance.Please Try again.');
        return;
      }
      totalDistance = (totalDistanceList[0].toDouble()) / 1000;
      // debugPrint("New Distance: $distance");
      if (totalDistance >
          double.parse(modelDetail.totdistance!
              .substring(0, modelDetail.totdistance!.length - 4))) {
        double diff = totalDistance -
            double.parse(modelDetail.totdistance!
                .substring(0, modelDetail.totdistance!.length - 4));
        double diff2 = double.parse(diff.toStringAsFixed(6));

        showAlert("Distance Increased", const Icon(Icons.update_outlined), "",
            "Your distance has increased by $diff2 km. Do you still want to update?",
            () {
          setState(() {
            updateSequenceBeforeSubmit(totalDistanceList);
          });
        }, () {
          refreshScreen();
        });
      } else if (totalDistance <=
          double.parse(modelDetail.totdistance!
              .substring(0, modelDetail.totdistance!.length - 4))) {
        updateSequenceBeforeSubmit(totalDistanceList);
      }
    } catch (err) {
      debugPrint(err.toString());
    }
  }

  fetchDistanceFromOSM(List<RouteDetailModel> routeDetail) async {
    try {
      // totalDistance = await fetchTotalRouteDistance(routeDetail);
      // loadingAlertService.showLoading();
      List<int> totalDistanceList =
          await fetchTotalRouteDistanceWithOSM(routeDetail, mapConfig);
      // loadingAlertService.hideLoading();
      if (totalDistanceList.isEmpty) {
        failToast('Unable to calculate route distance.Please Try again.');
        return;
      }
      totalDistance = (totalDistanceList[0].toDouble()) / 1000;
      // debugPrint("New Distance: $distance");
      if (totalDistance >
          double.parse(modelDetail.totdistance!
              .substring(0, modelDetail.totdistance!.length - 4))) {
        double diff = totalDistance -
            double.parse(modelDetail.totdistance!
                .substring(0, modelDetail.totdistance!.length - 4));
        double diff2 = double.parse(diff.toStringAsFixed(6));

        showAlert("Distance Increased", const Icon(Icons.update_outlined), "",
            "Your distance has increased by $diff2 km. Do you still want to update?",
            () {
          setState(() {
            updateSequenceBeforeSubmit(totalDistanceList);
          });
        }, () {
          refreshScreen();
        });
      } else if (totalDistance <=
          double.parse(modelDetail.totdistance!
              .substring(0, modelDetail.totdistance!.length - 4))) {
        updateSequenceBeforeSubmit(totalDistanceList);
      }
    } catch (err) {
      debugPrint(err.toString());
    }
  }

  showAlert(String title, Icon icon, String address, String msg,
      void Function() okayCallBack, void Function() cancelCallBack) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            icon: icon,
            iconColor: CommonColors.appBarColor,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [Text(msg), Text(address)],
            ),
            actions: [
              Column(
                children: [
                  const Divider(
                    color: CommonColors.disableColor,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          cancelCallBack.call();
                          // Navigator.pop(context);
                          Get.back();
                        },
                        child: const Text(
                          'cancel',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                      Container(
                        height: 30.0,
                        width: 1.0,
                        color: CommonColors.disableColor,
                        margin: const EdgeInsets.only(left: 10.0, right: 10.0),
                      ),
                      TextButton(
                          onPressed: () {
                            okayCallBack.call();
                            // Navigator.pop(context);
                            Get.back();
                          },
                          child: const Text(
                            'okay',
                            style: TextStyle(color: Colors.black),
                          )),
                    ],
                  ),
                ],
              )
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    double screenWidth = MediaQuery.of(context).size.width;
    bool isSmallDevice = screenWidth <= 360;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: CommonColors.colorPrimary,
        title: Text(
          'Route Detail',
          style: TextStyle(
              color: CommonColors.White, fontSize: SizeConfig.largeTextSize),
        ),
        leading: IconButton(
            onPressed: () {
              Get.back();
            },
            icon: Icon(
              Icons.arrow_back,
              color: CommonColors.White,
              size: SizeConfig.largeIconSize,
            )),
        actions: [
          InkWell(
            onTap: () {
              if (enableGoogleAPI) {
                Get.to(MapViewPage(
                  model: modelDetail,
                  // routeDetailList: routeDetailList,
                ));
              } else {
                Get.to(OsmMapScreen(
                  model: modelDetail,
                  // routeDetailList: routeDetailList,
                ));
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Image.asset(
                "assets/images/map.png",
                height: SizeConfig.extraLargeIconSize,
              ),
            ),
          ),
        ],
      ),
      body: modelDetail == null
          ? Scaffold(
              body: Center(
              child: Text(
                "Data not  found ".toUpperCase(),
                style:
                    TextStyle(color: CommonColors.successColor, fontSize: 20),
              ),
            ))
          : Container(
              padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.smallHorizontalPadding,
                  vertical: SizeConfig.smallVerticalPadding),
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.symmetric(
                        horizontal: SizeConfig.smallHorizontalPadding,
                        vertical: SizeConfig.smallVerticalPadding),
                    decoration: BoxDecoration(
                      color: CommonColors.White,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: CommonColors.appBarColor
                              .withAlpha((0.05 * 255).round()),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: SizeConfig.horizontalPadding,
                              vertical: SizeConfig.verticalPadding),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal:
                                            SizeConfig.horizontalPadding,
                                        vertical: SizeConfig.verticalPadding),
                                    decoration: BoxDecoration(
                                      color: CommonColors.darkBlue!
                                          .withAlpha((0.3 * 255).round()),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: CommonColors.darkBlue!
                                            .withAlpha((0.3 * 255).round()),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.route,
                                      color: CommonColors.darkBlue,
                                      size: SizeConfig.largeIconSize,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Route ID : ${modelDetail.planningid}',
                                          style: theme.textTheme.titleLarge
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: SizeConfig.largeTextSize,
                                          ),
                                        ),
                                        Text(
                                          '${modelDetail.routename}',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: CommonColors.grey600,
                                            fontSize: SizeConfig.smallTextSize,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal:
                                            SizeConfig.smallHorizontalPadding,
                                        vertical:
                                            SizeConfig.smallVerticalPadding),
                                    decoration: BoxDecoration(
                                      color: CommonColors.amber100,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.inventory_2_outlined,
                                          size: SizeConfig.mediumIconSize,
                                          color: CommonColors.amber800,
                                        ),
                                        SizedBox(
                                            width: SizeConfig
                                                .extraSmallHorizontalSpacing),
                                        Text(
                                          '${routeDetailList.length - 2} Stops',
                                          style: TextStyle(
                                            color: CommonColors.amber800,
                                            fontWeight: FontWeight.w600,
                                            fontSize: SizeConfig.smallTextSize,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Divider(
                                thickness: 1,
                                color: CommonColors.grey200,
                              ),
                              SizedBox(
                                  height: SizeConfig.mediumVerticalSpacing),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal:
                                        SizeConfig.smallHorizontalPadding,
                                    vertical: SizeConfig.smallVerticalPadding),
                                // decoration: BoxDecoration(
                                //   color: CommonColors.grey200,
                                //   borderRadius: BorderRadius.circular(12),
                                //   border: Border.all(
                                //     color: CommonColors.grey200!,
                                //   ),
                                // ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildInfoItem(
                                        context,
                                        Icons.calendar_today_outlined,
                                        'Date & Time',
                                        '${modelDetail.planningdt}',
                                        CommonColors.red600!,
                                      ),
                                    ),
                                    Container(
                                      height: SizeConfig.largeVerticalSpacing,
                                      width: 1,
                                      color: CommonColors.grey300,
                                    ),
                                    Expanded(
                                      child: _buildInfoItem(
                                        context,
                                        Icons.straighten,
                                        'Total Distance',
                                        '${modelDetail.totdistance}',
                                        CommonColors.successColor!,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Route Timeline
                  Container(
                    padding: EdgeInsets.symmetric(
                        vertical: SizeConfig.verticalPadding,
                        horizontal: SizeConfig.horizontalPadding),
                    margin: EdgeInsets.symmetric(
                        // vertical: SizeConfig.verticalPadding,
                        horizontal: SizeConfig.horizontalPadding),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        CommonColors.red600!,
                        CommonColors.colorPrimary!
                      ]),
                      // color: CommonColors.colorPrimary,
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(SizeConfig.largeRadius),
                          topRight: Radius.circular(SizeConfig.largeRadius)),
                      boxShadow: [
                        BoxShadow(
                          color: CommonColors.appBarColor
                              .withAlpha((0.05 * 255).round()),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal:
                                  SizeConfig.extraSmallHorizontalPadding,
                              vertical: SizeConfig.smallVerticalPadding),
                          decoration: BoxDecoration(
                            color: CommonColors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: CommonColors.White!),
                          ),
                          child: Image.asset(
                            // 'assets/images/multipointlocation.png',
                            'assets/images/multilocation.png',
                            height: SizeConfig.extraLargeIconSize,
                            width: SizeConfig.extraLargeIconSize,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Delivery Route',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: SizeConfig.smallTextSize,
                            color: CommonColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // const SizedBox(height: 16),
                  routeDetailList.isEmpty
                      ? Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Lottie.asset(
                                  'assets/map_blue.json',
                                  height: 100,
                                ),
                                Text(
                                  "No Data Found",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w200,
                                      fontSize: isSmallDevice ? 12 : 16),
                                )
                              ],
                            ),
                          ),
                        )
                      : Expanded(
                          child: RefreshIndicator(
                            onRefresh: refreshScreen,
                            child: Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                    bottomLeft:
                                        Radius.circular(SizeConfig.largeRadius),
                                    bottomRight: Radius.circular(
                                        SizeConfig.largeRadius)),
                                boxShadow: [
                                  BoxShadow(
                                    color: CommonColors.appBarColor
                                        .withAlpha((0.05 * 255).round()),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child:
                                  //  showUpdateBtn?
                                  routeModifyAllowed
                                      ? ReorderableListView.builder(
                                          buildDefaultDragHandles: false,
                                          itemBuilder: (context, index) {
                                            var data = routeDetailList[index];
                                            return RouteDetailTile(
                                              key: ValueKey(data.sequenceid),
                                              model: data,
                                              listLength:
                                                  routeDetailList.length,
                                              index: index,
                                              showDragHandle: index != 0 &&
                                                  index !=
                                                      routeDetailList.length -
                                                          1,
                                            );
                                          },
                                          itemCount: routeDetailList.length,
                                          onReorder: (oldIndex, newIndex) {
                                            if (oldIndex == 0 ||
                                                oldIndex ==
                                                    routeDetailList.length - 1)
                                              return;
                                            if (newIndex == 0 ||
                                                newIndex ==
                                                    routeDetailList.length)
                                              return;

                                            if (oldIndex < newIndex) {
                                              newIndex--;
                                            }
                                            var item = routeDetailList
                                                .removeAt(oldIndex);
                                            routeDetailList.insert(
                                                newIndex, item);

                                            if (enableGoogleAPI) {
                                              fetchDistanceFromGoogleApi(
                                                  routeDetailList);
                                            } else {
                                              fetchDistanceFromOSM(
                                                  routeDetailList);
                                            }

                                            // updateSequenceBeforeSubmit();
                                          },
                                        )
                                      :

                                      // // Normal List
                                      ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: routeDetailList.length,
                                          itemBuilder: (context, index) {
                                            var data = routeDetailList[index];
                                            return RouteDetailTile(
                                              model: data,
                                              listLength:
                                                  routeDetailList.length,
                                              index: index,
                                              showDragHandle: false,
                                            );
                                          },
                                        ),
                            ),
                          ),
                        ),
                ],
              ),
            ),
      persistentFooterButtons: [
        Visibility(
          visible: showActionBtn && !showUpdateBtn,
          child: Row(
            children: [
              Expanded(
                  child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(colors: [
                      CommonColors.red600!,
                      CommonColors.colorPrimary!
                    ])),
                child: ElevatedButton.icon(
                  onPressed: () {
                    alterForReject();
                  },
                  icon: Icon(Icons.close, size: SizeConfig.smallIconSize),
                  label: Text(
                    "Reject",
                    style: TextStyle(fontSize: SizeConfig.smallTextSize),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CommonColors.transparent,
                    shadowColor: CommonColors.transparent,
                    foregroundColor: CommonColors.White,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              )
                  //  InkWell(
                  //   onTap: () {
                  //     alterForReject();
                  //   },
                  //   child: Container(
                  //     alignment: Alignment.center,
                  //     padding: const EdgeInsets.symmetric(
                  //         horizontal: 10, vertical: 15),
                  //     decoration: BoxDecoration(
                  //         color: CommonColors.dangerColor,
                  //         borderRadius:
                  //             const BorderRadius.all(Radius.circular(10))),
                  //     child: Text("Reject".toUpperCase(),
                  //         style: TextStyle(color: CommonColors.White)),
                  //   ),
                  // ),
                  ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                  child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(colors: [
                      CommonColors.whatsapp!,
                      CommonColors.successColor!
                    ])),
                child: ElevatedButton.icon(
                  onPressed: () {
                    // alterForAccept();
                    List<RouteDetailModel> _routeList =
                        List.empty(growable: true);

                    _routeList.addAll(routeDetailList.where((routeDetailList) =>
                        !routeDetailList.grno!.contains("Pickup") &&
                        !routeDetailList.grno!.contains("Final Point")));
                    if (_routeList.isNotEmpty && hasDeliveries) {
                      Get.to(() => ReceivedLoadPage(
                              receivedLoadList: _routeList,
                              model: modelDetail))!
                          .then(
                        (value) => {refreshScreen()},
                      );
                    } else {
                      // _acceptRoute();
                      alterForAccept();
                    }
                  },
                  icon: Icon(Icons.list, size: SizeConfig.smallIconSize),
                  // label: const Text("Accept"),
                  // label: const Text("Receive Load"),
                  label: hasDeliveries
                      ? Text(
                          "Receive Load",
                          style: TextStyle(fontSize: SizeConfig.smallTextSize),
                        )
                      : Text(
                          "Accept",
                          style: TextStyle(fontSize: SizeConfig.smallTextSize),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CommonColors.transparent,
                    shadowColor: CommonColors.transparent,
                    foregroundColor: CommonColors.White,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              )
                  //  InkWell(
                  //   onTap: () {
                  //     alterForAccept();
                  //   },
                  //   child: Container(
                  //     alignment: Alignment.center,
                  //     padding: const EdgeInsets.symmetric(
                  //         horizontal: 10, vertical: 15),
                  //     decoration: BoxDecoration(
                  //         color: CommonColors.successColor,
                  //         borderRadius:
                  //             const BorderRadius.all(Radius.circular(10))),
                  //     child: Text("Accept".toUpperCase(),
                  //         style: TextStyle(color: CommonColors.White)),
                  //   ),
                  // ),
                  ),
            ],
          ),
        ),
      ],
    );
  }

  // This widget is used to create Date & time and Total distance containters
  Widget _buildInfoItem(BuildContext context, IconData icon, String label,
      String value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.horizontalPadding),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.extraSmallHorizontalPadding,
            vertical: SizeConfig.extraSmallVerticalPadding),
        decoration: BoxDecoration(
            color: color.withAlpha((0.1 * 255).round()),
            border: Border.all(color: color.withAlpha((0.1 * 255).round())),
            borderRadius: BorderRadius.circular(SizeConfig.mediumRadius)),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.horizontalPadding,
                  vertical: SizeConfig.verticalPadding),
              decoration: BoxDecoration(
                color: color.withAlpha((0.3 * 255).round()),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withAlpha((0.3 * 255).round()),
                ),
              ),
              child: Icon(
                icon,
                size: SizeConfig.smallIconSize,
                color: color,
              ),
            ),
            SizedBox(width: SizeConfig.horizontalPadding),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: SizeConfig.smallTextSize,
                      color: Colors.black54,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: SizeConfig.smallTextSize,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
