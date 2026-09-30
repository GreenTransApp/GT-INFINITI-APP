import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:gtlmd/base/BaseRepository.dart';
import 'package:gtlmd/bottomSheet/socialShareBottomSheet/shareOptionItemModel.dart';
import 'package:gtlmd/common/Colors.dart';
import 'package:gtlmd/common/Toast.dart';
import 'package:gtlmd/common/Utils.dart';
import 'package:gtlmd/common/alertBox/loadingAlertWithCancel.dart';
import 'package:gtlmd/design_system/size_config.dart';
import 'package:url_launcher/url_launcher.dart';

enum OptionType { WHATSAPP, VIEW_PDF }

class SocialShareBottomSheet extends StatefulWidget {
  String documentno;
  String menucode;
  SocialShareBottomSheet({
    super.key,
    required this.documentno,
    required this.menucode,
  });

  @override
  State<SocialShareBottomSheet> createState() =>
      SocialsharebottomsheetSheetState();
}

class SocialsharebottomsheetSheetState extends State<SocialShareBottomSheet> {
  final TextEditingController usermobileController = TextEditingController();
  List<ShareOptionitemModel> optionList = List.empty(growable: true);
  final BaseRepository _baseRepo = BaseRepository();
  List<StreamSubscription> _subscription = [];
  late LoadingAlertService loadingAlertService;
  OptionType? selectedOption= OptionType.WHATSAPP;
  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => loadingAlertService = LoadingAlertService(context: context));
    setObserver();
    addOptions();
  }

  setObserver() {
    _subscription.add(_baseRepo.viewDialog.stream.listen((showLoading) {
      if (showLoading) {
        loadingAlertService.showLoading();
      } else {
        loadingAlertService.hideLoading();
      }
    }));
    _subscription.add(_baseRepo.sendAlertResp.stream.listen((resp) {
      if (resp.CommandStatus == 1) {
        successToast(resp.CommandMessage ?? "Successfully send");
        Get.back();
      } else {
        failToast(
            resp.CommandMessage ?? "Something went wrong. Please try again");
      }
    }));
  }

  addOptions() {
    optionList.add(ShareOptionitemModel(
        itemlogo: 'assets/images/whatsapp.png',
        itemtype: OptionType.WHATSAPP,
        itemname: "Whatsapp"));
    optionList.add(ShareOptionitemModel(
        itemlogo: 'assets/images/pdf-file.png',
        itemtype: OptionType.VIEW_PDF,
        itemname: "View PDF"));
  }

  submitAlert() {
    if (selectedOption != null) {
      if (selectedOption == OptionType.WHATSAPP) {
        if (isNullOrEmpty(usermobileController.text.toString())) {
          failToast("Please Enter Mobile No.");
          return;
        }
        sendWhatsappAlert();
      } else if (selectedOption == OptionType.VIEW_PDF) {
        getBookingPrintLink();
      }
    } else {
      failToast("Please Select Option Proceed.");
    }
  }

  getBookingPrintLink() async {
    if (isNullOrEmpty(widget.menucode)) {
      failToast("Unable to  fetch menucode,Please Try again.");
      return;
    } else if (isNullOrEmpty(widget.documentno)) {
      failToast("Unable to  fetch Document# ,Please Try again.");
      return;
    }
    try {
      Map<String, String> params = {
        "prmconnstring": savedUser.companyid.toString(),
        "prmgrno": widget.documentno,
        "prmusercode": savedUser.usercode.toString(),
        "prmmenucode": widget.menucode,
        "prmsessionid": savedUser.sessionid.toString(),
      };
      String url = await _baseRepo.getBookingPrint(params);
      if (!isNullOrEmpty(url) && url.contains('http')) {
        launchUrl(Uri.parse(url));
        Get.back();
      } else {
        failToast(url ?? "Invalid URL Please Contact To Administrator.");
      }
    } catch (error) {
      failToast(error.toString());
    }
  }

  sendWhatsappAlert() async {
    if (isNullOrEmpty(usermobileController.text.toString())) {
      failToast("Please Enter Mobile No.");
      return;
    } else if (isNullOrEmpty(widget.documentno)) {
      failToast("Unable to  fetch Document# ,Please Try again.");
      return;
    }
    try {
      Map<String, String> params = {
        "prmdocumentno": widget.documentno,
        "prmmobileno": usermobileController.text.toString(),
        "prmeventname": "WHATSAPP",
        "prmloginbranchcode": savedUser.loginbranchcode.toString(),
        "prmusercode": savedUser.usercode.toString(),
        "prmmenucode": widget.menucode,
        "prmsessionid": savedUser.sessionid.toString(),
      };
      await _baseRepo.sendShareAlert(params);
    } catch (error) {
      failToast(error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: CommonColors.colorPrimary,
        foregroundColor: CommonColors.White,
        title: const Text('Share Option'),
        centerTitle: true,
        leading: const Text(''),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.extraSmallHorizontalPadding,
              vertical: SizeConfig.extraSmallVerticalPadding),
          margin: EdgeInsets.symmetric(
              horizontal: SizeConfig.extraSmallHorizontalSpacing,
              vertical: SizeConfig.extraSmallVerticalSpacing),
          decoration: BoxDecoration(
              color: CommonColors.colorPrimary?.withAlpha((0.05 * 255).round()),
              borderRadius: BorderRadius.circular(SizeConfig.largeRadius)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(
                height: 115,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: optionList.length,
                  itemBuilder: (context, index) {
                    final data = optionList[index];

                    final bool isSelected = selectedOption == data.itemtype;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedOption = data.itemtype;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 5,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? CommonColors.colorPrimary?.withAlpha(30)
                              : CommonColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? CommonColors.colorPrimary!
                                : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: CommonColors.colorPrimary!.withAlpha(50),
                                blurRadius: 8,
                                spreadRadius: 1,
                                offset: const Offset(0, 3),
                              ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            AnimatedScale(
                              scale: isSelected ? 1.15 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: Image.asset(
                                data.itemlogo.toString(),
                                width: SizeConfig.largeIconSize,
                                height: SizeConfig.largeIconSize,
                                fit: BoxFit.contain,
                              ),
                            ),
                            Text(
                              data.itemname.toString(),
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? CommonColors.colorPrimary
                                    : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                    vertical: SizeConfig.verticalPadding,
                    horizontal: SizeConfig.horizontalPadding),
                margin: EdgeInsets.symmetric(
                    vertical: SizeConfig.smallVerticalSpacing,
                    horizontal: SizeConfig.extraSmallHorizontalSpacing),
                width: SizeConfig.screenWidth,
                decoration: BoxDecoration(color: CommonColors.white),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text("Selected Option :",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(
                          width: SizeConfig.horizontalPadding,
                        ),
                        Text(selectedOption == OptionType.VIEW_PDF
                            ? "View PDF"
                            : "Whatsapp")
                      ],
                    ),
                    SizedBox(
                      height: SizeConfig.smallVerticalSpacing,
                    ),
                    if (selectedOption == OptionType.WHATSAPP) ...[
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          // boxShadow: [
                          //   BoxShadow(
                          //     color: Colors.black.withOpacity(0.08),
                          //     blurRadius: 10,
                          //     offset: const Offset(0, 4),
                          //   ),
                          // ],
                        ),
                        child: TextField(
                          controller: usermobileController,
                          // keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            hintText: 'Mobile Number',
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: CommonColors.colorPrimary!,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.phone_android,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 18, horizontal: 16),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  SizeConfig.mediumRadius),
                              borderSide:
                                  BorderSide(color: CommonColors.grey300!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  SizeConfig.mediumRadius),
                              borderSide:
                                  BorderSide(color: CommonColors.colorPrimary!),
                            ),
                          ),
                        ),
                      ),
                    ]
                  ],
                ),
              )
            ],
          ),
        ),
      ),
      persistentFooterButtons: [
        Row(
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
                  submitAlert();
                },
                icon: Icon(Icons.save, size: SizeConfig.smallIconSize),
                label: Text(
                  "Submit",
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
            )),
          ],
        ),
      ],
    );
  }
}

Future<void> showSocialShareBottomSheetBottomSheet<T>(
  BuildContext context,
  String documentno,
  String menucode,
  // String grno,
) async {
  return showModalBottomSheet<void>(
      isScrollControlled: true,
      useSafeArea: true,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25.0),
        ),
      ),
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.80,
          child: Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: SocialShareBottomSheet(
                documentno: documentno,
                menucode: menucode,
              )),
        );
      });
}
