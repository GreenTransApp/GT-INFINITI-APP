import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/route_manager.dart';
import 'package:get/state_manager.dart';
import 'package:gtlmd/common/Colors.dart';
import 'package:gtlmd/common/Toast.dart';
import 'package:gtlmd/common/Utils.dart';
import 'package:gtlmd/common/alertBox/loadingAlertWithCancel.dart';
import 'package:gtlmd/design_system/size_config.dart';
import 'package:gtlmd/pages/midmile/midMileTripDetail/midMileTripDetail.dart';
import 'package:gtlmd/pages/midmile/midMileTripList/midMileTripListModel.dart';
import 'package:gtlmd/pages/midmile/midMileTripList/midMileTripListViewModel.dart';
import 'package:gtlmd/pages/midmile/midMileTripList/updateMidMileTripInfo/updateMidMileTripInfo.dart';
import 'package:lottie/lottie.dart';

class MidMileTripList extends StatefulWidget {
  const MidMileTripList({super.key});

  @override
  State<MidMileTripList> createState() => MidMileTripListState();
}

class MidMileTripListState extends State<MidMileTripList> {
  List<MidMileTripListModel> tripsList = List.empty(growable: true);
  List<MidMileTripListModel> filterList = List.empty(growable: true);
  final TextEditingController _searchController = TextEditingController();
  String query = '';
  final MidMileTripListViewModel viewModel = MidMileTripListViewModel();
  late LoadingAlertService loadingAlertService;

  Future<Position> getCurrentLocation() async {
    return await Geolocator.getCurrentPosition();
  }

