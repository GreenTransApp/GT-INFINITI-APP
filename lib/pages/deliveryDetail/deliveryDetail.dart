import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:gtlmd/base/BaseRepository.dart';
import 'package:gtlmd/common/Colors.dart';
import 'package:gtlmd/common/Utils.dart';
import 'package:gtlmd/common/alertBox/loadingAlertWithCancel.dart';
import 'package:gtlmd/common/toast.dart';
import 'package:gtlmd/pages/deliveryDetail/Model/deliveryDetailModel.dart';
import 'package:gtlmd/pages/deliveryDetail/Model/lmdMenuModel.dart';
import 'package:gtlmd/pages/deliveryDetail/deliveryViewModel.dart';
import 'package:gtlmd/pages/mapView/mapViewPage.dart';
import 'package:gtlmd/pages/mapView/OsmMapScreen.dart';
import 'package:gtlmd/pages/trips/tripDetail/Model/currentDeliveryModel.dart';
import 'package:gtlmd/pages/trips/tripDetail/Model/tripModel.dart';
import 'package:gtlmd/service/locationService/appLocationService.dart';
import 'package:gtlmd/service/locationService/locationService.dart';
import 'package:gtlmd/tiles/deliveryDetailTile.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:material_symbols_icons/symbols.dart';

enum Filter { all, pending, delivered, pickup, undelivered, reversepickup }

class DeliveryDetail extends StatefulWidget {
  // final CurrentDeliveryModel model;
  final TripModel tripModel;
  const DeliveryDetail(
      {super.key,
      // required this.model,
      required this.tripModel});

  @override
  State<DeliveryDetail> createState() => _DeliveryDetailState();
}

