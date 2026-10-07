import 'dart:async';
import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gtlmd/base/BaseRepository.dart';
import 'package:gtlmd/bottomSheet/socialShareBottomSheet/socialShareBottomSheet.dart';
import 'package:gtlmd/common/Colors.dart';
import 'package:gtlmd/common/Utils.dart';
import 'package:gtlmd/common/alertBox/commonAlertDialog.dart';
import 'package:gtlmd/common/alertBox/loadingAlertWithCancel.dart';

import 'package:gtlmd/common/commonModel/pageLinkJsonParams.dart';
import 'package:gtlmd/common/toast.dart';
import 'package:gtlmd/design_system/size_config.dart';
import 'package:gtlmd/main.dart';
import 'package:gtlmd/pages/consignmentEnquiry/consignmentEnquiryPage.dart';
import 'package:gtlmd/pages/deliveryDetail/Model/deliveryDetailModel.dart';
import 'package:gtlmd/pages/deliveryDetail/Model/lmdMenuModel.dart';
import 'package:gtlmd/pages/otexPickupScreen/OtexPickupScreen.dart';
import 'package:gtlmd/pages/pickup/pickup.dart';
import 'package:gtlmd/pages/podEntry/podEntry.dart';
import 'package:gtlmd/pages/rejectPickup/rejectPickup.dart';
import 'package:gtlmd/pages/reversePickup/reversePickup.dart';
import 'package:gtlmd/pages/trips/tripDetail/Model/currentDeliveryModel.dart';
import 'package:gtlmd/pages/unDelivery/unDelivery.dart';
import 'package:gtlmd/tiles/addressCard.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:url_launcher/url_launcher.dart';

enum MenuTags { DELIVERY, UNDELIVERY, PICKUP, REVERSE_PICKUP }

class DeliveryDetailTile extends StatefulWidget {
  final DeliveryDetailModel model;
  final CurrentDeliveryModel currentDeliveryModel;
  final int index;
  final int listLength;
  final Function() onRefresh;
  final Future<void> Function(
          String grno, String indentId, String tripid, String jobid)
      updateDriverPosition;
  final Future<void> Function(String grno, String indentId, String tripid)
      updateDriverReachedDlvPoint;
  final Future<void> Function(String grno, String tripid, String jobid)
      updatePickupDepartedPosition;
  final List<LmdMenuModel> menuList;

  const DeliveryDetailTile({
    super.key,
    required this.model,
    required this.currentDeliveryModel,
    required this.index,
    required this.listLength,
    required this.onRefresh,
    required this.updateDriverPosition,
    required this.updateDriverReachedDlvPoint,
    required this.updatePickupDepartedPosition,
    this.menuList = const [],
  });

  @override
  State<DeliveryDetailTile> createState() => _RouteDetailTileState();
}

