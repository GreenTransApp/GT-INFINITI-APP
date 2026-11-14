import 'package:flutter/material.dart';
import 'package:gtlmd/common/Colors.dart';
import 'package:gtlmd/common/Toast.dart';
import 'package:gtlmd/common/Utils.dart';
import 'package:gtlmd/common/alertBox/loadingAlertWithCancel.dart';
import 'package:gtlmd/design_system/size_config.dart';
import 'package:gtlmd/pages/trips/tripDetail/Model/tripModel.dart';
import 'package:gtlmd/pages/trips/tripOrderSummary/accordianTile.dart';
import 'package:gtlmd/pages/trips/tripOrderSummary/model/consignmentModel.dart';
import 'package:gtlmd/pages/trips/tripOrderSummary/model/tripOrderSummaryModel.dart';
import 'package:gtlmd/pages/trips/tripOrderSummary/tripOrderSummaryViewModel.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:timeline_tile/timeline_tile.dart';

// ignore: must_be_immutable
class TripORdersSummary extends StatefulWidget {
  TripModel tripModel;
  TripORdersSummary({required this.tripModel, super.key});

  @override
  State<TripORdersSummary> createState() => _TripORdersSummaryState();
}

class _TripORdersSummaryState extends State<TripORdersSummary> {
  TripOrderSummaryViewModel viewModel = TripOrderSummaryViewModel();
  late LoadingAlertService loadingAlertService;
  TripOrderSummaryModel ordersList = TripOrderSummaryModel();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => loadingAlertService = LoadingAlertService(context: context));
    setObservers();
    getOrdersList();
    // createDummyData();
  }

  // createDummyData() {
  //   ordersList = [
  //     TripOrderSummaryModel(
  //       grno: "GRN-001",
  //       ordertype: "Pickup",
  //       dispatchdt: "2023-01-01",
  //       dispatchtime: "10:00 AM",
  //       orderStatus: "Pending",
  //     ),
  //     TripOrderSummaryModel(
  //       grno: "GRN-002",
  //       ordertype: "Delivery",
  //       dispatchdt: "2023-01-01",
  //       dispatchtime: "10:00 AM",
  //       orderStatus: "Delivered",
  //     ),
  //     TripOrderSummaryModel(
  //       grno: "GRN-003",
  //       ordertype: "Reverse Pickup",
  //       dispatchdt: "2023-01-01",
  //       dispatchtime: "10:00 AM",
  //       orderStatus: "Picked",
  //     ),
  //     TripOrderSummaryModel(
  //       grno: "GRN-001",
  //       ordertype: "Pickup",
  //       dispatchdt: "2023-01-01",
  //       dispatchtime: "10:00 AM",
  //       orderStatus: "Un-Picked",
  //     ),
  //     TripOrderSummaryModel(
  //       grno: "GRN-002",
  //       ordertype: "Delivery",
  //       dispatchdt: "2023-01-01",
  //       dispatchtime: "10:00 AM",
  //       orderStatus: "Un-Delivered",
  //     ),
  //     TripOrderSummaryModel(
  //       grno: "GRN-003",
  //       ordertype: "Reverse Pickup",
  //       dispatchdt: "2023-01-01",
  //       dispatchtime: "10:00 AM",
  //       orderStatus: "Pending",
  //     ),
  //   ];
  //   setState(() {});
  // }

  setObservers() {
    viewModel.viewDialog.stream.listen((showLoading) {
      if (showLoading) {
        loadingAlertService.showLoading();
      } else {
        loadingAlertService.hideLoading();
      }
    });

    viewModel.errorDialog.stream.listen((errMsg) {
      failToast(errMsg);
    });

    viewModel.tripOrderSummary.stream.listen((list) {
      ordersList = list;
      setState(() {});
    });
  }

  getOrdersList() {
    Map<String, String> params = {
      "prmcompanyid": savedLogin.companyid.toString(),
      "prmusercode": savedUser.usercode.toString(),
      "prmbranchcode": savedUser.loginbranchcode.toString(),
      "prmemployeeid": savedUser.employeeid.toString(),
      "prmsessionid": savedUser.sessionid.toString(),
      "prmtripid": widget.tripModel.tripid.toString(),
      "prmlogindivisionid": savedUser.logindivisionid.toString(),
      "prmmenucode": "",
      "prmplanningid": widget.tripModel.planningid.toString(),
      "prmmanifestno": widget.tripModel.manifestno.toString()
    };
    viewModel.getOrdersList(params);
  }

  Widget infoItem(
      String heading,
      String value,
      //  String status,
      CrossAxisAlignment crossAxisAlignment) {
    Color textColor = CommonColors.colorPrimary!;
    // if (status == "Picked") {
    //   textColor = CommonColors.colorPrimary!;
    // } else if (status == "Un-Picked") {
    //   textColor = CommonColors.colorPrimary!;
    // } else if (status == "Delivered") {
    //   textColor = CommonColors.green600!;
    // } else if (status == "Un-Delivered") {
    //   textColor = CommonColors.red600!;
    // } else if (status == "Pending") {
    //   textColor = CommonColors.amber500!;
    // }
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          heading,
          style: const TextStyle(
              color: CommonColors.appBarColor, fontWeight: FontWeight.normal),
        ),
        Text(
          value,
          style: const TextStyle(
              color: CommonColors.appBarColor, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget orderInfo(ConsignmentModel model, int index) {
    // Color backgroundColor = CommonColors.colorPrimary!.withAlpha((0.2 * 255).round());
    // Color dotColor = CommonColors.colorPrimary!.withAlpha((0.2 * 255).round());

    Color backgroundColor =
        CommonColors.colorPrimary!.withAlpha((0.2 * 255).round());
    Color dotColor = CommonColors.colorPrimary!.withAlpha((0.2 * 255).round());
    String status = "";
    if (model.consignmenttype == "R") {
      switch (model.reversepickupstatus) {
        case "U":
          status = "Un-Picked";
          dotColor = CommonColors.colorPrimary!;
          // cardBorderColor = CommonColors.colorPrimary!;
          backgroundColor =
              CommonColors.colorPrimary!.withAlpha((0.1 * 255).round());
          // statusIcon = Icons.cancel;
          // statusIconColor = CommonColors.colorPrimary!;
          break;
        case "D":
          status = "Picked";
          dotColor = CommonColors.colorPrimary!;
          backgroundColor =
              CommonColors.colorPrimary!.withAlpha((0.1 * 255).round());
          // cardBgColor =
          //     CommonColors.colorPrimary!.withAlpha((0.1 * 255).round());
          // statusIcon = Icons.check_circle;
          // statusIconColor = CommonColors.colorPrimary!;
          break;
        case "P":
          status = "Pending";
          dotColor = CommonColors.colorPrimary!;
          backgroundColor = CommonColors.colorPrimary!;
          // cardBorderColor = CommonColors.colorPrimary!;
          // cardBgColor =
          //     CommonColors.colorPrimary!.withAlpha((0.1 * 255).round());
          // statusIcon = Icons.access_time;
          // statusIconColor = CommonColors.colorPrimary!;
          break;
      }
    } else if (model.consignmenttype == 'D' || model.consignmenttype == 'U') {
      switch (model.deliverystatus) {
        case "U":
          status = "Undelivered";
          dotColor = CommonColors.red500!;
          backgroundColor = CommonColors.red50!;
          // statusIcon = Icons.cancel;
          // statusIconColor = CommonColors.red500!;
          break;
        case "D":
          status = "Delivered";
          dotColor = CommonColors.green500!;
          backgroundColor = CommonColors.green50!;
          // statusIcon = Icons.check_circle;
          // statusIconColor = CommonColors.green500!;
          break;
        case "P":
          status = "Pending";
          dotColor = CommonColors.amber500!;
          backgroundColor = CommonColors.amber50!;
          // statusIcon = Icons.access_time;
          // statusIconColor = CommonColors.amber500!;
          break;
      }
    } else {
      switch (model.pickupstatus) {
        // case "U":
        // status = "Undelivered";
        //   dotColor = CommonColors.red500!;
        //   cardBorderColor = CommonColors.red500!;
        //   cardBgColor = CommonColors.red50!;
        //   statusIcon = Icons.cancel;
        //   statusIconColor = CommonColors.red500!;
        //   break;
        case "D":
          status = "Picked";
          dotColor = CommonColors.green500!;
          backgroundColor = CommonColors.green50!;
          // statusIcon = Icons.check_circle;
          // statusIconColor = CommonColors.green500!;
          break;
        case "P":
          status = "Pending";
          dotColor = CommonColors.amber500!;
          backgroundColor = CommonColors.amber50!;
          // statusIcon = Icons.access_time;
          // statusIconColor = CommonColors.amber500!;
          break;
        default:
          status = "Pending";
          dotColor = CommonColors.amber500!;
          backgroundColor = CommonColors.amber50!;
          break;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TimelineTile(
        isFirst: index == 0,
        isLast: index == ordersList.consignments!.length - 1,
        beforeLineStyle: LineStyle(
          color: dotColor,
          thickness: 2,
        ),
        afterLineStyle: LineStyle(
          color: dotColor,
          thickness: 2,
        ),
        indicatorStyle: IndicatorStyle(
          height: 15,
          width: 15,
          indicator: Container(
            // margin: const EdgeInsets.only(top: 20),
            height: 30,
            width: 30,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
        endChild: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
                color: backgroundColor,
                border: Border.all(width: 1, color: backgroundColor),
                borderRadius: BorderRadiusGeometry.circular(12)),
            child: Column(
              children: [
                Row(children: [
                  Text(
                    "${(index + 1).toString()}#",
                    style: const TextStyle(
                        color: CommonColors.appBarColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  )
                ]),
                const SizedBox(
                  height: 8,
                ),
                Row(
                  children: [
                    Expanded(
                        child: infoItem(
                      "GR-NO",
                      model.grno.toString(),
                      // model.orderStatus.toString(),
                      CrossAxisAlignment.start,
                    )),
                    Expanded(
                        child: infoItem(
                      "Date",
                      model.dispatchdt.toString(),
                      // model.orderStatus.toString(),
                      CrossAxisAlignment.end,
                    )),
                  ],
                ),
                const SizedBox(
                  height: 16,
                ),
                Row(
                  children: [
                    Expanded(
                        child: infoItem(
                      "Order Type",
                      model.consignmenttypeview.toString(),
                      // model.ordertype.toString(),
                      // model.orderStatus.toString(),
                      CrossAxisAlignment.start,
                    )),
                    Expanded(
                        child: infoItem(
                      "Status",
                      status,
                      CrossAxisAlignment.end,
                    )),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRiderVehicleSection() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
          vertical: SizeConfig.smallVerticalPadding,
          horizontal: SizeConfig.smallHorizontalPadding),
      margin: const EdgeInsets.only(bottom: 1),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.person, color: Colors.blue[600], size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RIDER',
                      style: TextStyle(
                        fontSize: SizeConfig.smallTextSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ordersList.manifests.first.rider,
                      style: TextStyle(
                        fontSize: SizeConfig.mediumTextSize,
                        fontWeight: FontWeight.bold,
                        color: CommonColors.appBarColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.largeVerticalSpacing),
          Container(
            color: CommonColors.grey200,
            height: 1,
            margin: const EdgeInsets.symmetric(vertical: 4),
          ),
          SizedBox(height: SizeConfig.largeVerticalSpacing),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.amber[100],
                  borderRadius: BorderRadius.circular(SizeConfig.largeRadius),
                ),
                child: Icon(Icons.directions_car,
                    color: Colors.amber[600], size: 20),
              ),
              SizedBox(width: SizeConfig.mediumHorizontalSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VEHICLE',
                      style: TextStyle(
                        fontSize: SizeConfig.smallTextSize,
                        fontWeight: FontWeight.w600,
                        color: CommonColors.grey400,
                      ),
                    ),
                    SizedBox(height: SizeConfig.smallVerticalSpacing),
                    Text(
                      '${ordersList.manifests.first.vehicleNo} • ${ordersList.manifests.first.vehicleType}',
                      style: TextStyle(
                        fontSize: SizeConfig.mediumTextSize,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _buildStatCard(
                  'Total Pieces',
                  ordersList.manifests.first.noOfConsignment.toString(),
                  Colors.blue,
                  Symbols.package),
              _buildStatCard(
                  'Total Weight',
                  ordersList.manifests.first.totalWeight.toString(),
                  Colors.purple,
                  Symbols.weight),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            color: Colors.grey[200],
            height: 1,
            margin: const EdgeInsets.symmetric(vertical: 4),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, Color color, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withAlpha((0.2 * 255).toInt()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccordionSection({
    required String title,
    required List<Widget> children,
  }) {
    return AccordionTile(title: title, children: children);
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsignmentCard(ConsignmentModel consignment, int index) {
    // final isDelivered = consignment['status'] == 'delivered';
    CommonColors.colorPrimary!.withAlpha((0.2 * 255).round());
    Color statusColor = CommonColors.colorPrimary!;
    String status = "";
    if (consignment.consignmenttype == "R") {
      switch (consignment.reversepickupstatus) {
        case "U":
          status = "Un-Picked";
          statusColor = CommonColors.colorPrimary!;
          break;
        case "D":
          status = "Picked";
          statusColor = CommonColors.colorPrimary!;
          break;
        case "P":
          status = "Pending";
          statusColor = CommonColors.amber500!;
          break;
        default:
          status = "Pending";
          statusColor = CommonColors.amber500!;
          break;
      }
    } else if (consignment.consignmenttype == 'D' ||
        consignment.consignmenttype == 'U') {
      switch (consignment.deliverystatus) {
        case "U":
          status = "Undelivered";
          statusColor = CommonColors.dangerColor!;
          break;
        case "D":
          status = "Delivered";
          statusColor = CommonColors.successColor!;
          break;
        case "P":
          status = "Pending";
          statusColor = CommonColors.amber500!;
          break;
        default:
          status = "Pending";
          statusColor = CommonColors.amber500!;
          break;
      }
    } else {
      switch (consignment.pickupstatus) {
        case "U":
          status = "Un-Picked";
          statusColor = CommonColors.colorPrimary!;
          break;
        case "D":
          status = "Picked";
          statusColor = CommonColors.colorPrimary!;
          break;
        case "P":
          status = "Pending";
          statusColor = CommonColors.amber500!;
          break;
        default:
          status = "Pending";
          statusColor = CommonColors.amber500!;
          break;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Consignment #: ${consignment.grno}',
                            style: TextStyle(
                              fontSize: SizeConfig.smallTextSize,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                          SizedBox(
                              height: SizeConfig.extraSmallVerticalSpacing),
                          RichText(
                            text: TextSpan(
                              style: TextStyle(
                                  fontSize: SizeConfig.smallTextSize,
                                  color: Colors.grey[700]),
                              children: [
                                const TextSpan(text: 'Pcs: '),
                                TextSpan(
                                  text: '${consignment.pcs}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                const TextSpan(text: ' | Weight: '),
                                TextSpan(
                                  text: '${consignment.weight} kg',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                const TextSpan(text: ' | '),
                                TextSpan(
                                  text:
                                      'Stop ${index + 1} ${consignment.consignmenttypeview}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
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
                SizedBox(height: SizeConfig.smallVerticalSpacing),
                Text(
                  'Consignee: ${consignment.contactperson} | Address: ${consignment.address}',
                  style: TextStyle(
                      fontSize: SizeConfig.smallTextSize,
                      color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            status == "Delivered" || status == "Picked"
                                ? Icons.check_circle
                                : status == "Undelivered" ||
                                        status == "Un-Picked"
                                    ? Icons.cancel
                                    : Icons.info,
                            color: statusColor,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              status == "Delivered"
                                  ? 'Delivered To ${consignment.contactperson.toString().split(' ')[0]}'
                                  : status,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Status
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.horizontalPadding,
                vertical: SizeConfig.verticalPadding),
            color: Colors.grey[50],
            child: Row(
              children: [
                Visibility(
                  visible: !isNullOrEmpty(consignment.podimage),
                  child: const Text(
                    'POD : ',
                  ),
                ),
                SizedBox(
                  width: SizeConfig.extraSmallHorizontalSpacing,
                ),
                Visibility(
                  visible: !isNullOrEmpty(consignment.podimage),
                  child: GestureDetector(
                    onTap: () {
                      showDialogWithImage(context, consignment.podimage!);
                    },
                    child: Icon(
                      Symbols.link,
                      size: SizeConfig.extraLargeIconSize,
                      color: CommonColors.blue600,
                    ),
                  ),
                ),
                SizedBox(
                  width: SizeConfig.mediumHorizontalSpacing,
                ),
                Visibility(
                  visible: !isNullOrEmpty(consignment.signimage),
                  child: const Text(
                    'SIGN : ',
                  ),
                ),
                SizedBox(
                  width: SizeConfig.extraSmallHorizontalSpacing,
                ),
                Visibility(
                  visible: !isNullOrEmpty(consignment.signimage),
                  child: GestureDetector(
                    onTap: () {
                      showDialogWithImage(context, consignment.signimage!);
                    },
                    child: Icon(
                      Symbols.link,
                      size: SizeConfig.extraLargeIconSize,
                      color: CommonColors.blue600,
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsignmentList() {
    return Container(
      color: Colors.grey[50],
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.horizontalPadding,
          vertical: SizeConfig.verticalPadding),
      child: Column(
        children: ordersList.consignments
            .asMap()
            .entries
            .map((entry) => _buildConsignmentCard(entry.value, entry.key))
            .toList()
            .expand((card) => [card, const SizedBox(height: 8)])
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: CommonColors.colorPrimary,
          foregroundColor: CommonColors.White,
          title: Text(
            "Trip Order Summary",
            style: TextStyle(color: CommonColors.White),
          ),
        ),
        body: ordersList.manifests.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildSummarySection(),
                    _buildRiderVehicleSection(),
                    SizedBox(height: SizeConfig.smallVerticalSpacing),
                    _buildAccordionSection(
                      title: 'Vehicle Readings',
                      children: [
                        _buildDetailRow(
                            'Start Reading (km)',
                            isNullOrEmpty(ordersList
                                    .manifests.first.startReadingKm
                                    .toString())
                                ? "Pending"
                                : ordersList.manifests.first.startReadingKm
                                    .toString()),
                        _buildDetailRow(
                            'End Reading (km)',
                            isNullOrEmpty(ordersList
                                    .manifests.first.endReadingKm
                                    .toString())
                                ? "Pending"
                                : ordersList.manifests.first.endReadingKm
                                    .toString()),
                        _buildDetailRow(
                            'Distance Travelled (km)',
                            isNullOrEmpty(ordersList
                                    .manifests.first.distanceTravelledKm
                                    .toString())
                                ? "Pending"
                                : ordersList.manifests.first.distanceTravelledKm
                                    .toString()),
                      ],
                    ),
                    _buildAccordionSection(
                      title: 'Route Details',
                      children: [
                        _buildDetailRow(
                            'Total Distance',
                            isNullOrEmpty(ordersList.manifests.first.distance
                                    .toString())
                                ? 'N/A'
                                : ordersList.manifests.first.distance
                                    .toString()),
                        _buildDetailRow(
                            'Consignments',
                            isNullOrEmpty(ordersList
                                    .manifests.first.noOfConsignment
                                    .toString())
                                ? 'N/A'
                                : ordersList.manifests.first.noOfConsignment
                                    .toString()),
                        _buildDetailRow(
                            'Total Weight',
                            isNullOrEmpty(ordersList.manifests.first.totalWeight
                                    .toString())
                                ? 'N/A'
                                : ordersList.manifests.first.totalWeight
                                    .toString()),
                        // _buildDetailRow(
                        //     'Delivered',
                        //     isNullOrEmpty(ordersList.manifests.first.delivered
                        //             .toString())
                        //         ? 'N/A'
                        //         : ordersList.manifests.first.delivered
                        //             .toString()),
                        // _buildDetailRow(
                        //     'Pending',
                        //     isNullOrEmpty(ordersList.manifests.first.pending
                        //             .toString())
                        //         ? 'N/A'
                        //         : ordersList.manifests.first.pending
                        //             .toString()),
                      ],
                    ),
                    _buildAccordionSection(
                      title: 'Additional Info',
                      children: [
                        _buildDetailRow(
                            'Manifest No',
                            isNullOrEmpty(ordersList.manifests.first.manifestNo
                                    .toString())
                                ? 'N/A'
                                : ordersList.manifests.first.manifestNo
                                    .toString()),
                        _buildDetailRow(
                            'Manifest Time',
                            isNullOrEmpty(ordersList
                                    .manifests.first.manifestDateTime
                                    .toString())
                                ? 'N/A'
                                : ordersList.manifests.first.manifestDateTime
                                    .toString()),
                        _buildDetailRow(
                            'Dispatch Time',
                            isNullOrEmpty(ordersList
                                    .manifests.first.dispatchDateTime
                                    .toString())
                                ? 'N/A'
                                : ordersList.manifests.first.dispatchDateTime
                                    .toString()),
                        _buildDetailRow(
                            'Remarks',
                            isNullOrEmpty(ordersList.manifests.first.remarks
                                    .toString())
                                ? 'N/A'
                                : ordersList.manifests.first.remarks
                                    .toString()),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      padding: EdgeInsets.symmetric(
                          horizontal: SizeConfig.smallHorizontalPadding,
                          vertical: SizeConfig.smallVerticalPadding),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.local_shipping,
                                  color: Colors.green[600], size: 20),
                              SizedBox(
                                  width: SizeConfig.smallHorizontalSpacing),
                              Text(
                                'Stops',
                                style: TextStyle(
                                  fontSize: SizeConfig.largeTextSize,
                                  fontWeight: FontWeight.bold,
                                  color: CommonColors.appBarColor,
                                ),
                              ),
                              SizedBox(
                                  width: SizeConfig.smallHorizontalSpacing),
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: EdgeInsets.symmetric(
                                    horizontal:
                                        SizeConfig.smallHorizontalPadding,
                                    vertical:
                                        SizeConfig.extraSmallVerticalPadding),
                                decoration: BoxDecoration(
                                  color: Colors.green[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isNullOrEmpty(ordersList
                                          .manifests.first.noOfConsignment
                                          .toString())
                                      ? 'N/A'
                                      : ordersList
                                          .manifests.first.noOfConsignment
                                          .toString(),
                                  style: TextStyle(
                                    fontSize: SizeConfig.mediumTextSize,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _buildConsignmentList(),
                    // ListView.builder(
                    //   itemBuilder: (context, index) {
                    //     return orderInfo(ordersList.consignments[index], index);
                    //   },
                    //   itemCount: ordersList.consignments.length ?? 0,
                    // ),
                  ],
                ),
              )
        //  ListView.builder(
        //   itemBuilder: (context, index) {
        //     return orderInfo(ordersList[index], index);
        //   },
        //   itemCount: ordersList.length ?? 0,
        // ),
        );
  }
}