class _DeliveryDetailState extends State<DeliveryDetail>
    with WidgetsBindingObserver {
  CurrentDeliveryModel deliveryModel = CurrentDeliveryModel();
  List<DeliveryDetailModel> deliveryDetailList = List.empty(growable: true);
  // List<DeliveryDetailModel> filteredList = List.empty(growable: true);
  List<LmdMenuModel> menuList = [];
  late LoadingAlertService loadingAlertService;
  final DeliveryViewModel viewModel = DeliveryViewModel();
  final BaseRepository _baseRepo = BaseRepository();
  final List<StreamSubscription> _subscription = [];
  String currentdt = '';
  late DateTime todayDateTime;
  late String smallDateTime;
  bool enableGoogleAPI = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // deliveryModel = widget.model;
    todayDateTime = DateTime.now();
    smallDateTime = DateFormat('yyyy-MM-dd').format(todayDateTime);
    currentdt = smallDateTime.toString();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => loadingAlertService = LoadingAlertService(context: context));

    setObservers();
    getMenu();
    getDeliveryDetails();
    //  Future.delayed(const Duration(seconds: 5), () {
    getValueForGoogleMap();
        // });
  }

  getValueForGoogleMap() async {
    final value = await _baseRepo.returnValueFromCompAccPara({
      "prmvarname": "GENABLEGOOGLEMAPAPI",
      "prmcompanyid": savedLogin.companyid.toString(),
    });
    if (!isNullOrEmpty(value)) {
      enableGoogleAPI = value == "Y" ? true : false;
    } else {
      enableGoogleAPI = false;
    }
  }

  void getBookingPdf() async {
    Map<String, String> params = {
      "prmconnstring": savedUser.companyid.toString(),
      "prmgrno": 'RUH10000288',
      "prmusercode": savedUser.usercode.toString(),
      "prmmenucode": "GTAPP_BOOKING",
      "prmsessionid": savedUser.sessionid.toString(),
    };
    String url = await _baseRepo.getBookingPrint(params);
    print(url);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    for (var sub in _subscription) {
      sub.cancel();
    }

    super.dispose();
  }

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   refreshScreen();
  // }

  setObservers() {
    viewModel.deliveryDetailLiveData.stream.listen((resp) {
      if (resp.isNotEmpty && resp.elementAt(0).commandstatus == 1) {
        setState(() {
          deliveryDetailList = resp;
          // filteredList = List.from(resp);
        });
      } else {
        setState(() {
          deliveryDetailList = [];
          // filteredList = [];
        });
      }
    });
    viewModel.deliveryDataLiveData.stream.listen((resp) {
      if (resp.commandstatus == 1) {
        setState(() {
          deliveryModel = resp;
        });
      }
    });

    viewModel.viewDialog.stream.listen((showLoading) {
      if (showLoading) {
        loadingAlertService.showLoading();
      } else {
        loadingAlertService.hideLoading();
      }
    });
    _baseRepo.viewDialog.stream.listen((showLoading) {
      if (showLoading) {
        loadingAlertService.showLoading();
      } else {
        loadingAlertService.hideLoading();
      }
    });

    viewModel.isErrorLiveData.stream.listen((errMsg) {
      failToast(errMsg);
    });

    viewModel.getMenuLiveData.stream.listen((data) {
      setState(() {
        menuList = data;
      });
      print(data);
    });

    // _subscription.add(_baseRepo.compAccPara.stream.listen((resp) {
    //   debugPrint(resp);
    //   var value = isNullOrEmpty(resp) ? "N" : resp;
    //   openMapScreen(value);
    // }));

    // _subscription.add(_baseRepo.compAccPara.stream.listen((resp) {
    //   debugPrint(resp);
    //   setState(() {
    //     if (resp.isNotEmpty && resp.contains('GTI')) {
    //       menuCode = resp;
    //       debugPrint('Booking Menucode ${resp}');
    //     } else {
    //       debugPrint('Booking Menucode Not Found');
    //     }
    //   });
    // }));

    _subscription.add(viewModel.updateDriverReachedLD.stream.listen((resp) {
      if (resp.commandstatus == 1) {
        successToast("Location Update successfull");
        refreshScreen();
      } else {
        failToast(resp.commandmessage ?? "Something went wrong");
      }
    }));

    _subscription.add(viewModel.driverReachedDlvPoint.stream.listen((resp) {
      if (resp.commandstatus == 1) {
        successToast("Location Update successfull");
        refreshScreen();
      } else {
        failToast(resp.commandmessage ?? "Something went wrong");
      }
    }));
    _subscription.add(viewModel.pickupDepartedPosition.stream.listen((resp) {
      if (resp.commandstatus == 1) {
        successToast("Location Update successfull");
        refreshScreen();
      } else {
        failToast(resp.commandmessage ?? "Something went wrong");
      }
    }));
  }

  getDeliveryDetails() {
    Map<String, String> params = {
      "prmcompanyid": savedLogin.companyid.toString(),
      "prmusercode": savedUser.usercode.toString(),
      "prmbranchcode": savedUser.loginbranchcode.toString(),
      "prmdrsno": "",
      "prmtripid": widget.tripModel.tripid.toString(),
      "prmsessionid": savedUser.sessionid.toString(),
    };

    printParams(params);
    viewModel.getDeliveryDetail(params);
  }

  getMenu() {
    Map<String, String> params = {
      "prmusercode": savedUser.usercode.toString(),
      "prmloginbranchcode": savedUser.loginbranchcode.toString(),
      "prmdivisionid": savedUser.logindivisionid.toString(),
      "prmsessionid": savedUser.sessionid.toString(),
    };

    printParams(params);
    viewModel.getMenu(params);
  }

  Future<void> refreshScreen() async {
    getDeliveryDetails();
    // getBookingMenuCodeFromCompAccPara();
  }

  Future<void> updateDriverReached(
      String grno, String indentId, String tripid, String jobid) async {
    loadingAlertService.showLoading();

    try {
      // Position position = await Geolocator.getCurrentPosition(
      //   locationSettings: const LocationSettings(
      //     accuracy: LocationAccuracy.high,
      //     distanceFilter: 0,
      //   ),
      // ).timeout(const Duration(seconds: 15));

      final position = await LocationService().getCurrentLocation();

      // final address = await AppLocationService().getAddressFromLatLng(
      //   position.latitude,
      //   position.longitude,
      // );

      Map<String, dynamic> params = {
        "prmusercode": savedUser.usercode.toString(),
        "prmbranchcode": savedUser.loginbranchcode.toString(),
        "prmtripid": tripid,
        "prmgrno": grno,
        "prmindentid": indentId,
        "prmreachedlat": position.latitude.toString(),
        "prmreachedlong": position.longitude.toString(),
        "prmjobid": isNullOrEmpty(jobid) ? "" : int.parse(jobid),
        "prmsessionid": savedUser.sessionid.toString(),
      };

      printParams(params);
      viewModel.updateDriverReached(params);
    } catch (e, stackTrace) {
      print("updateDriverReached ERROR: $e");
      print(stackTrace);
    } finally {
      loadingAlertService.hideLoading();
    }
  }

  Future<void> updateDriverReachedDlvPoint(
      String grno, String indentId, String tripid) async {
    loadingAlertService.showLoading();

    try {
      // Position position = await Geolocator.getCurrentPosition(
      //   locationSettings: const LocationSettings(
      //     accuracy: LocationAccuracy.high,
      //     distanceFilter: 0,
      //   ),
      // );
      final position = await LocationService().getCurrentLocation();

      Map<String, String> params = {
        "prmusercode": savedUser.usercode.toString(),
        "prmbranchcode": savedUser.loginbranchcode.toString(),
        "prmtripid": tripid,
        "prmgrno": grno,
        "prmindentid": indentId,
        "prmreachedlat": position.latitude.toString(),
        "prmreachedlong": position.longitude.toString(),
        "prmsessionid": savedUser.sessionid.toString(),
      };

      printParams(params);
      viewModel.updateDriverReachedDlvPoint(params);
    } finally {
      loadingAlertService.hideLoading();
    }
  }

  Future<void> updatePickupDepartedPosition(
      String grno, String tripid, String jobid) async {
    loadingAlertService.showLoading();

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          // accuracy: LocationAccuracy.high,
          accuracy: LocationAccuracy.medium,
          distanceFilter: 0,
        ),
      );

      Map<String, dynamic> params = {
        "prmusercode": savedUser.usercode.toString(),
        "prmbranchcode": savedUser.loginbranchcode.toString(),
        "prmtripid": tripid,
        "prmgrno": grno,
        "prmpickuplat": position.latitude.toString(),
        "prmpickuplong": position.longitude.toString(),
        "prmjobid": int.parse(jobid),
        "prmsessionid": savedUser.sessionid.toString(),
      };

      printParams(params);
      viewModel.updatePickupDepartedPosition(params);
    } finally {
      loadingAlertService.hideLoading();
    }
  }

  // getBookingMenuCodeFromCompAccPara() {
  //   Map<String, String> params = {
  //     "prmvarname": "GLMDBOOKINGMENUCODE",
  //     "prmcompanyid": savedLogin.companyid.toString(),
  //   };

  //   printParams(params);
  //   _baseRepo.getValueFromCompAccPara(params);
  // }

  // filterList(Filter filter) {
  //   switch (filter) {
  //     case Filter.all:
  //       filteredList = List.from(deliveryDetailList);
  //       setState(() {});
  //       break;
  //     case Filter.pending:
  //       debugPrint("Pending");
  //       filteredList = List.from(deliveryDetailList.where((e) =>
  //           e.deliverystatus == 'P' ||
  //           e.pickupstatus == 'P' ||
  //           e.reversepickupstatus == 'P'));
  //       setState(() {});
  //       break;
  //     case Filter.delivered:
  //       debugPrint("Delivery");
  //       break;
  //     case Filter.pickup:
  //       debugPrint("Pickup");
  //       break;
  //     case Filter.undelivered:
  //       debugPrint("Un-Delivery");
  //       break;
  //     case Filter.reversepickup:
  //       debugPrint("Reverse Pickup");
  //       break;
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isSmallDevice = screenWidth <= 360;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: CommonColors.colorPrimary,
        title: Text(
          'Trip# ${widget.tripModel.tripid}',
          style: TextStyle(
              color: CommonColors.White, fontSize: isSmallDevice ? 18 : 20),
        ),
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.arrow_back,
              color: CommonColors.White,
              size: isSmallDevice ? 25 : 30,
            )),
        actions: [
          InkWell(
            onTap: () async {
              // Get.to(OsmMapScreen(
              //   model: widget.tripModel,
              // ));
              // Get.to(MapViewPage(
              //   model: widget.tripModel,
              // ));

             
               if (enableGoogleAPI) {
                await Get.to(() => MapViewPage(model: widget.tripModel));
              } else {
               await Get.to( () => OsmMapScreen(model: widget.tripModel),);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Image.asset(
                "assets/images/map.png",
                height: isSmallDevice ? 25 : 35,
              ),
            ),
          ),
        ],
      ),
      body: widget.tripModel == null
          ? Scaffold(
              body: Center(
              child: Text(
                "data not  found ".toUpperCase(),
                style:
                    TextStyle(color: CommonColors.successColor, fontSize: 20),
              ),
            ))
          : Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: isSmallDevice ? 8 : 10, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Consignments Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Consignments (${widget.tripModel.noofconsign})',
                        style: TextStyle(
                          fontSize: isSmallDevice ? 16 : 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      // GestureDetector(
                      //   onTap: () {
                      //     showMenu(
                      //         initialValue: 1,
                      //         context: context,
                      //         position:
                      //             const RelativeRect.fromLTRB(1, 120, 0.5, 0),
                      //         popUpAnimationStyle: const AnimationStyle(
                      //             curve: Curves.easeInCirc,

                      //             ),
                      //             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      //         items: [
                      //           PopupMenuItem(
                      //             child: const Text("All"),
                      //             onTap: () {
                      //               filterList(Filter.all);
                      //             },
                      //           ),
                      //           PopupMenuItem(
                      //             child: const Text("Pending"),
                      //             onTap: () {
                      //               filterList(Filter.pending);
                      //             },
                      //           ),
                      //           PopupMenuItem(
                      //             child: const Text("Delivery"),
                      //             onTap: () {
                      //               filterList(Filter.delivered);
                      //             },
                      //           ),
                      //           PopupMenuItem(
                      //             child: const Text("Un-Delivery"),
                      //             onTap: () {
                      //               filterList(Filter.undelivered);
                      //             },
                      //           ),
                      //           PopupMenuItem(
                      //             child: const Text("Pickup"),
                      //             onTap: () {
                      //               filterList(Filter.pickup);
                      //             },
                      //           ),
                      //           PopupMenuItem(
                      //             child: const Text("Reverse Pickup"),
                      //             onTap: () {
                      //               filterList(Filter.reversepickup);
                      //             },
                      //           ),
                      //         ]);
                      //   },
                      //   child: const Icon(
                      //     Symbols.filter_list_rounded,
                      //   ),
                      // )
                    ],
                  ),
                  const SizedBox(height: 16),
                  // filteredList.isNotEmpty
                  deliveryDetailList.isNotEmpty
                      ? Expanded(
                          child: RefreshIndicator(
                            onRefresh: refreshScreen,
                            backgroundColor: CommonColors.colorPrimary,
                            color: CommonColors.White,
                            child: Container(
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
                              child: ListView.builder(
                                itemCount: deliveryDetailList.length,
                                itemBuilder: (context, index) {
                                  var data = deliveryDetailList[index];

                                  return DeliveryDetailTile(
                                      model: data,
                                      currentDeliveryModel: deliveryModel,
                                      listLength: deliveryDetailList.length,
                                      index: index,
                                      onRefresh: refreshScreen,
                                      menuList: menuList,
                                      updateDriverPosition: updateDriverReached,
                                      updateDriverReachedDlvPoint:
                                          updateDriverReachedDlvPoint,
                                      updatePickupDepartedPosition:
                                          updatePickupDepartedPosition);
                                },
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Column(
                            children: [
                              Lottie.asset(
                                'assets/map_blue.json',
                                height: 100,
                              ),
                              const Text(
                                "No Data Found",
                                style: TextStyle(
                                    fontWeight: FontWeight.w200, fontSize: 18),
                              )
                            ],
                          ),
                        )
                ],
              ),
            ),
    );
  }
}