class _RouteDetailTileState extends State<DeliveryDetailTile> {
  bool isFirst = false;
  bool isLast = false;
  bool showActionBtn = true;
  DeliveryDetailModel modelDetail = DeliveryDetailModel();
  CurrentDeliveryModel currentDelivery = CurrentDeliveryModel();
  int listValue = 0;
  int listIndex = 0;
  late Color dotColor;
  late Color cardBgColor;
  late Color cardHeaderColor;
  late IconData statusIcon;
  late Color statusIconColor;
  String? status;
  final BaseRepository _baseRepo = BaseRepository();
  List<StreamSubscription> _subscription = [];
  bool showAllCardInfo = true;
  bool showCngeAddress = false;
  late LoadingAlertService loadingAlertService;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => loadingAlertService = LoadingAlertService(context: context));
    modelDetail = widget.model;
    currentDelivery = widget.currentDeliveryModel;
    if (modelDetail.showdeparted == 'N' && modelDetail.pickupstatus == 'D') {
      showAllCardInfo = false;
    }
    setObservers();
    // showPickupCardInfo = modelDetail.showdeparted == 'Y' ? true : false;
    // if (modelDetail.showdeparted == 'Y' &&
    //     modelDetail.consignmenttype == 'P' &&
    //     modelDetail.pickupstatus == 'P') {
    //   showAllCardInfo = true;
    // } else if (modelDetail.consignmenttype == 'D' ||
    //     modelDetail.consignmenttype == 'U' &&
    //         modelDetail.consignmenttype == 'R') {
    //   showAllCardInfo == true;
    // } else {
    //   showAllCardInfo = false;
    // }
    setState(() {
      // if (widget.model.deliverystatus == 'Y') {
      if (widget.model.deliverystatus == 'P') {
        showActionBtn = true;
      } else {
        showActionBtn = false;
      }

      checkConsignTypeAndStatus();
    });
    listValue = widget.listLength;
    listIndex = widget.index;

    if (listValue == 1 && listIndex == 0) {
      isFirst = true;
      isLast = true;
    } else if (listIndex == 0) {
      isFirst = true;
      isLast = false;
    } else if (listIndex == listValue - 1) {
      isFirst = false;
      isLast = true;
    } else {
      isFirst = false;
      isLast = false;
    }
  }

  setObservers() {
    _subscription.add(_baseRepo.viewDialog.stream.listen((showLoading) {
      if (showLoading) {
        loadingAlertService.showLoading();
      } else {
        loadingAlertService.hideLoading();
      }
    }));
  }

  @override
  void didUpdateWidget(covariant DeliveryDetailTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.model != widget.model) {
      setState(() {
        modelDetail = widget.model;
        if (widget.model.deliverystatus == 'P') {
          showActionBtn = true;
        } else {
          showActionBtn = false;
        }
        checkConsignTypeAndStatus();
        if (modelDetail.showdeparted == 'N' &&
            modelDetail.pickupstatus == 'D') {
          showAllCardInfo = false;
        }
      });
    }
  }

  checkConsignTypeAndStatus() {
    if (modelDetail.consignmenttype == "R") {
      switch (modelDetail.reversepickupstatus) {
        case "U":
          status = "Un-Picked";
          dotColor = CommonColors.colorPrimary!;
          cardBgColor =
              CommonColors.colorPrimary!.withAlpha((0.1 * 255).round());
          cardHeaderColor = CommonColors.colorPrimary!;
          statusIcon = Icons.cancel;
          statusIconColor = CommonColors.colorPrimary!;
          break;
        case "D":
          status = "Picked";
          dotColor = CommonColors.colorPrimary!;
          cardBgColor =
              CommonColors.colorPrimary!.withAlpha((0.1 * 255).round());
          cardHeaderColor = CommonColors.colorPrimary!;
          statusIcon = Icons.check_circle;
          statusIconColor = CommonColors.colorPrimary!;
          break;
        case "P":
          status = "Pending";
          dotColor = CommonColors.colorPrimary!;
          cardBgColor =
              CommonColors.colorPrimary!.withAlpha((0.1 * 255).round());
          cardHeaderColor = CommonColors.colorPrimary!;
          statusIcon = Icons.access_time;
          statusIconColor = CommonColors.colorPrimary!;
          break;
      }
    } else if (modelDetail.consignmenttype == 'D' ||
        modelDetail.consignmenttype == 'U') {
      switch (modelDetail.deliverystatus) {
        case "U":
          status = "Undelivered";
          dotColor = CommonColors.red500!;
          cardBgColor = CommonColors.red50!;
          cardHeaderColor = CommonColors.red!;
          statusIcon = Icons.cancel;
          statusIconColor = CommonColors.red500!;
          break;
        case "D":
          status = "Delivered";
          dotColor = CommonColors.green500!;
          cardBgColor = CommonColors.green50!;
          cardHeaderColor = CommonColors.green500!;
          statusIcon = Icons.check_circle;
          statusIconColor = CommonColors.green500!;
          break;
        case "P":
          status = "Pending";
          dotColor = CommonColors.amber500!;
          cardBgColor = CommonColors.amber50!;
          cardHeaderColor = CommonColors.pendingColor!;
          statusIcon = Icons.access_time;
          statusIconColor = CommonColors.amber500!;
          break;
      }
    } else {
      switch (modelDetail.pickupstatus) {
        case "U":
          status = "Rejected";
          dotColor = CommonColors.red500!;
          // cardBorderColor = CommonColors.red500!;
          cardBgColor = CommonColors.red50!;
          cardHeaderColor = CommonColors.red!;
          statusIcon = Icons.cancel;
          statusIconColor = CommonColors.red500!;
          break;
        case "D":
          status = "Picked";
          dotColor = CommonColors.green500!;
          cardBgColor = CommonColors.green50!;
          cardHeaderColor = CommonColors.green500!;
          statusIcon = Icons.check_circle;
          statusIconColor = CommonColors.green500!;
          break;
        case "P":
          status = "Pending";
          dotColor = CommonColors.amber500!;
          cardBgColor = CommonColors.amber50!;
          cardHeaderColor = CommonColors.pendingColor!;
          statusIcon = Icons.access_time;
          statusIconColor = CommonColors.amber500!;
          break;
        default:
          status = "Pending";
          dotColor = CommonColors.amber500!;
          cardBgColor = CommonColors.amber50!;
          cardHeaderColor = CommonColors.pendingColor!;
          statusIcon = Icons.access_time;
          statusIconColor = CommonColors.amber500!;
          break;
      }
    }
  }

  _makePhoneCall(String? mobileNum) async {
    try {
      var url = Uri.parse("tel:$mobileNum");
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        failToast("Somethinig went wrong, please try again later");
      }
    } catch (err) {
      failToast(err.toString());
    }
  }

  getBookingPrintLink(String menuCode) async {
    if (isNullOrEmpty(menuCode)) {
      menuCode = "GTAPP_PICKUPBOOKING";
    }
    try {
      Map<String, String> params = {
        "prmconnstring": savedUser.companyid.toString(),
        // "prmgrno": widget.model.generatedGr.toString(),
        "prmgrno": modelDetail.generatedGr.toString(),
        "prmusercode": savedUser.usercode.toString(),
        // "prmmenucode": "GTAPP_BOOKING",
        "prmmenucode": menuCode.toString(),
        // "prmmenucode": menuCode.toString(),
        "prmsessionid": savedUser.sessionid.toString(),
      };
      String url = await _baseRepo.getBookingPrint(params);
      if (!isNullOrEmpty(url) && url.contains('http')) {
        launchUrl(Uri.parse(url));
      } else {
        failToast(url ?? "Invalid URL Please Contact To Administrator.");
      }
    } catch (error) {
      failToast(error.toString());
    }
  }

  Future<void> navigateToLocation({
    required String latitude,
    required String longitude,
  }) async {
    final Uri googleMapsUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=$latitude,$longitude'
      '&travelmode=driving',
    );

    try {
      await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
    } on Exception catch (e) {
      print('Error launching Google Maps: $e');
    }
  }

  updateDriverReached() async {
    await widget.updateDriverPosition(
        modelDetail.grno.toString(),
        modelDetail.transactionid.toString(),
        modelDetail.tripid.toString(),
        modelDetail.jobid.toString());
  }

  updateDriverReachedDlvLocation() async {
    await widget.updateDriverReachedDlvPoint(modelDetail.grno.toString(),
        modelDetail.transactionid.toString(), modelDetail.tripid.toString());
  }

  updatePickupDepartedPosition() async {
    await widget.updatePickupDepartedPosition(modelDetail.grno.toString(),
        modelDetail.tripid.toString(), modelDetail.jobid.toString());
  }

  void _toggleShowAllPickupDetail() {
    setState(() {
      showAllCardInfo = !showAllCardInfo;
    });
  }


  @override
  Widget build(BuildContext context) {
    return TimelineTile(
      isFirst: isFirst,
      isLast: isLast,
      alignment: TimelineAlign.manual,
      lineXY: 0.05,
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
          height: 15,
          width: 15,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
      ),
      endChild: Padding(
        padding: EdgeInsets.symmetric(
            vertical: SizeConfig.verticalPadding,
            horizontal: SizeConfig.horizontalPadding),
        child: modelDetail.directdelivery == "Y"
            ? directDeliveryConsignmentCard()
            : consignmentCard(),
      ),
    );
  }

  Widget consignmentCard() {
    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with ID and Status

          Container(
            // color: Colors.blue,
            padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.smallHorizontalPadding,
                vertical: SizeConfig.smallVerticalPadding),
            decoration: BoxDecoration(
              color: cardHeaderColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12.0),
              ),
            ),

            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    '${widget.model.grno}/${isNullOrEmpty(widget.model.orderid.toString()) ? "" : widget.model.orderid}',
                    style: TextStyle(
                      color: CommonColors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: SizeConfig.mediumTextSize,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Stop badge next to GR No
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.smallHorizontalPadding,
                          ),
                          decoration: BoxDecoration(
                            color: CommonColors.white!,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            'Stop ${modelDetail.sequenceno} / ${modelDetail.consignmenttypeview}',
                            style: TextStyle(
                              fontSize: SizeConfig.mediumTextSize,
                              fontWeight: FontWeight.bold,
                              color: cardHeaderColor,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      PopupMenuButton<String>(
                        icon: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: CommonColors.white!, // Border color
                                width: 2.0, // Border thickness
                              ),
                            ),
                            child: Icon(
                              Icons.more_vert,
                              color: CommonColors.white,
                            )),
                        onSelected: (value) {
                          switch (value) {
                            case 'enquiry':
                              // Get.to(OtexPickupScreen(
                              //   transactionId: isNullOrEmpty(widget
                              //           .model.transactionid
                              //           .toString())
                              //       ? '0'
                              //       : widget.model.transactionid
                              //           .toString(),
                              //   grno: widget.model.grno.toString(),
                              //   orderid: isNullOrEmpty(widget
                              //           .model.orderid
                              //           .toString())
                              //       ? '0'
                              //       : widget.model.orderid.toString(),
                              //   isReadOnly: true,
                              // ));

                              LmdMenuModel? targetMenu;
                              try {
                                targetMenu = widget.menuList.firstWhere(
                                    (element) =>
                                        element.tag?.toString() ==
                                        MenuTags.PICKUP.name.toString());
                                {
                                  {
                                    menuCode = targetMenu.menuCode.toString();
                                  }
                                }
                              } catch (e) {
                                targetMenu = null;
                              }
                              if (isNullOrEmpty(widget.model.generatedGr)) {
                                failToast("Consignment# is not  found.");
                                return;
                              } else {
                                Get.to(ConsignmentEnquiryPage(
                                  consignmentNo:
                                      widget.model.generatedGr.toString(),
                                  tripid: widget.model.tripid ?? 0,
                                ));
                              }
                              break;
                            case 'share':
                              LmdMenuModel? targetMenu;
                              try {
                                targetMenu = widget.menuList.firstWhere(
                                    (element) =>
                                        element.tag?.toString() ==
                                        MenuTags.PICKUP.name.toString());
                                {
                                  {
                                    menuCode = targetMenu.menuCode.toString();
                                  }
                                }
                              } catch (e) {
                                targetMenu = null;
                              }
                              // getBookingPrintLink(menuCode);
        //                         shareAlertDialog(context, "ALERT!", "Are you sure you want to logout?",""
        // );
                              showSocialShareBottomSheetBottomSheet(context, widget.model.generatedGr.toString(),menuCode);
                              break;
                            case 'map':
                              {
                                // we have to pass lattitude and longitude of the consignment.
                                // used static for testing.
                                navigateToLocation(
                                    latitude:
                                        widget.model.deliverylat.toString(),
                                    longitude:
                                        widget.model.deliverylong.toString());
                              }
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          if (widget.model.consignmenttype == 'P' &&
                              status == 'Picked')
                            const PopupMenuItem(
                              value: 'enquiry',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.contact_support_rounded,
                                    size: 20,
                                  ),
                                  SizedBox(
                                    width: 4,
                                  ),
                                  Text('Enquiry')
                                ],
                              ),
                            ),
                          if (widget.model.consignmenttype == 'P' &&
                              status == 'Picked')
                            const PopupMenuItem(
                              value: 'share',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.share_rounded,
                                    size: 20,
                                  ),
                                  SizedBox(
                                    width: 4,
                                  ),
                                  Text('Share')
                                ],
                              ),
                            ),
                          const PopupMenuItem(
                            value: 'map',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  size: 20,
                                ),
                                SizedBox(
                                  width: 4,
                                ),
                                Text('Map')
                              ],
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

          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.horizontalPadding,
                vertical: SizeConfig.extraSmallVerticalSpacing),
            child: Column(
              children: [
                Visibility(
                  visible: showAllCardInfo,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Row(
                              //   children: [
                              //     Visibility(
                              //       visible: widget.model.reached == 'N',
                              //       child: GestureDetector(
                              //         onTap: () {
                              //           updateDriverReached();
                              //         },
                              //         child: Row(
                              //           mainAxisAlignment:
                              //               MainAxisAlignment.spaceEvenly,
                              //           children: [
                              //             Container(
                              //               margin: EdgeInsets.only(
                              //                   right: SizeConfig
                              //                       .horizontalPadding),
                              //               padding: EdgeInsets.symmetric(
                              //                 horizontal: SizeConfig
                              //                     .smallHorizontalSpacing,
                              //                 vertical: 5,
                              //               ),
                              //               decoration: BoxDecoration(
                              //                   color:
                              //                       CommonColors.colorPrimary2!,
                              //                   borderRadius:
                              //                       BorderRadius.circular(16)),
                              //               child: Text(
                              //                 "Pending",
                              //                 style: TextStyle(
                              //                     fontWeight: FontWeight.w600,
                              //                     fontSize:SizeConfig.extraSmallTextSize,
                              //                     color: CommonColors.white),
                              //               ),
                              //             ),
                              //             Container(
                              //               padding: EdgeInsets.symmetric(
                              //                 horizontal: SizeConfig
                              //                     .extraSmallHorizontalSpacing,
                              //                 vertical: 4,
                              //               ),
                              //               decoration: BoxDecoration(
                              //                   color: CommonColors.white!,
                              //                   border: Border.all(
                              //                       color:
                              //                           CommonColors.grey400!),
                              //                   borderRadius:
                              //                       BorderRadius.circular(16)),
                              //               child:  Row(
                              //                 children: [
                              //                    Icon(
                              //     Icons.circle,
                              //     color: CommonColors.colorPrimary2,
                              //     size: SizeConfig.extraSmallIconSize,
                              //   ),
                              //                   Text(
                              //                     "Arrived At",
                              //                     style: TextStyle(
                              //                         fontWeight: FontWeight.w600,
                              //                         fontSize: SizeConfig.extraSmallTextSize,
                              //                         color:
                              //                             CommonColors.appBarColor),
                              //                   ),
                              //                 ],
                              //               ),
                              //             ),
                              //           ],
                              //         ),
                              //       ),
                              //     ),
                              //     Visibility(
                              //       visible: widget.model.reached == 'Y',
                              //       child: Row(
                              //         children: [
                              //           Icon(
                              //             Icons.check_circle,
                              //             color: CommonColors.green600,
                              //           ),
                              //           const SizedBox(
                              //             width: 8,
                              //           ),
                              //           const Text("Reached")
                              //         ],
                              //       ),
                              //     ),
                              //   ],
                              // ),
                              // SizedBox(
                              //   height: SizeConfig.smallVerticalSpacing,
                              // ),
                              isNullOrEmpty(modelDetail.undeliverreason)
                                  ? const SizedBox.shrink()
                                  : Text(
                                      'Reason: ${modelDetail.undeliverreason}',
                                      style: TextStyle(
                                        fontSize: SizeConfig.smallTextSize,
                                        fontWeight: FontWeight.w800,
                                        color: cardHeaderColor,
                                      )),
                            ],
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal:
                                  SizeConfig.extraSmallHorizontalSpacing,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                                border: Border.all(color: cardHeaderColor),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(20))),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.circle,
                                  color: statusIconColor,
                                  size: SizeConfig.extraSmallIconSize,
                                ),
                                Text(
                                  status.toString(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: statusIconColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // SizedBox(height: SizeConfig.smallVerticalSpacing),

                  // Consignee Details
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.smallHorizontalPadding,
                            vertical: SizeConfig.extraSmallVerticalPadding),
                        decoration: BoxDecoration(
                          color: CommonColors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: modelDetail.consignmenttype == 'P'
                                        ? 'Consignor : '
                                        : 'Consignee : ',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: SizeConfig.extraSmallTextSize,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                  TextSpan(
                                    text: modelDetail.cngename ?? '',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: SizeConfig.smallTextSize,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                               // Consignment Details
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                          Row(
                              children: [
                                // Text(
                                //   modelDetail.cngemobile ?? '—',
                                //   style: TextStyle(
                                //     fontWeight: FontWeight.w600,
                                //     fontSize: SizeConfig.smallTextSize,
                                //   ),
                                // ),
                              Text(
                              // 'Mobile No.',
                              modelDetail.consignmenttype == 'P'
                              ? 'Consignor Mobile No. : '
                              : 'Consignee Mobile No. : ',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: SizeConfig.extraSmallTextSize,
                              ),
                            ),
                            SizedBox(
                                height:
                                    SizeConfig.extraSmallHorizontalSpacing),
                                RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                        color: Colors.black, fontSize: 18),
                                    children: [
                                      TextSpan(
                                        text: '${modelDetail.cngemobile}',
                                        style: TextStyle(
                                           fontSize: SizeConfig.extraSmallTextSize,
                                            color: CommonColors.blue600,
                                            decoration:
                                                TextDecoration.underline),
                                        // Use url_launcher to launch the URL
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () async {
                                            if (status == "Pending" ||
                                                status == "Un-Picked") {
                                              _makePhoneCall(
                                                  modelDetail.cngemobile);
                                            } else {
                                              failToast(
                                                  "consignment already ${status}.");
                                            }
                                          },
                                      ),
                                    ],
                                  ),
                                ),
                              
                              ],
                            ),

                      
                          ],
                        ),
                        
                        SizedBox(height: SizeConfig.extraSmallVerticalSpacing),
                         // Address Card
                        AddressCard(
                            // title: 'Address',
                              title: modelDetail.consignmenttype == 'P'
                                    ? 'Consignor Address: '
                                    : 'Consignee Address: ',
                            address: modelDetail.cngeaddress ?? '',
                            color:
                                statusIconColor.withAlpha((0.1 * 255).toInt())),
                        
                          ],
                        ),
                      ),
                        SizedBox(height: SizeConfig.extraSmallVerticalSpacing),

                      // Consignor Details
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.smallHorizontalPadding,
                            vertical: SizeConfig.extraSmallVerticalPadding),
                        decoration: BoxDecoration(
                          color: CommonColors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: modelDetail.consignmenttype == 'P'
                                        ? 'Consignee : '
                                        : 'Consignor : ',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: SizeConfig.extraSmallTextSize,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                  TextSpan(
                                    text: modelDetail.cngrname ?? '',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: SizeConfig.smallTextSize,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                               // Consignment Details
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                            Text(
                              // 'Mobile No.',
                              modelDetail.consignmenttype == 'P'
                              ? 'Consignee Mobile No.:'
                              : 'Consignor Mobile No.:',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: SizeConfig.extraSmallTextSize,
                              ),
                            ),
                            SizedBox(
                                height:
                                    SizeConfig.extraSmallHorizontalSpacing),
                                RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                        color: Colors.black, fontSize: 18),
                                    children: [
                                      TextSpan(
                                        text: '${modelDetail.cngrmobileno}',
                                        style: TextStyle(
                                              fontSize: SizeConfig.extraSmallTextSize,
                                            color: CommonColors.blue600,
                                            decoration:
                                                TextDecoration.underline),
                                        // Use url_launcher to launch the URL
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () async {
                                            if (status == "Pending" ||
                                                status == "Un-Picked") {
                                              _makePhoneCall(
                                                  modelDetail.cngrmobileno);
                                            } else {
                                              failToast(
                                                  "consignment already ${status}.");
                                            }
                                          },
                                      ),
                                    ],
                                  ),
                                ),
                            
                              ],
                            ),
                            
                            InkWell(
                              onTap: () {
                                setState(() {
                                showCngeAddress = !showCngeAddress;
                                });
                              },
                              child: CircleAvatar(
                              backgroundColor: CommonColors.grey200,
                              child:Icon(Icons.location_on_rounded, color: CommonColors.colorPrimary2, size: SizeConfig.smallIconSize,),),
                            ),
                          ],
                        ),
                        
                        // SizedBox(height: SizeConfig.extraSmallVerticalSpacing),
                         // Address Card
                        Visibility(
                          visible: showCngeAddress,
                          child: Padding(
                            padding:  EdgeInsets.only(top: SizeConfig.extraSmallVerticalSpacing),
                            child: AddressCard(
                                // title: 'Address',
                                  title: modelDetail.consignmenttype == 'P'
                                        ? 'Consignee Address: '
                                        : 'Consignor Address: ',
                                address: modelDetail.cngraddress ?? '',
                                color:
                                    statusIconColor.withAlpha((0.1 * 255).toInt())),
                          ),
                        ),
                        
                          ],
                        ),
                      ),

                      // SizedBox(
                      //   height: SizeConfig.smallVerticalSpacing,
                      // ),

                   
                      Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pcs',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: SizeConfig.smallTextSize,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${modelDetail.pcs}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: SizeConfig.smallTextSize,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                 Text(
                                    'Reference No.',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: SizeConfig.smallTextSize,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isNullOrEmpty(modelDetail.referenceno) ? 'N/A' : '${modelDetail.referenceno}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: SizeConfig.smallTextSize,
                                    ),
                                  ),],
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: SizeConfig.smallVerticalSpacing),
                        
                      // Action Buttons for Pending
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.smallHorizontalPadding,
                            vertical: SizeConfig.extraSmallVerticalPadding),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: CommonColors.grey50!
                            // .withAlpha((0.1 * 255).toInt()),
                            ),
                        child: Row(
                          children: [
                            Expanded(
                                child: Row(
                              children: [
                                // Icon(Icons.watch_later_outlined),
                                Text(
                                  widget.model.reached == 'Y'
                                      ? (modelDetail.reachedatdatetime
                                              ?.toString() ??
                                          '')
                                      : 'Pending',
                                  style: TextStyle(
                                      fontSize: SizeConfig.extraSmallTextSize,
                                      fontWeight: FontWeight.bold),
                                ),
                                if (widget.model.reached != 'Y') ...[
                                  const ImageIcon(
                                      AssetImage('assets/images/loading.png'))
                                  //  AssetImage('assets/images/image.png'))
                                ]
                              ],
                            )),
                            Visibility(
                              visible: modelDetail.reached == 'Y',
                              child: Row(
                                children: [
                                  Text(
                                    'Arrived At',
                                    style: TextStyle(
                                      fontSize: SizeConfig.smallTextSize,
                                      fontWeight: FontWeight.w600,
                                      color: CommonColors.green600,
                                    ),
                                  ),
                                  Icon(
                                    Icons.check_circle,
                                    color: CommonColors.green600,
                                  ),
                                ],
                              ),
                            ),
                            if (modelDetail.reached != 'Y') ...[
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    updateDriverReached();
                                  },
                                  // icon: Icon(Icons.close, size: SizeConfig.mediumIconSize),
                                  icon: const Icon(Icons.arrow_forward_ios),
                                  iconAlignment: IconAlignment.end,
                                  label: Text('Arrived At',
                                      style: TextStyle(
                                          fontSize:
                                              SizeConfig.extraSmallTextSize)),
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                        horizontal:
                                            SizeConfig.smallHorizontalPadding,
                                        vertical:
                                            SizeConfig.smallVerticalPadding),
                                    backgroundColor: CommonColors.colorPrimary2,
                                    foregroundColor: CommonColors.White,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),

                      if (modelDetail.consignmenttype == "D" &&
                          status == "Pending") ...[
                        SizedBox(height: SizeConfig.smallVerticalSpacing),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  LmdMenuModel? targetMenu;
                                  try {
                                    targetMenu = widget.menuList.firstWhere(
                                        (element) =>
                                            element.tag?.toString() ==
                                            MenuTags.UNDELIVERY.name
                                                .toString());
                                    {
                                      menuCode = targetMenu.menuCode.toString();
                                    }
                                  } catch (e) {
                                    targetMenu = null;
                                  }

                                  String fileName =
                                      targetMenu?.fileName?.toLowerCase() ??
                                          'UnDelivery';

                                  if (fileName == 'UnDelivery' ||
                                      fileName == 'undelivery') {
                                    if (widget.model.reached == 'N') {
                                      failToast("Not reached");
                                      return;
                                    }
                                    Get.to(UnDelivery(
                                            deliveryDetailModel: modelDetail))
                                        ?.then((_) {
                                      widget.onRefresh();
                                    });
                                  } else {
                                    failToast("Screen $fileName not mapped.");
                                  }
                                },
                                icon: Icon(Icons.close,
                                    color: CommonColors.red600,
                                    size: SizeConfig.mediumIconSize),
                                label: Text('Undeliver',
                                    style: TextStyle(
                                        color: CommonColors.red600,
                                        fontSize: SizeConfig.smallTextSize)),
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                      vertical:
                                          SizeConfig.extraSmallVerticalSpacing),
                                  backgroundColor: CommonColors.white,
                                  foregroundColor: CommonColors.White,
                                  side: BorderSide(
                                    color: CommonColors.red600!, // Border color
                                    width: 3.0, // Border thickness
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  LmdMenuModel? targetMenu;
                                  try {
                                    targetMenu = widget.menuList.firstWhere(
                                        (element) =>
                                            element.tag?.toString() ==
                                            MenuTags.DELIVERY.name.toString());
                                    {
                                      {
                                        menuCode =
                                            targetMenu.menuCode.toString();
                                      }
                                    }
                                  } catch (e) {
                                    targetMenu = null;
                                  }

                                  String fileName =
                                      targetMenu?.fileName?.toLowerCase() ??
                                          'PodEntry';

                                  if (fileName == 'PodEntry' ||
                                      fileName == 'podentry') {
                                    if (widget.model.reached == 'N') {
                                      failToast("Not reached");
                                      return;
                                    }
                                    Get.to(PodEntry(
                                            deliveryDetailModel: modelDetail))
                                        ?.then((_) {
                                      widget.onRefresh();
                                    });
                                  } else {
                                    failToast("Screen $fileName not mapped.");
                                  }
                                },
                                icon: Icon(
                                  Icons.check,
                                  size: SizeConfig.mediumIconSize,
                                  color: CommonColors.green600,
                                ),
                                label: Text('Deliver',
                                    style: TextStyle(
                                        fontSize: SizeConfig.smallTextSize,
                                        color: CommonColors.green600)),
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                      vertical:
                                          SizeConfig.extraSmallVerticalSpacing),
                                  backgroundColor: CommonColors.white,
                                  foregroundColor: CommonColors.White,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: BorderSide(
                                    color:
                                        CommonColors.green600!, // Border color
                                    width: 3.0, // Border thickness
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (modelDetail.consignmenttype == "R" &&
                          modelDetail.pickupstatus == "U") ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  LmdMenuModel? targetMenu;
                                  try {
                                    targetMenu = widget.menuList.firstWhere(
                                        (element) =>
                                            element.tag?.toString() ==
                                            MenuTags.REVERSE_PICKUP.name
                                                .toString());
                                    {
                                      {
                                        menuCode =
                                            targetMenu.menuCode.toString();
                                      }
                                    }
                                  } catch (e) {
                                    targetMenu = null;
                                  }

                                  String fileName =
                                      targetMenu?.fileName?.toLowerCase() ??
                                          'ReversePickup';

                                  if (fileName == 'ReversePickup' ||
                                      fileName == 'reversepickup') {
                                    if (widget.model.reached == 'N') {
                                      failToast("Not reached");
                                      return;
                                    }
                                    Get.to(ReversePickup(
                                      deliveryDetailModel: modelDetail,
                                    ))?.then((_) {
                                      widget.onRefresh();
                                    });
                                  } else {
                                    failToast("Screen $fileName not mapped.");
                                  }
                                },
                                icon: Icon(
                                  Icons.check,
                                  size: SizeConfig.mediumIconSize,
                                  color: CommonColors.colorPrimary2,
                                ),
                                label: Text('Reverse Pickup',
                                    style: TextStyle(
                                        fontSize: SizeConfig.smallTextSize,
                                        color: CommonColors.colorPrimary2)),
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                      vertical:
                                          SizeConfig.extraSmallVerticalSpacing),
                                  backgroundColor: CommonColors.white,
                                  foregroundColor: CommonColors.White,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  side: BorderSide(
                                    color: CommonColors
                                        .colorPrimary2, // Border color
                                    width: 3.0, // Border thickness
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (modelDetail.consignmenttype == "P" &&
                          (modelDetail.pickupstatus == "P")) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  LmdMenuModel? targetMenu;
                                  try {
                                    targetMenu = widget.menuList.firstWhere(
                                        (element) =>
                                            element.tag?.toString() ==
                                            'rejectpickup');
                                    {
                                      {
                                        menuCode =
                                            targetMenu.menuCode.toString();
                                      }
                                    }
                                  } catch (e) {
                                    targetMenu = null;
                                  }

                                  String fileName =
                                      targetMenu?.fileName ?? 'RejectPickup';

                                  if (fileName == 'RejectPickup') {
                                     if (widget.model.reached == 'N') {
                                      failToast("Not reached");
                                      return;
                                    }
                                    Get.to(RejectPickup(details: widget.model))
                                        ?.then((_) {
                                      widget.onRefresh();
                                    });
                                  } else {
                                    failToast("Screen $fileName not mapped.");
                                  }
                                },
                                icon: Icon(
                                  Icons.close,
                                  size: SizeConfig.mediumIconSize,
                                  color: CommonColors.dangerColor,
                                ),
                                label: Text('Reject',
                                    style: TextStyle(
                                        fontSize: SizeConfig.smallTextSize,
                                        color: CommonColors.dangerColor)),
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                      vertical:
                                          SizeConfig.extraSmallVerticalSpacing),
                                  backgroundColor: CommonColors.white,
                                  foregroundColor: CommonColors.White,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  side: BorderSide(
                                    color: CommonColors
                                        .dangerColor!, // Border color
                                    width: 3.0, // Border thickness
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: SizeConfig.smallHorizontalPadding,
                            ),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  LmdMenuModel? targetMenu;
                                  print(MenuTags.PICKUP.name.toString());
                                  try {
                                    targetMenu = widget.menuList.firstWhere(
                                        (element) =>
                                            element.tag?.toString() ==
                                            MenuTags.PICKUP.name.toString());
                                    {
                                      {
                                        menuCode =
                                            targetMenu.menuCode.toString();
                                      }
                                    }
                                    {}
                                  } catch (e) {
                                    targetMenu = null;
                                  }

                                  String fileName =
                                      targetMenu?.fileName?.toLowerCase() ??
                                          'pickup';

                                  if (fileName == 'OtexPickupScreen' ||
                                      fileName == 'otexpickupscreen') {
                                    if (widget.model.reached == 'N') {
                                      failToast("Not reached");
                                      return;
                                    }
                                    Get.to(
                                      OtexPickupScreen(
                                        transactionId: isNullOrEmpty(widget
                                                .model.transactionid
                                                .toString())
                                            ? '0'
                                            : widget.model.transactionid
                                                .toString(),
                                        grno: widget.model.grno.toString(),
                                        orderid: isNullOrEmpty(
                                                widget.model.orderid.toString())
                                            ? '0'
                                            : widget.model.orderid.toString(),
                                        jobid: isNullOrEmpty(
                                                widget.model.jobid.toString())
                                            ? '0'
                                            : widget.model.jobid.toString(),
                                      ),
                                    )?.then((_) {
                                      widget.onRefresh();
                                    });
                                  } else if (fileName == 'Pickup' ||
                                      fileName == 'pickup') {
                                    if (widget.model.reached == 'N') {
                                      failToast("Not reached");
                                      return;
                                    }
                                    Get.to(Pickup(details: widget.model))
                                        ?.then((_) {
                                      widget.onRefresh();
                                    });
                                  } else {
                                    failToast("Screen $fileName not mapped.");
                                  }
                                },
                                icon: Icon(
                                  Icons.check,
                                  size: SizeConfig.mediumIconSize,
                                  color: CommonColors.colorPrimary2,
                                ),
                                label: Text('Pickup',
                                    style: TextStyle(
                                        fontSize: SizeConfig.smallTextSize,
                                        color: CommonColors.colorPrimary2)),
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                      vertical:
                                          SizeConfig.extraSmallVerticalSpacing),
                                  backgroundColor: CommonColors.white,
                                  foregroundColor: CommonColors.White,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  side: BorderSide(
                                    color: CommonColors
                                        .colorPrimary2!, // Border color
                                    width: 3.0, // Border thickness
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (modelDetail.consignmenttype == "P" &&
                          modelDetail.showdeparted == "Y") ...[
                        SizedBox(height: SizeConfig.smallVerticalSpacing),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: SizeConfig.smallHorizontalPadding,
                              vertical: SizeConfig.extraSmallVerticalPadding),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: CommonColors.grey50!
                              // .withAlpha((0.1 * 255).toInt()),
                              ),
                          child: Row(
                            children: [
                              Expanded(
                                  child:
                                      // Text(
                                      //   modelDetail.pickupdeparted == 'Y' ? modelDetail.pickupdeparteddattime ?? '': 'Pending',
                                      //   style: TextStyle(
                                      //     fontSize: SizeConfig.mediumTextSize,
                                      //     fontWeight: FontWeight.w600,
                                      //     color: CommonColors.colorPrimary,
                                      //   ),
                                      // ),
                                      Row(
                                children: [
                                  // Icon(Icons.watch_later_outlined),
                                  Text(
                                    modelDetail.pickupdeparted == 'Y'
                                        ? (modelDetail.pickupdeparteddattime
                                                ?.toString() ??
                                            '')
                                        : 'Pending',
                                    style: TextStyle(
                                        fontSize: SizeConfig.extraSmallTextSize,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  if (modelDetail.pickupdeparted != 'Y') ...[
                                    const ImageIcon(
                                        AssetImage('assets/images/loading.png'))
                                    //  AssetImage('assets/images/image.png'))
                                  ]
                                ],
                              )),
                              Visibility(
                                visible: widget.model.pickupdeparted == 'Y',
                                child: Row(
                                  children: [
                                    Text(
                                      'Pickup Departed',
                                      style: TextStyle(
                                        fontSize: SizeConfig.smallTextSize,
                                        fontWeight: FontWeight.w600,
                                        color: CommonColors.green600,
                                      ),
                                    ),
                                    Icon(
                                      Icons.check_circle,
                                      color: CommonColors.green600,
                                    ),
                                  ],
                                ),
                              ),
                              if (widget.model.pickupdeparted != 'Y') ...[
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      if (modelDetail.consignmenttype == "P" &&
                                          modelDetail.pickupstatus == "P") {
                                        failToast(
                                            "Please update pickup status the consignment first");
                                        return;
                                      }
                                      updatePickupDepartedPosition();
                                    },
                                    // icon: Icon(Icons.close, size: SizeConfig.mediumIconSize),
                                    icon: const Icon(Icons.arrow_forward_ios),
                                    iconAlignment: IconAlignment.end,
                                    label: Text('Pickup Departed',
                                        style: TextStyle(
                                            fontSize:
                                                SizeConfig.extraSmallTextSize)),
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                          horizontal:
                                              SizeConfig.smallHorizontalPadding,
                                          vertical:
                                              SizeConfig.smallVerticalPadding),
                                      backgroundColor:
                                          CommonColors.colorPrimary2,
                                      foregroundColor: CommonColors.White,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                ),
                              ]
                            ],
                          ),
                        ),
                        SizedBox(height: SizeConfig.smallVerticalSpacing),
                      ] else if (modelDetail.consignmenttype == "P" &&
                          modelDetail.showdeparted == "N") ...[
                        modelDetail.pickupdeparted == 'Y'
                            ? Container(
                                margin: EdgeInsets.symmetric(
                                    vertical:
                                        SizeConfig.extraSmallVerticalSpacing),
                                padding: EdgeInsets.symmetric(
                                    horizontal: SizeConfig.horizontalPadding,
                                    vertical:
                                        SizeConfig.extraSmallVerticalPadding),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    color: CommonColors.grey50!
                                    // .withAlpha((0.1 * 255).toInt()),
                                    ),
                                child: Row(
                                  children: [
                                    Expanded(
                                        child:
                                            // Text(
                                            //   modelDetail.pickupdeparted == 'Y' ? modelDetail.pickupdeparteddattime ?? '': 'Pending',
                                            //   style: TextStyle(
                                            //     fontSize: SizeConfig.mediumTextSize,
                                            //     fontWeight: FontWeight.w600,
                                            //     color: CommonColors.colorPrimary,
                                            //   ),
                                            // ),
                                            Text(
                                      modelDetail.pickupdeparted == 'Y'
                                          ? (modelDetail.pickupdeparteddattime
                                                  ?.toString() ??
                                              '')
                                          : '',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    )),
                                    Visibility(
                                      visible:
                                          modelDetail.pickupdeparted == 'Y',
                                      child: Row(
                                        children: [
                                          Text(
                                            'Pickup Departed',
                                            style: TextStyle(
                                              fontSize:
                                                  SizeConfig.smallTextSize,
                                              fontWeight: FontWeight.w600,
                                              color: CommonColors.green600,
                                            ),
                                          ),
                                          Icon(
                                            Icons.check_circle,
                                            color: CommonColors.green600,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Text(''),
                      ]
                    ],
                  ),
                ),
                Visibility(
                    visible: modelDetail.showdeparted == 'N' &&
                        modelDetail.consignmenttype == 'P' &&
                        modelDetail.pickupstatus == 'D',
                    child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: CommonColors.white
                              ?.withAlpha((0.5 * 255).round()),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                            onPressed: () {
                              _toggleShowAllPickupDetail();
                            },
                            icon: showAllCardInfo
                                ? Icon(
                                    Icons.keyboard_arrow_up_outlined,
                                    size: 25,
                                    color: CommonColors.grey600,
                                  )
                                : Icon(
                                    Icons.keyboard_arrow_down_outlined,
                                    size: 25,
                                    color: CommonColors.grey600,
                                  )))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget directDeliveryConsignmentCard() {
    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with ID and Status

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.horizontalPadding,
                    vertical: SizeConfig.smallVerticalPadding),
                decoration: BoxDecoration(
                  color: cardHeaderColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12.0),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        '${widget.model.grno}/${isNullOrEmpty(widget.model.orderid.toString()) ? "" : widget.model.orderid}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: CommonColors.White,
                          fontSize: SizeConfig.mediumTextSize,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Stop badge next to GR No
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: SizeConfig.smallHorizontalPadding,
                                // vertical: SizeConfig.smallVerticalPadding
                              ),
                              decoration: BoxDecoration(
                                color: CommonColors.white!,
                                // .withAlpha((0.1 * 255).round()),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(
                                'Stop ${modelDetail.sequenceno} / ${modelDetail.consignmenttypeview}',
                                style: TextStyle(
                                  fontSize: SizeConfig.mediumTextSize,
                                  fontWeight: FontWeight.bold,
                                  color: statusIconColor,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          PopupMenuButton<String>(
                            icon: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: CommonColors.white!, // Border color
                                    width: 2.0, // Border thickness
                                  ),
                                ),
                                child: Icon(
                                  Icons.more_vert,
                                  color: CommonColors.white,
                                )),
                            onSelected: (value) {
                              switch (value) {
                                case 'enquiry':
                                  // Get.to(OtexPickupScreen(
                                  //   transactionId: isNullOrEmpty(widget
                                  //           .model.transactionid
                                  //           .toString())
                                  //       ? '0'
                                  //       : widget.model.transactionid
                                  //           .toString(),
                                  //   grno: widget.model.grno.toString(),
                                  //   orderid: isNullOrEmpty(widget
                                  //           .model.orderid
                                  //           .toString())
                                  //       ? '0'
                                  //       : widget.model.orderid.toString(),
                                  //   isReadOnly: true,
                                  // ));

                                  LmdMenuModel? targetMenu;
                                  try {
                                    targetMenu = widget.menuList.firstWhere(
                                        (element) =>
                                            element.tag?.toString() ==
                                            MenuTags.PICKUP.name.toString());
                                    {
                                      {
                                        menuCode =
                                            targetMenu.menuCode.toString();
                                      }
                                    }
                                  } catch (e) {
                                    targetMenu = null;
                                  }

                                  if (isNullOrEmpty(widget.model.generatedGr)) {
                                    failToast("Consignment# is not  found.");
                                    return;
                                  } else {
                                    Get.to(ConsignmentEnquiryPage(
                                      consignmentNo:
                                          widget.model.generatedGr.toString(),
                                      tripid: widget.model.tripid ?? 0,
                                    ));
                                  }
                                  break;
                                case 'share':
                                  LmdMenuModel? targetMenu;
                                  try {
                                    targetMenu = widget.menuList.firstWhere(
                                        (element) =>
                                            element.tag?.toString() ==
                                            MenuTags.PICKUP.name.toString());
                                    {
                                      {
                                        menuCode =
                                            targetMenu.menuCode.toString();
                                      }
                                    }
                                  } catch (e) {
                                    targetMenu = null;
                                  }

                                  getBookingPrintLink(menuCode);
                                  break;
                                case 'map':
                                  {
                                    // we have to pass lattitude and longitude of the consignment.
                                    // used static for testing.
                                    navigateToLocation(
                                        latitude:
                                            widget.model.deliverylat.toString(),
                                        longitude: widget.model.deliverylong
                                            .toString());
                                  }
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              if (widget.model.consignmenttype == 'P' &&
                                  status == 'Picked')
                                const PopupMenuItem(
                                  value: 'enquiry',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.contact_support_rounded,
                                        size: 20,
                                      ),
                                      SizedBox(
                                        width: 4,
                                      ),
                                      Text('Enquiry')
                                    ],
                                  ),
                                ),
                              if (widget.model.consignmenttype == 'P' &&
                                  status == 'Picked')
                                const PopupMenuItem(
                                  value: 'share',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.share_rounded,
                                        size: 20,
                                      ),
                                      SizedBox(
                                        width: 4,
                                      ),
                                      Text('Share')
                                    ],
                                  ),
                                ),
                              const PopupMenuItem(
                                value: 'map',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_rounded,
                                      size: 20,
                                    ),
                                    SizedBox(
                                      width: 4,
                                    ),
                                    Text('Map')
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal:
                                      SizeConfig.extraSmallHorizontalPadding,
                                  vertical:
                                      SizeConfig.extraSmallVerticalPadding),
                              child: Text(
                                "Direct Delivery",
                                style: TextStyle(
                                  fontSize: SizeConfig.smallTextSize,
                                  fontWeight: FontWeight.w500,
                                  color: statusIconColor,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.delivery_dining_outlined,
                              color: statusIconColor,
                              size: SizeConfig.extraLargeIconSize,
                            ),
                          ],
                        ),
                        isNullOrEmpty(modelDetail.undeliverreason)
                            ? const SizedBox.shrink()
                            : Text('Reason: ${modelDetail.undeliverreason}',
                                style: TextStyle(
                                  fontSize: SizeConfig.smallTextSize,
                                  fontWeight: FontWeight.w800,
                                  color: CommonColors.colorPrimary,
                                )),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: SizeConfig.smallVerticalSpacing),

          Padding(
            padding:
                EdgeInsets.symmetric(horizontal: SizeConfig.horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: modelDetail.consignmenttype == 'P'
                            ? 'Consignor : '
                            : 'Consignee : ',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: SizeConfig.smallTextSize,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      TextSpan(
                        text: modelDetail.cngename ?? '',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: SizeConfig.smallTextSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(
                  height: SizeConfig.smallVerticalSpacing,
                ),

                // Address Card
                AddressCard(
                    title: 'Address',
                    address: modelDetail.cngeaddress ?? '',
                    color: statusIconColor.withAlpha((0.1 * 255).toInt())),
                // Consignment Details
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pcs',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: SizeConfig.smallTextSize,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${modelDetail.pcs}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: SizeConfig.smallTextSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mobile No.',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: SizeConfig.smallTextSize,
                            ),
                          ),
                          SizedBox(
                              height: SizeConfig.extraSmallVerticalSpacing),
                          Row(
                            children: [
                              // Text(
                              //   modelDetail.cngemobile ?? '—',
                              //   style: TextStyle(
                              //     fontWeight: FontWeight.w600,
                              //     fontSize: SizeConfig.smallTextSize,
                              //   ),
                              // ),

                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                      color: Colors.black, fontSize: 18),
                                  children: [
                                    TextSpan(
                                      text: '${modelDetail.cngemobile}',
                                      style: TextStyle(
                                          color: CommonColors.blue600,
                                          decoration: TextDecoration.underline),
                                      // Use url_launcher to launch the URL
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () async {
                                          if (status == "Pending" ||
                                              status == "Un-Picked") {
                                            _makePhoneCall(
                                                modelDetail.cngemobile);
                                          } else {
                                            failToast(
                                                "consignment already ${status}.");
                                          }
                                        },
                                    ),
                                  ],
                                ),
                              ),

                              // Visibility(
                              //   visible:
                              //       status == "Pending" || status == "Un-Picked",
                              //   child: const SizedBox(
                              //     width: 10,
                              //   ),
                              // ),
                              // Visibility(
                              //   visible:
                              //       status == "Pending" || status == "Un-Picked",
                              //   child: Container(
                              //     decoration: BoxDecoration(
                              //       color:
                              //           status == "Pending" || status == "Un-Picked"
                              //               ? CommonColors.colorPrimary
                              //               : CommonColors.grey400,
                              //       borderRadius: BorderRadius.circular(
                              //           SizeConfig.extraLargeRadius),
                              //     ),
                              //     width: SizeConfig.extraLargeHorizontalPadding,
                              //     height: SizeConfig.extraLargeVerticalPadding,
                              //     child: Center(
                              //       child: GestureDetector(
                              //           onTap: () {
                              //             if (status == 'Pending' ||
                              //                 status == 'Un-Picked') {
                              //               commonAlertDialog(
                              //                   context,
                              //                   "Make a phone call?",
                              //                   "Are you sure you want to call ${modelDetail.cngemobile}?",
                              //                   "",
                              //                   Icon(Icons.phone_outlined,
                              //                       size: SizeConfig
                              //                           .extraSmallIconSize), () {
                              //                 _makePhoneCall(
                              //                     modelDetail.cngemobile);
                              //               });
                              //             }
                              //           },
                              //           child: Icon(
                              //             Icons.call_outlined,
                              //             color: CommonColors.White,
                              //             size: SizeConfig.smallIconSize,
                              //           )),
                              //     ),
                              //   ),
                              // ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: SizeConfig.smallVerticalSpacing),

                // Action Buttons for Pending
                if (modelDetail.directdelivery == 'Y') ...[
                  SizedBox(height: SizeConfig.smallVerticalSpacing),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig.horizontalPadding,
                        vertical: SizeConfig.extraSmallVerticalPadding),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: CommonColors.white!,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                modelDetail.reached == 'Y'
                                    ? modelDetail.reachedatdatetime.toString()
                                    : 'Pending',
                                style: TextStyle(
                                  fontSize: SizeConfig.extraSmallTextSize,
                                  fontWeight: FontWeight.w600,
                                  color: CommonColors.colorPrimary2,
                                ),
                              ),
                              if (modelDetail.reached != 'Y') ...[
                                const ImageIcon(
                                    AssetImage('assets/images/loading.png'))
                              ]
                            ],
                          ),
                        ),
                        Visibility(
                          visible: widget.model.reached == 'Y',
                          child: Row(
                            children: [
                              Text(
                                'Reached',
                                style: TextStyle(
                                  fontSize: SizeConfig.smallTextSize,
                                  fontWeight: FontWeight.w600,
                                  color: CommonColors.green600,
                                ),
                              ),
                              Icon(
                                Icons.check_circle,
                                color: CommonColors.green600,
                              ),
                            ],
                          ),
                        ),
                        Visibility(
                          visible: widget.model.reached != 'Y',
                          child: Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                updateDriverReached();
                              },
                              // icon: Icon(Icons.close, size: SizeConfig.mediumIconSize),
                              icon: Icon(Icons.arrow_forward_ios_outlined),
                              iconAlignment: IconAlignment.end,
                              label: Text('Arrived At',
                                  style: TextStyle(
                                      fontSize: SizeConfig.extraSmallTextSize)),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                    horizontal:
                                        SizeConfig.smallHorizontalPadding,
                                    vertical: SizeConfig.smallVerticalPadding),
                                backgroundColor: CommonColors.colorPrimary2,
                                foregroundColor: CommonColors.White,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: SizeConfig.smallVerticalSpacing),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig.horizontalPadding,
                        vertical: SizeConfig.extraSmallVerticalPadding),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: CommonColors.white!,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                isNullOrEmpty(modelDetail.pickupstatusupdateon
                                        .toString())
                                    ? 'Pending'
                                    : widget.model.pickupstatusupdateon
                                        .toString(),
                                style: TextStyle(
                                  fontSize: SizeConfig.extraSmallTextSize,
                                  fontWeight: FontWeight.w600,
                                  color: CommonColors.colorPrimary2,
                                ),
                              ),
                              if (isNullOrEmpty(modelDetail.pickupstatusupdateon
                                  .toString())) ...[
                                const ImageIcon(
                                    AssetImage('assets/images/loading.png'))
                              ]
                            ],
                          ),
                        ),
                        if (modelDetail.consignmenttype == "P" &&
                            (modelDetail.pickupstatus == "P")) ...[
                          Expanded(
                            child: Column(
                  
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    LmdMenuModel? targetMenu;
                                    print(MenuTags.PICKUP.name.toString());
                                    try {
                                      targetMenu = widget.menuList.firstWhere(
                                          (element) =>
                                              element.tag?.toString() ==
                                              MenuTags.PICKUP.name
                                                  .toString());
                                      {
                                        {
                                          menuCode =
                                              targetMenu.menuCode.toString();
                                        }
                                      }
                                      {}
                                    } catch (e) {
                                      targetMenu = null;
                                    }
                                
                                    String fileName =
                                        targetMenu?.fileName?.toLowerCase() ??
                                            'pickup';
                                
                                    if (fileName == 'OtexPickupScreen' ||
                                        fileName == 'otexpickupscreen') {
                                      if (widget.model.reached == 'N') {
                                        failToast("Not reached");
                                        return;
                                      }
                                      Get.to(
                                        OtexPickupScreen(
                                          transactionId: isNullOrEmpty(widget
                                                  .model.transactionid
                                                  .toString())
                                              ? '0'
                                              : widget.model.transactionid
                                                  .toString(),
                                          grno: widget.model.grno.toString(),
                                          orderid: isNullOrEmpty(widget
                                                  .model.orderid
                                                  .toString())
                                              ? '0'
                                              : widget.model.orderid
                                                  .toString(),
                                          jobid: isNullOrEmpty(widget
                                                  .model.jobid
                                                  .toString())
                                              ? '0'
                                              : widget.model.jobid.toString(),
                                        ),
                                      )?.then((_) {
                                        widget.onRefresh();
                                      });
                                    } else if (fileName == 'Pickup' ||
                                        fileName == 'pickup') {
                                      if (widget.model.reached == 'N') {
                                        failToast("Not reached");
                                        return;
                                      }
                                      Get.to(Pickup(details: widget.model))
                                          ?.then((_) {
                                        widget.onRefresh();
                                      });
                                    } else {
                                      failToast(
                                          "Screen $fileName not mapped.");
                                    }
                                  },
                                  // icon: Icon(Icons.close, size: SizeConfig.mediumIconSize),
                                  label: Text('Pickup',
                                      style: TextStyle(
                                          color: CommonColors.colorPrimary2,
                                          fontSize:
                                              SizeConfig.extraSmallTextSize)),
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                        horizontal:
                                            SizeConfig.horizontalPadding,
                                        vertical: SizeConfig
                                            .extraSmallVerticalPadding),
                                    backgroundColor: CommonColors.white,
                                    foregroundColor: CommonColors.White,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    side: BorderSide(
                                      color: CommonColors
                                          .colorPrimary2, // Border color
                                      width: 3.0, // Border thickness
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: SizeConfig.extraSmallHorizontalSpacing,
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    LmdMenuModel? targetMenu;
                                    try {
                                      targetMenu = widget.menuList.firstWhere(
                                          (element) =>
                                              element.tag?.toString() ==
                                              'rejectpickup');
                                      {
                                        {
                                          menuCode =
                                              targetMenu.menuCode.toString();
                                        }
                                      }
                                    } catch (e) {
                                      targetMenu = null;
                                    }
                                
                                    String fileName = targetMenu?.fileName ??
                                        'RejectPickup';
                                
                                    if (fileName == 'RejectPickup') {
                                       if (widget.model.reached == 'N') {
                                        failToast("Not reached");
                                        return;
                                      }
                                      Get.to(RejectPickup(
                                              details: widget.model))
                                          ?.then((_) {
                                        widget.onRefresh();
                                      });
                                    } else {
                                      failToast(
                                          "Screen $fileName not mapped.");
                                    }
                                  },
                                  //  icon: Icon(Icons.close, size: SizeConfig.mediumIconSize),
                                  label: Text('Reject',
                                      style: TextStyle(
                                        color: CommonColors.dangerColor,
                                        fontSize:
                                            SizeConfig.extraSmallTextSize,
                                      )),
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                        // vertical:
                                        //     SizeConfig.extraSmallVerticalSpacing,
                                        horizontal: SizeConfig
                                            .extraSmallHorizontalSpacing),
                                    backgroundColor: CommonColors.white,
                                    foregroundColor: CommonColors.White,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    side: BorderSide(
                                      color: CommonColors
                                          .red600!, // Border color
                                      width: 3.0, // Border thickness
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        // Visibility(
                        //   visible:
                        if (modelDetail.consignmenttype == "P" &&
                            (modelDetail.pickupstatus == "D")) ...[
                          // child:
                          Row(
                            children: [
                              Text(
                                'Picked',
                                style: TextStyle(
                                  fontSize: SizeConfig.smallTextSize,
                                  fontWeight: FontWeight.w600,
                                  color: CommonColors.green600,
                                ),
                              ),
                              Icon(
                                Icons.check_circle,
                                color: CommonColors.green600,
                              ),
                              // SizedBox(width: SizeConfig.smallHorizontalPadding),
                            ],
                          ),
                        ]
                        // ),
                      ],
                    ),
                  ),
                  // SizedBox(height: SizeConfig.smallVerticalSpacing),
                  SizedBox(height: SizeConfig.smallVerticalSpacing),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig.horizontalPadding,
                        vertical: SizeConfig.extraSmallVerticalPadding),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: CommonColors.white!,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                modelDetail.pickupdeparted == 'Y'
                                    ? modelDetail.pickupdeparteddattime ?? ''
                                    : 'Pending',
                                style: TextStyle(
                                  fontSize: SizeConfig.extraSmallTextSize,
                                  fontWeight: FontWeight.w600,
                                  color: CommonColors.colorPrimary2,
                                ),
                              ),
                              if (modelDetail.pickupdeparted != 'Y') ...[
                                const ImageIcon(
                                    AssetImage('assets/images/loading.png'))
                              ],
                            ],
                          ),
                        ),
                        Visibility(
                          visible: widget.model.pickupdeparted == 'Y',
                          child: Row(
                            children: [
                              Text(
                                'Pickup Departed',
                                style: TextStyle(
                                  fontSize: SizeConfig.smallTextSize,
                                  fontWeight: FontWeight.w600,
                                  color: CommonColors.green600,
                                ),
                              ),
                              Icon(
                                Icons.check_circle,
                                color: CommonColors.green600,
                              ),
                            ],
                          ),
                        ),
                        Visibility(
                          visible: widget.model.pickupdeparted != 'Y',
                          child: Expanded(
                            child: ElevatedButton.icon(
                              icon: Icon(Icons.arrow_forward_ios_outlined),
                              iconAlignment: IconAlignment.end,
                              onPressed: () {
                                if (modelDetail.consignmenttype == "P" &&
                                    modelDetail.pickupstatus == "P") {
                                  failToast(
                                      "Please Pick up the consignment first");
                                  return;
                                }
                                updatePickupDepartedPosition();
                              },
                              // icon: Icon(Icons.close, size: SizeConfig.mediumIconSize),
                              label: Text('Pickup Departed',
                                  style: TextStyle(
                                      fontSize: SizeConfig.extraSmallTextSize)),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                    horizontal: SizeConfig.horizontalPadding,
                                    vertical:
                                        SizeConfig.extraSmallVerticalPadding),
                                backgroundColor: CommonColors.colorPrimary2,
                                foregroundColor: CommonColors.White,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: SizeConfig.smallVerticalSpacing),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig.horizontalPadding,
                        vertical: SizeConfig.extraSmallVerticalPadding),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: CommonColors.white!,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                modelDetail.reachedAtDlvPoint == 'Y'
                                    ? modelDetail.reachedAtDlvPointDt.toString()
                                    : 'Pending',
                                style: TextStyle(
                                  fontSize: SizeConfig.extraSmallTextSize,
                                  fontWeight: FontWeight.w600,
                                  color: CommonColors.colorPrimary2,
                                ),
                              ),
                              if (modelDetail.reachedAtDlvPoint != 'Y') ...[
                                const ImageIcon(
                                    AssetImage('assets/images/loading.png'))
                              ],
                            ],
                          ),
                        ),
                        Visibility(
                          visible: widget.model.reachedAtDlvPoint == 'Y',
                          child: Row(
                            children: [
                              Text(
                                'Reached Delivery Point',
                                style: TextStyle(
                                  fontSize: SizeConfig.smallTextSize,
                                  fontWeight: FontWeight.w600,
                                  color: CommonColors.green600,
                                ),
                              ),
                              Icon(
                                Icons.check_circle,
                                color: CommonColors.green600,
                              ),
                            ],
                          ),
                        ),
                        Visibility(
                          visible: widget.model.reachedAtDlvPoint != 'Y',
                          child: Expanded(
                            child: ElevatedButton.icon(
                              icon: Icon(Icons.arrow_forward_ios_outlined),
                              iconAlignment: IconAlignment.end,
                              onPressed: () {
                                if (modelDetail.consignmenttype == "P" &&
                                    modelDetail.pickupstatus == "P") {
                                  failToast(
                                      "Please Pick up the consignment first");
                                  return;
                                } else if (modelDetail.pickupdeparted != 'Y') {
                                  failToast(
                                      "Please depart from pickup point first");
                                  return;
                                }
                                updateDriverReachedDlvLocation();
                              },
                              // icon: Icon(Icons.close, size: SizeConfig.mediumIconSize),
                              label: Text('Arrive At Destination',
                                  style: TextStyle(
                                      fontSize: SizeConfig.extraSmallTextSize)),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                    horizontal:
                                        SizeConfig.extraSmallHorizontalPadding,
                                    vertical:
                                        SizeConfig.extraSmallVerticalPadding),
                                backgroundColor: CommonColors.colorPrimary2,
                                foregroundColor: CommonColors.White,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: SizeConfig.smallVerticalSpacing),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig.horizontalPadding,
                        vertical: SizeConfig.extraSmallVerticalPadding),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: CommonColors.white!,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                isNullOrEmpty(widget
                                        .model.deliverystatusupdateon
                                        .toString())
                                    ? 'Pending'
                                    : widget.model.deliverystatusupdateon
                                        .toString(),
                                style: TextStyle(
                                  fontSize: SizeConfig.extraSmallTextSize,
                                  fontWeight: FontWeight.w600,
                                  color: CommonColors.colorPrimary2,
                                ),
                              ),
                              if (widget.model.deliverystatus == 'P') ...[
                                const ImageIcon(
                                    AssetImage('assets/images/loading.png'))
                              ]
                            ],
                          ),
                        ),
                        Visibility(
                          visible: widget.model.deliverystatus == 'P',
                          child: Expanded(
                            child: Column(
                               crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    LmdMenuModel? targetMenu;
                                    try {
                                      targetMenu = widget.menuList.firstWhere(
                                          (element) =>
                                              element.tag?.toString() ==
                                              MenuTags.DELIVERY.name
                                                  .toString());
                                      {
                                        {
                                          menuCode =
                                              targetMenu.menuCode.toString();
                                        }
                                      }
                                    } catch (e) {
                                      targetMenu = null;
                                    }
                                
                                    String fileName =
                                        targetMenu?.fileName?.toLowerCase() ??
                                            'PodEntry';
                                
                                    if (fileName == 'PodEntry' ||
                                        fileName == 'podentry') {
                                      if (widget.model.reached == 'N') {
                                        failToast("Not reached");
                                        return;
                                      } else if (modelDetail
                                                  .reachedAtDlvPoint ==
                                              'Y' &&
                                          modelDetail.pickupstatus != 'D') {
                                        failToast("Pickup not done yet.");
                                        return;
                                      } else if (modelDetail
                                              .reachedAtDlvPoint !=
                                          'Y') {
                                        failToast(
                                            'Not reached delivery point');
                                        return;
                                      }
                                      Get.to(PodEntry(
                                              deliveryDetailModel:
                                                  modelDetail))
                                          ?.then((_) {
                                        widget.onRefresh();
                                      });
                                    } else {
                                      failToast(
                                          "Screen $fileName not mapped.");
                                    }
                                  },
                                  // icon: Icon(Icons.close, size: SizeConfig.mediumIconSize),
                                  label: Text('Deliver',
                                      style: TextStyle(
                                          color: CommonColors.successColor,
                                          fontSize:
                                              SizeConfig.extraSmallTextSize)),
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                        horizontal:
                                            SizeConfig.horizontalPadding,
                                        vertical: SizeConfig
                                            .extraSmallVerticalPadding),
                                    backgroundColor: CommonColors.white,
                                    foregroundColor: CommonColors.White,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    side: BorderSide(
                                      color: CommonColors
                                          .successColor!, // Border color
                                      width: 3.0, // Border thickness
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: SizeConfig.horizontalPadding,
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    LmdMenuModel? targetMenu;
                                    try {
                                      targetMenu = widget.menuList.firstWhere(
                                          (element) =>
                                              element.tag?.toString() ==
                                              MenuTags.UNDELIVERY.name
                                                  .toString());
                                      {
                                        menuCode =
                                            targetMenu.menuCode.toString();
                                      }
                                    } catch (e) {
                                      targetMenu = null;
                                    }
                                
                                    String fileName =
                                        targetMenu?.fileName?.toLowerCase() ??
                                            'UnDelivery';
                                
                                    if (fileName == 'UnDelivery' ||
                                        fileName == 'undelivery') {
                                      if (widget.model.reached == 'N') {
                                        failToast("Not reached");
                                        return;
                                      } else if (modelDetail.directdelivery ==
                                              'Y' &&
                                          modelDetail.pickupstatus != 'D') {
                                        failToast("Pickup not done yet.");
                                        return;
                                      } else if (modelDetail
                                              .reachedAtDlvPoint !=
                                          'Y') {
                                        failToast(
                                            'Not reached delivery point');
                                        return;
                                      }
                                      Get.to(UnDelivery(
                                              deliveryDetailModel:
                                                  modelDetail))
                                          ?.then((_) {
                                        widget.onRefresh();
                                      });
                                    } else {
                                      failToast(
                                          "Screen $fileName not mapped.");
                                    }
                                  },
                                  // icon: Icon(Icons.close, size: SizeConfig.mediumIconSize),
                                  label: Text('Undeliver',
                                      style: TextStyle(
                                          color: CommonColors.red600,
                                          fontSize:
                                              SizeConfig.extraSmallTextSize)),
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                        horizontal:
                                            SizeConfig.smallHorizontalPadding,
                                        vertical: SizeConfig
                                            .extraSmallVerticalPadding),
                                    backgroundColor: CommonColors.white,
                                    foregroundColor: CommonColors.White,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    side: BorderSide(
                                      color: CommonColors
                                          .red600!, // Border color
                                      width: 3.0, // Border thickness
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Visibility(
                          visible: (modelDetail.deliverystatus != "P"),
                          child: Row(
                            children: [
                              Text(
                                modelDetail.deliverystatus == 'D'
                                    ? 'Delivered'
                                    : 'Undelivered',
                                style: TextStyle(
                                  fontSize: SizeConfig.mediumTextSize,
                                  fontWeight: FontWeight.w600,
                                  color: CommonColors.green600,
                                ),
                              ),
                              Icon(
                                Icons.check_circle,
                                color: CommonColors.green600,
                              ),
                              SizedBox(
                                  width: SizeConfig.smallHorizontalPadding),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: SizeConfig.smallVerticalSpacing),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