  void generateDummyData() {
    tripsList.add(MidMileTripListModel(
        tripid: 1,
        tripdetailid: 1,
        startdt: "2026-09-09",
        starttime: "12:01",
        vehiclestartkm: 12,
        vehiclestartlocation: "Test",
        pickuplatposition: 12.0,
        pickuplongposition: 12.0,
        startreadingimageid: "123",
        tripstart: 'Y'));
    tripsList.add(MidMileTripListModel(
        tripid: 2,
        tripdetailid: 2,
        startdt: "2026-09-09",
        starttime: "12:01",
        vehiclestartkm: 12,
        vehiclestartlocation: "Working",
        pickuplatposition: 12.0,
        pickuplongposition: 12.0,
        startreadingimageid: "123",
        tripstart: 'Y'));
    tripsList.add(MidMileTripListModel(
        tripid: 3,
        tripdetailid: 3,
        startdt: "2026-09-09",
        starttime: "12:01",
        vehiclestartkm: 12,
        vehiclestartlocation: "OR",
        pickuplatposition: 12.0,
        pickuplongposition: 12.0,
        startreadingimageid: "123",
        tripstart: 'Y'));
    tripsList.add(MidMileTripListModel(
        tripid: 0,
        tripdetailid: 0,
        startdt: "2026-09-09",
        starttime: "12:01",
        vehiclestartkm: 12,
        vehiclestartlocation: "Not",
        pickuplatposition: 12.0,
        pickuplongposition: 12.0,
        startreadingimageid: "123",
        tripstart: 'N'));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadingAlertService = LoadingAlertService(context: context);
    });
    setObserver();
    // getMidMileTripsList();
    // generateDummyData();
  }

  setObserver() {
    viewModel.loadingDialog.stream.listen((show) {
      show
          ? loadingAlertService.showLoading()
          : loadingAlertService.hideLoading();
    });

    viewModel.errorDialog.stream.listen((error) {
      failToast(error);
    });

    viewModel.midMileTripsList.stream.listen((listData) {
      if (listData.isNotEmpty) {
        setState(() {
          tripsList = listData;
          filterList = listData;
        });
      } else {
        tripsList.clear();
        filterList.clear();
      }
    });
    viewModel.validateTripLiveData.stream.listen((resp) {
      if (resp.commandstatus == 1) {
        startTrip(resp);
      } else {
        failToast(resp.commandmessage ?? "Something went wrong");
      }
    });
  }

  void updateSearch(String newQuery) {
    List<MidMileTripListModel> newMatchQuery = [];

    if (newQuery.isEmpty) {
      setState(() {
        query = '';
        filterList = tripsList;
      });
    } else {
      for (var trip in tripsList) {
        if ((trip.tripid
                    ?.toString()
                    .toLowerCase()
                    .contains(newQuery.toLowerCase()) ??
                false) ||
            (trip.origin?.toLowerCase().contains(newQuery.toLowerCase()) ??
                false) ||
            (trip.destination?.toLowerCase().contains(newQuery.toLowerCase()) ??
                false) ||
            (trip.vehicleno?.toLowerCase().contains(newQuery.toLowerCase()) ??
                false) ||
            (trip.placementid
                    ?.toString()
                    .toLowerCase()
                    .contains(newQuery.toLowerCase()) ??
                false) ||
            (trip.drivername?.toLowerCase().contains(newQuery.toLowerCase()) ??
                false)) {
          newMatchQuery.add(trip);
        }
      }
      setState(() {
        query = newQuery;
        filterList = newMatchQuery;
      });
    }
  }

  Future<void> onRefresh() async {
    await getMidMileTripsList();
  }

  Future<void> getMidMileTripsList() async {
    Map<String, String> params = {
      "prmcompanyid": savedUser.companyid.toString(),
      "prmloginbranchcode": savedUser.loginbranchcode.toString(),
      "prmlogindivisionid": savedUser.logindivisionid.toString(),
      "prmdrivercode": savedUser.drivercode.toString(),
      "prmusercode": savedUser.usercode.toString(),
      "prmmenucode": "GTAPP_MIDMILETRIPLIST",
      "prmfromdt": convert2SmallDateTime(dashboardFromDt.toString()),
      "prmtodt": convert2SmallDateTime(dashboardToDt.toString()),
      "prmsessionid": savedUser.sessionid.toString(),
    };
    await viewModel.getMidMileTripsList(params);
  }

  Future<void> _ValidateTripBeforeStart(MidMileTripListModel trip) async {
    Map<String, String> params = {
      "prmusercode": savedUser.usercode.toString(),
      "prmtripid": trip.tripid.toString(),
      "prmbranchcode": savedUser.loginbranchcode.toString(),
      "prmdivisionid": savedUser.logindivisionid.toString(),
      "prmvehiclecode": trip.vehiclecode.toString(),
      "prmsessionid": savedUser.sessionid.toString(),
    };
    viewModel.ValidateTripBeforeStart(params);
  }

  startTrip(MidMileTripListModel trip) {
    openUpdateMidMileTripInfo(
        context, trip, onRefresh, MidMileTripStatus.START_TRIP);
  }

  closeTrip(MidMileTripListModel trip) {
    openUpdateMidMileTripInfo(
        context, trip, onRefresh, MidMileTripStatus.CLOSE_TRIP);
      
  }

  Widget _infoTile(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor:
              CommonColors.colorPrimary!.withAlpha((0.2 * 255).toInt()),
          child: Icon(
            icon,
            size: 18,
            color: CommonColors.colorPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget tripsListCard(MidMileTripListModel trip) {
    return GestureDetector(
      onTap: () {
        if (trip.tripstart == 'Y') {
          // Get.to(MidMileTripDetail(
          //     tripid: trip.tripid!, tripdetailid: trip.tripdetailid!));
          Get.to(() => MidMileTripDetail(
              tripid: trip.tripid!,
              tripdetailid: trip.tripdetailid!))?.then((_) {
            onRefresh();
            authService.validateDevice(context);
          });
        } else {
          failToast("Please start the trip to view details");
        }
      },
      child: Card(
          color: CommonColors.white!,
          elevation: 3,
          margin: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SizeConfig.largeRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Header
              Container(
                padding: EdgeInsets.symmetric(
                    vertical: SizeConfig.verticalPadding,
                    horizontal: SizeConfig.horizontalPadding),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(SizeConfig.largeRadius),
                        topRight: Radius.circular(SizeConfig.largeRadius)),
                    gradient: RadialGradient(radius: 7, colors: [
                      CommonColors.colorPrimary!.withAlpha((0.2 * 255).toInt()),
                      CommonColors.white!
                    ])),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: SizeConfig.extraSmallHorizontalPadding),
                      decoration: BoxDecoration(
                          color: CommonColors.white,
                          border: Border.all(
                              color: CommonColors.colorPrimary!, width: 0.2),
                          borderRadius: BorderRadius.all(
                              Radius.circular(SizeConfig.smallRadius))),
                      child: Text(
                        "Trip ID : ${trip.tripid}",
                        style: TextStyle(
                          fontSize: SizeConfig.smallTextSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: SizeConfig.extraSmallHorizontalPadding),
                      decoration: BoxDecoration(
                          color: CommonColors.white,
                          border: Border.all(
                              color: CommonColors.colorPrimary!, width: 0.2),
                          borderRadius: BorderRadius.all(
                              Radius.circular(SizeConfig.smallRadius))),
                      child: Text(
                        "Trip Detail ID : ${trip.tripdetailid}",
                        style: TextStyle(
                          fontSize: SizeConfig.smallTextSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              /// Origin -> Destination
              Container(
                padding: EdgeInsets.symmetric(
                    vertical: SizeConfig.verticalPadding,
                    horizontal: SizeConfig.smallHorizontalPadding),
                margin: EdgeInsets.symmetric(
                    horizontal: SizeConfig.extraSmallHorizontalSpacing),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        trip.origin ?? "-",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.arrow_forward),
                    ),
                    Expanded(
                      child: Text(
                        trip.destination ?? "-",
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.flag,
                      color: Colors.red,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              /// Details
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.smallHorizontalPadding),
                child: Row(
                  children: [
                    Expanded(
                      child: _infoTile(
                        Icons.local_shipping_outlined,
                        "Vehicle",
                        trip.vehicleno ?? "-",
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _infoTile(Icons.speed, "Vehicle Start KM",
                          "${trip.vehiclestartkm.toString()} km"),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.smallHorizontalPadding),
                child: Row(
                  children: [
                    Expanded(
                      child: _infoTile(Icons.badge_outlined, "Placement",
                          trip.placementid.toString()),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _infoTile(
                        Icons.phone,
                        "Mobile",
                        trip.mobileno ?? "-",
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              if (trip.tripstart == 'N') ...[
                // InkWell(
                //   onTap: () => startTrip(trip),
                //   borderRadius: BorderRadius.circular(8),
                //   child: Container(

                //     padding: EdgeInsets.symmetric(
                //       horizontal: SizeConfig.mediumHorizontalSpacing,
                //       vertical: SizeConfig.smallVerticalSpacing,
                //     ),
                //     decoration: BoxDecoration(
                //       color: CommonColors.colorPrimary,
                //       borderRadius: BorderRadius.circular(8),
                //     ),
                //     child: Row(
                //       mainAxisSize: MainAxisSize.min,
                //       children: [
                //         Icon(
                //           Icons.play_arrow_rounded,
                //           color: Colors.white,
                //           size: SizeConfig.extraLargeIconSize,
                //         ),
                //         const SizedBox(width: 6),
                //         const Text(
                //           "Start Trip",
                //           style: TextStyle(
                //             color: Colors.white,
                //             fontWeight: FontWeight.w600,
                //           ),
                //         ),
                //       ],
                //     ),
                //   ),
                // ),

                Row(
                  children: [
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.symmetric(
                            horizontal: SizeConfig.extraSmallHorizontalPadding,
                            vertical: SizeConfig.verticalPadding),
                        decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(SizeConfig.smallRadius),
                            gradient: LinearGradient(colors: [
                              CommonColors.red600!,
                              CommonColors.colorPrimary!
                            ])),
                        width: double.infinity,
                        child: ElevatedButton(
                          //  onPressed:() => startTrip(trip),
                          onPressed: () => _ValidateTripBeforeStart(trip),
                          style: ElevatedButton.styleFrom(
                            // backgroundColor: CommonColors.colorPrimary,
                            // foregroundColor: CommonColors.White,
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            disabledBackgroundColor: CommonColors.grey300,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ), // Disable if not punched in
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.play_arrow_rounded,
                                size: SizeConfig.largeIconSize,
                                color: CommonColors.white,
                              ),
                              SizedBox(width: SizeConfig.horizontalPadding),
                              Text(
                                "Start Trip",
                                style: TextStyle(
                                    fontSize: SizeConfig.smallTextSize,
                                    color: CommonColors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // if (trip.tripstart == 'Y') ...[

              Visibility(
                visible: trip.tripstart == 'Y',
                child: Container(
                  decoration: BoxDecoration(
                      color: CommonColors.grey!.withOpacity(0.1),
                      border: Border(
                          top: BorderSide(
                              color: CommonColors.grey!.withOpacity(0.3),
                              width: 1))),
                  padding: EdgeInsets.symmetric(
                      vertical: SizeConfig.smallVerticalPadding,
                      horizontal: SizeConfig.smallHorizontalPadding),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Started : ${trip.startdatetime ?? "-"}",
                              // "Started :test",
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Visibility(
                visible: trip.showclosetripbtn == 'Y',
                child: Container(
                  margin: EdgeInsets.symmetric(
                      horizontal: SizeConfig.extraSmallHorizontalPadding,
                      vertical: SizeConfig.extraSmallVerticalPadding),
                  decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(SizeConfig.smallRadius),
                      gradient: LinearGradient(colors: [
                        CommonColors.red600!,
                        CommonColors.red500!
                      ])),
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => closeTrip(trip),
                    style: ElevatedButton.styleFrom(
                      // backgroundColor: CommonColors.colorPrimary,
                      // foregroundColor: CommonColors.White,
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      disabledBackgroundColor: CommonColors.grey300,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ), // Disable if not punched in
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.play_arrow_rounded,
                          size: SizeConfig.largeIconSize,
                          color: CommonColors.white,
                        ),
                        SizedBox(width: SizeConfig.horizontalPadding),
                        Text(
                          "Close Trip",
                          style: TextStyle(
                              fontSize: SizeConfig.smallTextSize,
                              color: CommonColors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            // ],
          )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: Colors.white,
      backgroundColor: CommonColors.colorPrimary,
      onRefresh: onRefresh,
      child: Scaffold(
        body: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SizeConfig.largeRadius),
          ),
          // color: CommonColors.grey200,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                    color: CommonColors.colorPrimary2,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(SizeConfig.largeRadius),
                        topRight: Radius.circular(SizeConfig.largeRadius))),
                padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.horizontalPadding,
                    vertical: SizeConfig.verticalPadding),
                child: TextField(
                  controller: _searchController,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  cursorColor: CommonColors.appBarColor,
                  obscureText: false,
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.search,
                      color: CommonColors.appBarColor,
                      size: SizeConfig.largeIconSize,
                    ),
                    suffixIcon: IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchController.clear();
                          updateSearch('');
                        });
                      },
                      icon: _searchController.text.isNotEmpty
                          ? const Icon(Icons.clear)
                          : const Icon(
                              Icons.clear,
                              color: Colors.transparent,
                            ),
                    ),
                    hintText: 'Search',
                    filled: true,
                    fillColor: CommonColors.white,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(10.0), // Set the desired radius
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: updateSearch,
                ),
              ),
              Expanded(
                child: Container(
                  child: (filterList.isEmpty) == true
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Lottie.asset("assets/emptyDelivery.json",
                                      height: 150),
                                  Text(
                                    "No Trips",
                                    style: TextStyle(
                                        fontSize: SizeConfig.mediumTextSize,
                                        color: CommonColors.appBarColor),
                                  )
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: filterList.length,
                          itemBuilder: (context, index) {
                            return tripsListCard(filterList[index]);
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    // return Scaffold(
    //   body: RefreshIndicator(
    //     onRefresh: onRefresh,
    //     child: tripsList.isEmpty
    //         ? ListView(
    //             physics: const AlwaysScrollableScrollPhysics(),
    //             children: [
    //               SizedBox(height: MediaQuery.of(context).size.height * 0.25),
    //               Lottie.asset("assets/emptyDelivery.json", height: 150),
    //               const Center(
    //                 child: Text(
    //                   'No Trips Found',
    //                   style: TextStyle(
    //                       color: CommonColors.appBarColor,
    //                       fontWeight: FontWeight.w400),
    //                 ),
    //               )
    //             ],
    //           )
    // : ListView.builder(
    //     physics: const AlwaysScrollableScrollPhysics(),
    //     itemCount: tripsList.length,
    //     itemBuilder: (context, index) {
    //       return tripsListCard(tripsList[index]);
    //     },
    //   ),
    //   ),
    // );
  }
}
