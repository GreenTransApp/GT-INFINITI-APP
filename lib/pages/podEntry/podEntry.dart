import 'dart:convert';

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:gtlmd/api/HttpCalls.dart';
import 'package:gtlmd/base/BaseRepository.dart';
import 'package:gtlmd/bottomSheet/multiImageBottomSheet.dart';
import 'package:gtlmd/bottomSheet/signatureBottomSheet.dart';
import 'package:gtlmd/common/Colors.dart';
import 'package:gtlmd/common/Toast.dart';
import 'package:gtlmd/common/Utils.dart';
import 'package:gtlmd/common/alertBox/SuccessAlert.dart';
import 'package:gtlmd/common/alertBox/loadingAlertWithCancel.dart';
import 'package:gtlmd/common/commonButton.dart';
import 'package:gtlmd/common/commonModel/allFormLoadModel.dart';
import 'package:gtlmd/common/commonViewModel/lovViewModel.dart';

import 'package:gtlmd/common/imagePicker/alertBoxImagePicker.dart';

import 'package:gtlmd/design_system/size_config.dart';
import 'package:gtlmd/pages/deliveryDetail/Model/deliveryDetailModel.dart';
import 'package:gtlmd/pages/podEntry/Model/podEntryModel.dart';
import 'package:gtlmd/pages/podEntry/Model/stickerModel.dart';
import 'package:gtlmd/pages/podEntry/podEntryViewModel.dart';
import 'package:gtlmd/pages/podEntry/podRelationModel.dart';
import 'package:gtlmd/pages/podEntry/scanAndDeliver.dart';
import 'package:gtlmd/pages/unDelivery/reasonModel.dart';
import 'package:gtlmd/service/locationService/appLocationService.dart';
import 'package:gtlmd/service/locationService/locationService.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/widgets.dart' as pw;

class PodEntry extends StatefulWidget {
  final DeliveryDetailModel deliveryDetailModel;
  const PodEntry({super.key, required this.deliveryDetailModel});
  @override
  State<PodEntry> createState() => _PodEntryState();
}

class _PodEntryState extends State<PodEntry> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _podDate;
  TimeOfDay? _podTime;
  bool _isLoading = true;
  late LoadingAlertService loadingAlertService;
  PodEntryViewModel viewModel = PodEntryViewModel();
  DeliveryDetailModel modelDetail = DeliveryDetailModel();
  final TextEditingController _podDateController = TextEditingController();
  final TextEditingController _podTimeController = TextEditingController();
  final TextEditingController _grNoController = TextEditingController();
  final TextEditingController _originNameController = TextEditingController();
  final TextEditingController _destinationNameController =
      TextEditingController();
  final TextEditingController _bookingDateController = TextEditingController();
  final TextEditingController _bookingTimeController = TextEditingController();
  final TextEditingController _deliveryDateController = TextEditingController();
  final TextEditingController _deliveryTimeController = TextEditingController();
  final TextEditingController _receivedByController = TextEditingController();

  final TextEditingController _receiverMobileByController =
      TextEditingController();
  // final TextEditingController _deliverByController = TextEditingController();
  final TextEditingController _relationController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _arrivalDateController = TextEditingController();
  final TextEditingController _arrivalTimeController = TextEditingController();
  final TextEditingController _totalPckgsController = TextEditingController();
  final TextEditingController _deliverPckgsController = TextEditingController();
  final TextEditingController _damagedPckgsController = TextEditingController();
  final TextEditingController _totalWeightController = TextEditingController();
  final TextEditingController _damagedReasonController =
      TextEditingController();
  String? _selectedRelation;
  ReasonModel? _selectedDamageReason;
  String? _signatureFilePath;
  String? _podFilePath;
  String? _damageImg1FilePath;
  String? _damageImg2FilePath;
  String? totpckgs;
  // List<String> _damageImages = [];
  List<String> _damageImages = List.empty(growable: true);
  List<String> _deliveryNoteImages = List.empty(growable: true);
  bool isSignRequired = true;
  bool isStampRequired = true;
  PodEntryModel model = PodEntryModel();
  // List<PodRelationsModel> _relations = [];
  // List<ReasonModel> _damageReason = [];
  List<PodRelationsModel> _relations = List.empty(growable: true);
  List<ReasonModel> _damageReason = List.empty(growable: true);
  List<PodStickerModel> _stickerList = List.empty(growable: true);
  BaseRepository _baseRepo = BaseRepository();
  late FocusNode receivedByFocus;
  late FocusNode receiverMobileNumFocus;
  late FocusNode dlvPckgsFocus;
  late FocusNode dmgPckgsFocus;
  late FocusNode remarksFocus;
  String currentAddress = '';
  final LovViewModel lovViewModel = LovViewModel();
  List<AllFormLoadModel> _formLoadDataList = List.empty(growable: true);
  // Map<String, AllFormLoadModel> fieldMap = {};
  late DateTime todayDateTime;
  late String currentdate;
  late String currentTime;
  bool isGrEditable = false;
  Position? position;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback(
        (_) => loadingAlertService = LoadingAlertService(context: context));
    setintialValue();
  }

  setintialValue() {
    getLoginPrefs();
    setObservers();
    getPodLovs();
    todayDateTime = DateTime.now();
    // currentdate = DateFormat('yyyy-MM-dd').format(todayDateTime);
    currentdate = DateFormat('dd-MM-yyyy').format(todayDateTime);
    currentTime = DateFormat('h:mm a').format(todayDateTime);
    receivedByFocus = FocusNode();
    receiverMobileNumFocus = FocusNode();
    dlvPckgsFocus = FocusNode();
    dmgPckgsFocus = FocusNode();
    remarksFocus = FocusNode();
    modelDetail = widget.deliveryDetailModel;
    _grNoController.text = isNullOrEmpty(modelDetail.generatedGr)
        ? modelDetail.grno.toString()
        : modelDetail.generatedGr.toString();

    _podDateController.text = currentdate;
    _podTimeController.text = currentTime;
    _deliveryDateController.text = currentdate;
    // _deliverPckgsController.text = modelDetail.pcs.toString();
    // _damagedPckgsController.text = "0";
    _deliveryTimeController.text = currentTime;
    // _deliveryTimeController.text = DateFormat('h:mm a').format(DateTime.now());
    // _deliverByController.text = savedUser.username.toString();
    if (isNullOrEmpty(_grNoController.text.toString())) {
      _grNoController.text = "";
      isGrEditable = true;
    } else {
      isGrEditable = false;
      getGrDetail();
    }
  }

  Future<List<AllFormLoadModel>> getFormLoadData() async {
    Map<String, String> params = {
      "prmlogincompanyid": savedUser.companyid.toString(),
      "prmloginbranchcode": savedUser.loginbranchcode.toString(),
      "prmlogindivisionid": savedUser.logindivisionid.toString(),
      "prmtablename": "grpod",
      "prmusercode": savedUser.usercode.toString(),
      "prmmenucode": "GTAPP_PODENTRY",
      "prmsessionid": savedUser.sessionid.toString(),
    };

    return lovViewModel.getFormLoadData(params);
  }

  Future<void> fetchLocationAndSubmit() async {
    loadingAlertService.showLoading();
    position = await LocationService().getCurrentLocation();

    final address = await AppLocationService().getAddressFromLatLng(
      position!.latitude,
      position!.longitude,
    );
    loadingAlertService.hideLoading();

    if (address != null) {
      currentAddress = address;
      debugPrint("Current Address: $currentAddress");
      submitPodForm();
    } else {
      failToast("Could not get your location.");
    }
  }

  getLoginPrefs() {
    try {
      getLoginData().then((login) => {
            if (login.commandstatus == null || login.commandstatus == -1)
              {debugPrint("Unale to Get LoginData")}
            else
              {
                companyId = login.companyid.toString(),
                getUserData().then((user) => {
                      if (user.commandstatus == null ||
                          user.commandstatus == -1)
                        throw Exception("")
                      else
                        {
                          // setObservers(),
                          // // getFormLoadData(),
                          // getGrDetail(),
                          // getPodLovs()
                        }
                    })
              }
          });
    } catch (err) {
      debugPrint(err.toString());
    }
  }

  setPodData(PodEntryModel pod) {
    _originNameController.text = isNullOrEmpty(pod.origin.toString())
        ? "Data Not Found"
        : pod.origin.toString();
    _destinationNameController.text = isNullOrEmpty(pod.destname.toString())
        ? "Data Not Found"
        : pod.destname.toString();
    _bookingDateController.text =
        isNullOrEmpty(pod.grdt.toString()) ? "" : pod.grdt.toString();
    _bookingTimeController.text =
        isNullOrEmpty(pod.picktime.toString()) ? "" : pod.picktime.toString();
    _arrivalDateController.text = isNullOrEmpty(pod.receivedt)
        ? DateFormat('dd-MM-yyyy').format(DateTime.now())
        : pod.receivedt.toString();
    _arrivalTimeController.text = isNullOrEmpty(pod.receivetime)
        ? "${TimeOfDay.now().hour}:${TimeOfDay.now().minute}"
        : pod.receivetime.toString();
    _destinationNameController.text = pod.destname.toString();
    _receivedByController.text =
        isNullOrEmpty(pod.cnge.toString()) ? "" : pod.cnge.toString();
    _receiverMobileByController.text =
        isNullOrEmpty(_receiverMobileByController.text)
            ? isNullOrEmpty(pod.cngetelno.toString())
                ? ""
                : pod.cngetelno.toString()
            : _receiverMobileByController.text;

    isSignRequired = pod.sign == "Y" ? true : false;
    isStampRequired = pod.stamp == "Y" ? true : false;

    _totalWeightController.text = '${pod.cweight.toString()} Kg';

    _totalPckgsController.text = pod.pckgs.toString() ?? "0";
    _deliverPckgsController.text = pod.deliverpckgs.toString() ?? "0";
    _damagedPckgsController.text = pod.damagepckgs.toString() ?? "0";
    totpckgs = pod.pckgs.toString();
    model.sign = isNullOrEmpty(_signatureFilePath) ? 'N' : 'Y';
    model.stamp = isNullOrEmpty(_podFilePath) ? 'N' : 'Y';
  }

  resetPodData() {
    _originNameController.text = "";
    _destinationNameController.text = "";
    _bookingDateController.text = "";
    _bookingTimeController.text = "";
    _arrivalDateController.text = currentdate;
    _arrivalTimeController.text = currentTime;
    _destinationNameController.text = "";
    _receivedByController.text = "";
    _receiverMobileByController.text = "";
    _remarksController.text = "";
    _relationController.text = "";
    _signatureFilePath = "";
    _podFilePath = "";

    isSignRequired = false;
    isStampRequired = false;
    _totalWeightController.text = '0 Kg';

    _totalPckgsController.text = "0";
    _deliverPckgsController.text = "0";
    _damagedPckgsController.text = "0";
    totpckgs = "0";
    _deliveryNoteImages = [];
    _stickerList = [];
  }

  setObservers() {
    _baseRepo.viewDialog.stream.listen((showDialog) {
      if (showDialog) {
        loadingAlertService.showLoading();
      } else {
        loadingAlertService.hideLoading();
      }
    });
    viewModel.podEntryLiveData.stream.listen((pod) {
      if (pod.commandstatus == 1) {
        setState(() {
          model = pod;
          setPodData(model);
        });
      } else {
        if (pod.commandmessage != null) {
          failToast(pod.commandmessage!);
        } else {
          failToast("Something went wrong");
        }
        resetPodData();

        // Get.back();
      }
    });
    lovViewModel.allFormLoadList.stream.listen((data) {
      if (data[0].CommandStatus == 1) {
        setState(() {
          _formLoadDataList = data;
          createFieldMap(_formLoadDataList);
          debugPrint(model.toString());
        });
      } else {
        if (data[0].CommandMessage != null) {
          failToast(data[0].CommandMessage!);
        } else {
          failToast("Something went wrong");
        }
        // Get.back();
      }
    });

    viewModel.viewDialog.stream.listen((showLoading) {
      if (showLoading) {
        loadingAlertService.showLoading();
      } else {
        loadingAlertService.hideLoading();
      }
    });

    viewModel.isErrorLiveData.stream.listen((errMsg) {
      if (!isNullOrEmpty(errMsg)) {
        failToast(errMsg.toString());
      } else {
        failToast("Something went wrong");
      }
    });

    viewModel.podRelationLiveData.stream.listen((list) {
      if (list != null) {
        setState(() {
          _relations = list;
          _selectedRelation = 'SELF';
          _relationController.text = 'SELF';
        });
        // _showRelationDialog(context, _relations);
      }
    });
    viewModel.podDamageReasonLiveData.stream.listen((list) {
      if (list != null) {
        setState(() {
          _damageReason = list;
        });
        // _showRelationDialog(context, _relations);
      }
    });
    viewModel.podStickerLiveData.stream.listen((list) {
      setState(() {
        _stickerList = list;
      });
    });

    viewModel.savePodLiveData.stream.listen((resp) {
      // String grno = isNullOrEmpty(modelDetail.generatedGr.toString())
      //     ? modelDetail.grno.toString()
      //     : modelDetail.generatedGr.toString();
      if (resp.commandstatus == 1) {
        successToast("POD Upload successful");
        showSuccessAlert(
            context,
            // "POD SUCCESSFULLY\n Consignment# -: ${resp.grNo}",
            "POD SUCCESSFULLY\n Consignment# -: ${_grNoController.text.toString()}",
            "",
            backCallBackForAlert);
      } else {
        failToast(resp.commandmessage!.toString() ?? "Something went wrong");
      }
    });

    // viewModel.savePodCommonLiveData.stream.listen((resp) {
    //   if (resp.commandstatus == 1) {
    //     successToast("POD Upload successful");
    //     showSuccessAlert(
    //         context,
    //         // "POD SUCCESSFULLY\n Consignment# -: ${resp.grNo}",
    //         "POD SUCCESSFULLY\n Consignment# -: ${modelDetail.grno}",
    //         "",
    //         backCallBackForAlert);
    //   } else {
    //     failToast(resp.commandmessage!.toString() ?? "Something went wrong");
    //   }
    // });
  }

  Future<String> convertImagesToPdf(List<String> imagePaths) async {
    final pdf = pw.Document();

    for (final path in imagePaths) {
      final file = File(path);

      if (!await file.exists()) continue;

      final Uint8List bytes = await file.readAsBytes();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (_) => pw.Center(
            child: pw.Image(
              pw.MemoryImage(bytes),
              fit: pw.BoxFit.contain,
            ),
          ),
        ),
      );
    }

    final tempDir = await getTemporaryDirectory();
    final pdfPath =
        '${tempDir.path}/Images_${DateTime.now().millisecondsSinceEpoch}.pdf';

    final pdfFile = File(pdfPath);
    await pdfFile.writeAsBytes(await pdf.save());

    return pdfPath;
  }

  void backCallBackForAlert() {
    //    Navigator.pop(context); // Close success dialog
    Get.back(result: true); // Close PodEntry and return true
  }

  getPodLovs() {
    Map<String, String> params = {
      "prmconnstring": savedLogin.companyid.toString()
    };
    viewModel.getPodLovs(params);
  }

  getGrDetail() {
    if (isNullOrEmpty(_grNoController.text.toString())) {
      failToast("Please Enter Consignment#");
      return;
    }
    Map<String, String> params = {
      "prmcompanyid": savedLogin.companyid.toString(),
      "prmgrno": _grNoController.text.toString(),
      // "prmgrno": isNullOrEmpty(modelDetail.generatedGr)
      //     ? modelDetail.grno.toString()
      //     : modelDetail.generatedGr.toString(),
      "prmbranchcode": savedUser.loginbranchcode.toString()
    };

    viewModel.getPodEntry(params);
  }

  validatePod() async {
    if (_grNoController.text.isEmpty) {
      failToast("Please fill GR number");
      return;
    } else if (_receivedByController.text.isEmpty) {
      failToast('Please fill the Received by field');
      return;
    } else if (_receiverMobileByController.text.isEmpty) {
      failToast('Please fill the receiver mobile number field');
      return;
    }
    // else if (_receiverMobileByController.text.length != 10) {
    //   failToast("Please enter a valid mobile number");
    //   return;
    // }
    else if (isNullOrEmpty(_relationController.text.toString())) {
      failToast('Please fill the relation field');
      return;
    }
/*     else if (_deliverByController.text.isEmpty) {
      failToast('Please fill the delivery boy field');
      return;
    } */
    else if (model!.sign == 'N' ||
        _signatureFilePath == null ||
        _signatureFilePath!.isEmpty) {
      failToast('Please add Signature');
      return;
    } else if (model!.stamp == 'N' ||
        _podFilePath == null ||
        _podFilePath!.isEmpty) {
      failToast('Please add POD Image');
      return;
    } else if (isNullOrEmpty(_deliverPckgsController.text)) {
      failToast("Please enter delivery packages");
      return;
    } else if (isNullOrEmpty(_damagedPckgsController.text)) {
      _damagedPckgsController.text = "0";
      // failToast("Please enter damaged packages");
      // return;
    } else if (int.parse(_deliverPckgsController.text) >
        int.parse(model.pckgs.toString())) {
      failToast("Delivery packages cannot be greater than total packages");
      return;
    } else if (int.parse(_damagedPckgsController.text) >
        int.parse(model.pckgs.toString())) {
      failToast("Damaged packages cannot be greater than total packages");
      return;
    } else if (int.parse(_damagedPckgsController.text.toString()) > 0 &&
        _selectedDamageReason == null) {
      failToast("Please select a damage reason");
      return;
    }
    // else if (int.parse(_damagedPckgsController.text.toString()) > 0 &&
    //     _damageImg1FilePath == null) {
    //   failToast("Please select damange Image 1");
    //   return;
    // }
    else if (int.parse(_damagedPckgsController.text.toString()) > 0 &&
        _damageImages.isEmpty) {
      failToast("Please select damage images");
      return;
    } else {
      fetchLocationAndSubmit();
    }
  }

  Future<void> submitPodForm() async {
    // List<String> damageImageList = List.empty(growable: true);
    // for (String image in _damageImages) {
    //   damageImageList.add(convertFilePathToBase64(image));
    // }

    String damageImagesBase64 = "";
    List<String> damageBase64ImgList = [];
    for (String image in _damageImages) {
      damageBase64ImgList.add(convertFilePathToBase64(image));
    }
    damageImagesBase64 = damageBase64ImgList.join(',');

    String deliveryImagesBase64 = "";
    List<String> DeliveryBase64Images = [];
    for (String image in _deliveryNoteImages) {
      DeliveryBase64Images.add(convertFilePathToBase64(image));
    }
    deliveryImagesBase64 = DeliveryBase64Images.join(',');

    // String damageImgpdfPath = await convertImagesToPdf(_damageImages);
    // String deliveryImgpdfPath = await convertImagesToPdf(_deliveryNoteImages);

    Map<String, dynamic> params = {
      // "prmconnstring": savedLogin.companyid.toString(),
      "prmloginbranchcode": savedUser.loginbranchcode.toString(),
      "prmgrno": _grNoController.text.toString(),
      "prmdlvdt":
          convert2SmallDateTime(_deliveryDateController.text.toString()),
      "prmdlvtime": formatTimeString(_deliveryTimeController.text.toString()),
      "prmname": _receivedByController.text.toString(),
      "prmrelation": _relationController.text.toString(),
      "prmphno": _receiverMobileByController.text.toString(),
      "prmsign": model!.sign.toString(),
      "prmstamp": model!.stamp.toString(),
      "prmremarks": _remarksController.text.toUpperCase(),
      "prmusercode": savedUser.usercode.toString(),
      "prmpodimageurl": convertFilePathToBase64(_podFilePath),
      "prmsignimageurl": convertFilePathToBase64(_signatureFilePath),
      // "prmpodimage": convertFilePathToBase64(_podFilePath),
      // "prmsignimage": convertFilePathToBase64(_signatureFilePath),
      "prmsessionid": savedUser.sessionid.toString(),
      // "prmdelayreason": ",",
      "prmdeliveryboy": savedUser.username.toString(),
      "prmmenucode": menuCode,
      "prmpoddt": convert2SmallDateTime(_podDateController.text.toString()),
      "prmdrsno": model.drsno.toString(),
      "prmboyid": isNullOrEmpty(savedUser.executiveid.toString()) ? "0" : '',
      "prmdeliverpckgs": isNullOrEmpty(_deliverPckgsController.text)
          ? "0"
          : _deliverPckgsController.text.toString(),
      "prmdamagepckgs": isNullOrEmpty(_damagedPckgsController.text)
          ? "0"
          : _damagedPckgsController.text.toString(),
      "prmdamagereasonid": _selectedDamageReason == null
          ? '0'
          : _selectedDamageReason!.reasoncode,
      // "prmdamageimgstr": damageImageList,
      // "prmdamageimagestr": convertFilePathToBase64(damageImgpdfPath),
      "prmdamageimagestr":
          isNullOrEmpty(damageImagesBase64) ? null : damageImagesBase64,
      // "prmdeliveryimgpath": convertFilePathToBase64(deliveryImgpdfPath),
      "prmdeliveryimgpath":
          isNullOrEmpty(deliveryImagesBase64) ? null : deliveryImagesBase64,
      "prmentrylocation": currentAddress,
      "prmentrylocationlat": position?.latitude.toString() ?? "",
      "prmentrylocationlong": position?.longitude.toString() ?? "",
    };

    // loadingAlertService.showLoading();

    viewModel.savePodEntry(params);
  }

  _datePicker(
      String heading, TextEditingController controller, bool isEnabled) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.sizeOf(context).width * 0.02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.sizeOf(context).width * 0.02,
              vertical: MediaQuery.sizeOf(context).height * 0.01,
            ),
            child: RichText(
              textAlign: TextAlign.start,
              text: TextSpan(
                style: const TextStyle(),
                children: <TextSpan>[
                  TextSpan(
                    text: heading,
                    style: const TextStyle(color: CommonColors.appBarColor),
                  ),
                  TextSpan(
                    text: '*',
                    style: TextStyle(color: CommonColors.dangerColor),
                  ),
                ],
              ),
            ),
          ),
          TextField(
            enabled: isEnabled,
            readOnly: true,
            controller: TextEditingController(
              text: controller.text,
            ),
            decoration: const InputDecoration(
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black),
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
              hintText: 'Select date',
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black),
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
              suffixIcon: Icon(
                Icons.calendar_month,
              ),
            ),
            onTap: () {
              _pickDate(controller);
            },
          ),
        ],
      ),
    );
  }

  _timePicker(
      String heading, TextEditingController controller, bool isEnabled) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.sizeOf(context).width * 0.02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.sizeOf(context).width * 0.02,
                vertical: MediaQuery.sizeOf(context).height * 0.01),
            child: RichText(
              textAlign: TextAlign.start,
              text: TextSpan(
                style: const TextStyle(),
                children: <TextSpan>[
                  TextSpan(
                    text: heading,
                    style: const TextStyle(color: CommonColors.appBarColor),
                  ),
                  TextSpan(
                    text: '*',
                    style: TextStyle(color: CommonColors.dangerColor),
                  ),
                ],
              ),
            ),
          ),
          TextField(
            enabled: isEnabled,
            readOnly: true,
            controller: TextEditingController(
              text: controller.text,
            ),
            decoration: const InputDecoration(
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black),
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
              hintText: 'Select time',
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black),
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
              suffixIcon: Icon(Icons.alarm_rounded),
            ),
            onTap: () {
              debugPrint('Field');
              _pickTime(controller);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    debugPrint("Selected date: $pickedDate");
    setState(() {
      controller.text = DateFormat('dd-MM-yyyy').format(pickedDate!);
    });
  }

  String formatDate(DateTime? date) {
    String result = "";
    result = date != null
        ? "${date.toLocal()}".split(' ')[0].toString()
        : _podDateController.text;
    return result;
  }

  Future<void> _pickTime(TextEditingController controller) async {
    final TimeOfDay? selectedTime = await showTimePicker(
      initialTime: TimeOfDay.now(),
      context: context,
    );

    setState(() {
      controller.text = selectedTime != null
          ? "${selectedTime.hour}:${selectedTime.minute}"
          : controller.text;
    });
  }

/*   Future<String?> _showRelationDialog(BuildContext context) async {
    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return _relationSelectionDialog();
      },
    );
  }
 */ /* 
  _relationSelectionDialog() {
    return AlertDialog(
      title: Text('Relation'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _relations.map((relation) {
            return RadioListTile<String>(
              title: Text(relation),
              value: relation,
              groupValue: _selectedRelation,
              onChanged: (String? value) {
                setState(() {
                  _selectedRelation = value;
                });
              },
            );
          }).toList(),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: Text('OK'),
          onPressed: () {
            Navigator.of(context).pop(_selectedRelation);
          },
        ),
      ],
    );
  }
 */

  Future<String?> _getStoragePermission() async {
    final status = await Permission.storage.request();
    if (status.isGranted) {
      return _pickFile();
    }
    final photosPermission = await Permission.photos.request();
    if (photosPermission.isGranted) {
      return _pickFile();
    }
  }

  Future<String?> _pickFile() async {
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles();
    } catch (e) {
      print('Error picking file: $e');
    }
    return result == null ? "" : result.files[0].path;
  }

  void _showRelationDialog(
      BuildContext context, List<PodRelationsModel> _relations) async {
    String? _selectionResult;

    String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: const Text(
                'Relation',
                style: TextStyle(
                  color: Color(0xFF2934AB), // Your primary color
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _relations.map((relation) {
                    return RadioListTile<String>(
                      activeColor: Color(0xFF2934AB),
                      title: Text(relation.relations.toString()),
                      value: relation.relations.toString(),
                      groupValue: _selectedRelation,
                      onChanged: (String? value) {
                        setState(() {
                          _selectedRelation = value;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Color(0xFF2934AB), // Apply primary color
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      color: Color(0xFF2934AB), // Apply primary color
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    Get.back(result: _selectedRelation);
                  },
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      print('Selected Relation: $result');
      setState(() {
        _relationController.text = result.toString();
      });
    }
  }

  Widget _buildFormField({
    required String label,
    required bool isRequired,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon,
                size: SizeConfig.mediumIconSize,
                color: const Color(0xFF64748B)),
            SizedBox(width: SizeConfig.smallHorizontalSpacing),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: label,
                    style: TextStyle(
                      fontSize: SizeConfig.smallTextSize,
                      fontWeight: FontWeight.w500,
                      color: CommonColors.darkCyanBlue!,
                    ),
                  ),
                  if (isRequired)
                    TextSpan(
                      text: ' *',
                      style: TextStyle(
                        color: CommonColors.red!,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: SizeConfig.smallVerticalSpacing),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, IconButton? suffixIcon) {
    return InputDecoration(
      suffixIcon: suffixIcon,
      hintText: hint,
      hintStyle: TextStyle(
          color: CommonColors.grey400!, fontSize: SizeConfig.mediumTextSize),
      contentPadding: EdgeInsets.symmetric(
          horizontal: SizeConfig.smallHorizontalPadding,
          vertical: SizeConfig.smallVerticalPadding),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(SizeConfig.mediumRadius),
        borderSide: BorderSide(color: CommonColors.grey300!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(SizeConfig.mediumRadius),
        borderSide: BorderSide(color: CommonColors.grey300!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(SizeConfig.mediumRadius),
        borderSide:
            BorderSide(color: CommonColors.primaryColorShade!, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(SizeConfig.mediumRadius),
        borderSide: BorderSide(color: CommonColors.red!, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(SizeConfig.mediumRadius),
        borderSide: BorderSide(color: CommonColors.red!, width: 1.5),
      ),
    );
  }

  clearDamagedValues() {
    _selectedDamageReason = null;
    _damageImg1FilePath = null;
    _damageImg2FilePath = null;
  }

  @override
  void dispose() {
    _grNoController.dispose();
    _podDateController.dispose();
    _podTimeController.dispose();
    _originNameController.dispose();
    _destinationNameController.dispose();
    _bookingDateController.dispose();
    _bookingTimeController.dispose();
    _deliveryDateController.dispose();
    _deliveryTimeController.dispose();
    _receivedByController.dispose();
    _receiverMobileByController.dispose();
    _relationController.dispose();
    _remarksController.dispose();
    _arrivalDateController.dispose();
    _arrivalTimeController.dispose();
    _deliverPckgsController.dispose();
    _damagedPckgsController.dispose();
    _totalWeightController.dispose();
    _damagedReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isSmallDevice = screenWidth <= 360;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: CommonColors.colorPrimary,
        title: Text(
          'POD Entry',
          style: TextStyle(
              color: CommonColors.White, fontSize: SizeConfig.largeTextSize),
        ),
        leading: InkWell(
          onTap: () => {Navigator.pop(context)},
          child: Icon(
            Icons.arrow_back,
            color: CommonColors.White,
            size: SizeConfig.largeIconSize,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.horizontalPadding,
                vertical: SizeConfig.verticalPadding),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(SizeConfig.mediumRadius)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig.horizontalPadding,
                        vertical: SizeConfig.verticalPadding),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.local_shipping_outlined,
                              color: CommonColors.primaryColorShade!,
                              size: SizeConfig.extraLargeIconSize,
                            ),
                            SizedBox(width: SizeConfig.mediumHorizontalSpacing),
                            Text(
                              'Delivery Information',
                              style: TextStyle(
                                fontSize: SizeConfig.mediumTextSize,
                                fontWeight: FontWeight.w600,
                                color: CommonColors.primaryColorShade!,
                              ),
                            ),
                          ],
                        ),
                        Visibility(
                          visible: _stickerList.isNotEmpty,
                          child: GestureDetector(
                            onTap: () {
                              Get.to(ScanAndLoad(
                                stickersList: _stickerList,
                                deliveryDetailModel: modelDetail,
                              ))!
                                  .then((_) {
                                getGrDetail();
                              });
                            },
                            child: const Icon(
                              Symbols.qr_code_scanner_rounded,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig.horizontalPadding,
                        vertical: SizeConfig.verticalPadding),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // _buildFormField(
                          //   // label: "Consignment Number",
                          //   label: getFormStringValue(
                          //           "grno", RETURN_TYPE.LabelName) ??
                          //       "Consignment Number",
                          //   isRequired: false,
                          //   icon: Icons.inventory_2_outlined,
                          //   child: TextFormField(
                          //     enabled: false,
                          //     controller: _grNoController,
                          //     style: TextStyle(
                          //         color: CommonColors.appBarColor,
                          //         fontSize: SizeConfig.mediumTextSize),
                          //     decoration: _inputDecoration(
                          //       getFormStringValue(
                          //               "grno", RETURN_TYPE.PlaceHolder) ??
                          //           "Consignment Number",
                          //     ),
                          //     validator: (value) {
                          //       if (value == null || value.isEmpty) {
                          //         return 'Please enter consignment number';
                          //       }
                          //       return null;
                          //     },
                          //   ),
                          // ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.inventory_2_outlined,
                                      size: SizeConfig.mediumIconSize,
                                      color: const Color(0xFF64748B)),
                                  SizedBox(
                                      width: SizeConfig.smallHorizontalSpacing),
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: getFormStringValue("grno",
                                                  RETURN_TYPE.LabelName) ??
                                              "Consignment Number",
                                          style: TextStyle(
                                            fontSize: SizeConfig.smallTextSize,
                                            fontWeight: FontWeight.w500,
                                            color: CommonColors.darkCyanBlue!,
                                          ),
                                        ),
                                        if (true)
                                          TextSpan(
                                            text: ' *',
                                            style: TextStyle(
                                              color: CommonColors.red!,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: SizeConfig.smallVerticalSpacing),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      enabled: isGrEditable,
                                      controller: _grNoController,
                                      style: TextStyle(
                                          color: CommonColors.appBarColor,
                                          fontSize: SizeConfig.mediumTextSize),
                                      decoration: _inputDecoration(
                                        getFormStringValue("grno",
                                                RETURN_TYPE.PlaceHolder) ??
                                            "Consignment Number",
                                        _grNoController.text.isNotEmpty
                                            ? IconButton(
                                                icon: const Icon(Icons.clear),
                                                onPressed: () {
                                                  _grNoController.clear();
                                                  resetPodData();
                                                  setState(() {});
                                                },
                                              )
                                            : null,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter consignment number';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  Visibility(
                                    visible: isGrEditable,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: ElevatedButton(
                                        onPressed: () {
                                          getGrDetail();
                                        },
                                        style: ElevatedButton.styleFrom(
                                          //  backgroundColor: CommonColors.colorPrimary,
                                          elevation: 0,
                                          side: BorderSide(
                                            color: CommonColors.colorPrimary!,
                                            width: 2,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(15),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 18, horizontal: 18),
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: SizeConfig
                                                .extraSmallHorizontalPadding,
                                          ),
                                          child: Text(
                                            'Varify',
                                            style: TextStyle(
                                              color: CommonColors.colorPrimary,
                                              fontWeight: FontWeight.bold,
                                              fontSize:
                                                  SizeConfig.smallTextSize,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),
                          _buildFormField(
                            // label: "Total Weight",
                            label: getFormStringValue(
                                    "cweight", RETURN_TYPE.LabelName) ??
                                "Total Weight",
                            isRequired: false,
                            icon: Icons.inventory_2_outlined,
                            child: TextFormField(
                              enabled: false,
                              style: TextStyle(
                                  color: CommonColors.appBarColor,
                                  fontSize: SizeConfig.mediumTextSize),
                              controller: _totalWeightController,
                              decoration: _inputDecoration(
                                "Total Weight",
                                _totalWeightController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          _totalWeightController.clear();
                                          setState(() {});
                                        },
                                      )
                                    : null,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter total weight';
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(height: SizeConfig.mediumVerticalSpacing),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildFormField(
                                    // label: "Delivery Date",
                                    label: getFormStringValue(
                                            "dlvdt", RETURN_TYPE.LabelName) ??
                                        "Delivery Date",
                                    isRequired: true,
                                    icon: Icons.calendar_today,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal:
                                              SizeConfig.smallHorizontalPadding,
                                          vertical:
                                              SizeConfig.smallVerticalPadding),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: CommonColors.grey300!),
                                        borderRadius: BorderRadius.circular(
                                            SizeConfig.mediumRadius),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _deliveryDateController.text
                                                .toString(),
                                            style: TextStyle(
                                                fontSize:
                                                    SizeConfig.mediumTextSize),
                                          ),
                                          Icon(Icons.calendar_month,
                                              size: SizeConfig.mediumIconSize,
                                              color: CommonColors.grey),
                                        ],
                                      ),
                                    )),
                              ),
                              SizedBox(
                                  width: SizeConfig.mediumHorizontalSpacing),
                              Expanded(
                                child: _buildFormField(
                                  // label: 'Delivery Time',
                                  label: getFormStringValue(
                                          "dlvtime", RETURN_TYPE.LabelName) ??
                                      "Delivery Time",
                                  isRequired: true,
                                  icon: Icons.access_time,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal:
                                            SizeConfig.smallHorizontalPadding,
                                        vertical:
                                            SizeConfig.smallVerticalPadding),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: CommonColors.grey300!),
                                      borderRadius: BorderRadius.circular(
                                          SizeConfig.mediumRadius),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _deliveryTimeController.text
                                              .toString(),
                                          style: TextStyle(
                                              fontSize:
                                                  SizeConfig.mediumTextSize),
                                        ),
                                        Icon(Icons.access_time,
                                            size: SizeConfig.mediumIconSize,
                                            color: CommonColors.grey),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: SizeConfig.mediumVerticalSpacing),
                          _buildFormField(
                            // label: 'Received By',
                            label: getFormStringValue(
                                    "name", RETURN_TYPE.LabelName) ??
                                "Received By",
                            isRequired: true,
                            icon: Icons.person_outline,
                            child: TextFormField(
                              controller: _receivedByController,
                              style: TextStyle(
                                  fontSize: SizeConfig.mediumTextSize),
                              focusNode: receivedByFocus,
                              onTapOutside: (event) {
                                receivedByFocus.unfocus();
                              },
                              decoration: _inputDecoration(
                                "Enter recipient's name",
                                _receivedByController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          _receivedByController.clear();
                                          setState(() {});
                                        },
                                      )
                                    : null,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter recipient name';
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(height: SizeConfig.mediumVerticalSpacing),
                          _buildFormField(
                            // label: 'Receiver Mobile Number',
                            label: getFormStringValue(
                                    "phno", RETURN_TYPE.LabelName) ??
                                "Receiver Mobile Number",
                            isRequired: true,
                            icon: Icons.phone_android_outlined,
                            child: TextFormField(
                              style: TextStyle(
                                  fontSize: SizeConfig.mediumTextSize),
                              focusNode: receiverMobileNumFocus,
                              onTapOutside: (event) {
                                receiverMobileNumFocus.unfocus();
                              },
                              controller: _receiverMobileByController,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              keyboardType: TextInputType.number,
                              decoration: _inputDecoration(
                                'Enter mobile number',
                                _receiverMobileByController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          _receiverMobileByController.clear();
                                          setState(() {});
                                        },
                                      )
                                    : null,
                              ),
                              validator: (value) {
                                if (value == null ||
                                    value.isEmpty ||
                                    value.length != 10) {
                                  return 'Please enter a valid mobile number';
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(height: SizeConfig.mediumVerticalSpacing),
                          // Relation
                          _buildFormField(
                            // label: 'Relation',
                            label: getFormStringValue(
                                    "relation", RETURN_TYPE.LabelName) ??
                                "Relation",
                            isRequired: true,
                            icon: Icons.people_outline,
                            child: DropdownButtonFormField<String>(
                              value: _selectedRelation,
                              style: TextStyle(
                                  fontSize: SizeConfig.mediumTextSize,
                                  color: Colors.black),
                              decoration:
                                  _inputDecoration('Select relation', null),
                              items:
                                  _relations.map((PodRelationsModel relation) {
                                return DropdownMenuItem<String>(
                                  value: relation.relations,
                                  child: Text(relation.relations.toString()),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedRelation = newValue;
                                  _relationController.text =
                                      newValue.toString();
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select a relation';
                                }
                                return null;
                              },
                            ),
                          ),

                          SizedBox(height: SizeConfig.mediumVerticalSpacing),
                          _buildFormField(
                            // label: "Deliver Pckgs",
                            label: getFormStringValue(
                                    "pckgs", RETURN_TYPE.LabelName) ??
                                "Total Pckgs",
                            isRequired: true,
                            icon: Icons.delivery_dining_outlined,
                            child: TextFormField(
                                enabled: false,
                                style: TextStyle(
                                    fontSize: SizeConfig.mediumTextSize),
                                controller: _totalPckgsController,
                                decoration: _inputDecoration(
                                  'Total Packages',
                                  _totalPckgsController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            _totalPckgsController.clear();
                                            setState(() {});
                                          },
                                        )
                                      : null,
                                ),
                                onChanged: null),
                          ),
                          SizedBox(height: SizeConfig.mediumVerticalSpacing),
                          // Delivery Person
                          // _buildFormField(
                          //   label: 'Delivery Person',
                          //   isRequired: true,
                          //   icon: Icons.delivery_dining_outlined,
                          //   child: TextFormField(
                          //     controller: _deliverByController,
                          //     keyboardType: TextInputType.text,
                          //     decoration: _inputDecoration('Delivery person'),
                          //   ),
                          // ),
                          // const SizedBox(height: 20),
                          // Delivery Packages
                          _buildFormField(
                            // label: "Deliver Pckgs",
                            label: getFormStringValue(
                                    "pckgs", RETURN_TYPE.LabelName) ??
                                "Deliver Pckgs",
                            isRequired: true,
                            icon: Icons.delivery_dining_outlined,
                            child: TextFormField(
                              style: TextStyle(
                                  fontSize: SizeConfig.mediumTextSize),
                              focusNode: dlvPckgsFocus,
                              onTapOutside: (event) {
                                dlvPckgsFocus.unfocus();
                              },
                              controller: _deliverPckgsController,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              keyboardType: TextInputType.number,
                              decoration: _inputDecoration(
                                'Delivery Packages',
                                _deliverPckgsController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          _deliverPckgsController.clear();
                                          setState(() {});
                                        },
                                      )
                                    : null,
                              ),
                              validator: (value) {
                                if (isNullOrEmpty(value)) {
                                  return 'Please enter delivery packages';
                                }
                                return null;
                              },
                              onChanged: (value) {
                                if (int.parse(value) >
                                    (int.parse(totpckgs.toString()) -
                                        int.parse(_damagedPckgsController.text
                                            .toString()))) {
                                  failToast(
                                      "Delivery Packages can't be greater than Total Packages - Damaged Packages");
                                  _deliverPckgsController.text = '0';
                                  // _deliverPckgsController.text =
                                  //     (int.parse(totpckgs.toString()) -
                                  //             int.parse(_damagedPckgsController
                                  //                 .text
                                  //                 .toString()))
                                  //         .toString();
                                }
                              },
                            ),
                          ),
                          SizedBox(
                            height: SizeConfig.mediumVerticalSpacing,
                          ),
                          // Damage Packages
                          _buildFormField(
                            // label: "Damaged Pckgs",
                            label: getFormStringValue(
                                    "damage", RETURN_TYPE.LabelName) ??
                                "Damaged Pckgs",
                            isRequired: true,
                            icon: Icons.delivery_dining_outlined,
                            child: TextFormField(
                              style: TextStyle(
                                  fontSize: SizeConfig.mediumTextSize),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              keyboardType: TextInputType.number,
                              focusNode: dmgPckgsFocus,
                              onTapOutside: (event) {
                                dmgPckgsFocus.unfocus();
                              },
                              onChanged: (value) {
                                _damagedPckgsController.text = value;

                                if (_damagedPckgsController.text
                                        .toString()
                                        .isNotEmpty &&
                                    int.parse(_damagedPckgsController.text
                                            .toString()) ==
                                        0) {
                                  // empty the damage reason, damage image 1 and damage image 2 variables
                                  clearDamagedValues();
                                }

                                setState(() {});
                              },
                              controller: _damagedPckgsController,
                              // keyboardType: TextInputType.phone,
                              decoration: _inputDecoration(
                                'Damaged Packages',
                                _damagedPckgsController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          _damagedPckgsController.clear();
                                          setState(() {});
                                        },
                                      )
                                    : null,
                              ),
                              // validator: (value) {
                              //   if (isNullOrEmpty(value)) {
                              //     return 'Please enter damanged packages';
                              //   }
                              //   return null;
                              // },
                            ),
                          ),
                          SizedBox(
                            height: SizeConfig.mediumVerticalSpacing,
                          ),
                          Visibility(
                              visible: _damagedPckgsController.text
                                      .toString()
                                      .isNotEmpty &&
                                  int.parse(_damagedPckgsController.text
                                          .toString()) >
                                      0,
                              child: SizedBox(
                                  height: SizeConfig.mediumVerticalSpacing)),
                          // Damage Reason
                          Visibility(
                            visible: _damagedPckgsController.text
                                    .toString()
                                    .isNotEmpty &&
                                int.parse(_damagedPckgsController.text
                                        .toString()) >
                                    0,
                            child: _buildFormField(
                              label: 'Damage Reason',
                              isRequired: _damagedPckgsController.text
                                      .toString()
                                      .isNotEmpty &&
                                  int.parse(_damagedPckgsController.text
                                          .toString()) >
                                      0,
                              icon: Icons.people_outline,
                              child: DropdownButtonFormField<ReasonModel>(
                                value: _selectedDamageReason,
                                style: TextStyle(
                                    fontSize: SizeConfig.mediumTextSize,
                                    color: Colors.black),
                                decoration:
                                    _inputDecoration('Select reason', null),
                                items: _damageReason.map((ReasonModel reason) {
                                  return DropdownMenuItem<ReasonModel>(
                                    value: reason,
                                    child: Text(
                                        reason.reasonname.toString() ?? ''),
                                  );
                                }).toList(),
                                onChanged: (ReasonModel? newValue) {
                                  setState(() {
                                    _selectedDamageReason = newValue;
                                  });
                                },
                                validator: (value) {
                                  if (value == null) {
                                    return 'Please select a reason';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),

                          SizedBox(
                            height: SizeConfig.mediumVerticalSpacing,
                          ),
                          Visibility(
                            visible: _damagedPckgsController.text
                                    .toString()
                                    .isNotEmpty &&
                                int.parse(_damagedPckgsController.text
                                        .toString()) >
                                    0,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal:
                                      SizeConfig.mediumHorizontalSpacing),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                spacing: 8,
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () async {
                                        // showImagePickerDialog(context,
                                        //     (file) async {
                                        //   if (file != null) {
                                        //     debugPrint(
                                        //         'Damage Image 1 File data: ${file!.path}');
                                        //     setState(() {
                                        //       _damageImg1FilePath = file!.path;
                                        //     });
                                        //   } else {
                                        //     // model!.stamp = 'N';
                                        //     failToast("File not selected");
                                        //   }
                                        // });

                                        List<String> imagePaths =
                                            await showMultiImageBottomSheetDialog(
                                                context, _damageImages, false);
                                        setState(() {
                                          _damageImages = imagePaths;
                                        });
                                      },
                                      child: Container(
                                        alignment: Alignment.center,
                                        padding: EdgeInsets.symmetric(
                                            horizontal: SizeConfig
                                                .smallHorizontalSpacing,
                                            vertical: SizeConfig
                                                .smallVerticalSpacing),
                                        decoration: BoxDecoration(
                                            color:
                                                CommonColors.primaryColorShade,
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(
                                                    SizeConfig.largeRadius))),
                                        child: Text("Damage Images",
                                            style: TextStyle(
                                                color: CommonColors.White,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ),

/* 
                                  Expanded(
                                    child: InkWell(
                                      onTap: () {
                                        // model.stamp = 'Y';
                                        showImagePickerDialog(context,
                                            (file) async {
                                          if (file != null) {
                                            debugPrint(
                                                'Damage Img 2 File data: ${file!.path}');
                                            setState(() {
                                              _damageImg2FilePath = file!.path;
                                            });
                                          } else {
                                            // model!.stamp = 'N';
                                            failToast("File not selected");
                                          }
                                        });
                                      },
                                      child: Container(
                                        alignment: Alignment.center,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 15),
                                        decoration: BoxDecoration(
                                            color:
                                                CommonColors.primaryColorShade,
                                            borderRadius:
                                                const BorderRadius.all(
                                                    Radius.circular(10))),
                                        child: Text("Upload Image 2",
                                            style: TextStyle(
                                                color: CommonColors.White,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ),

 */
                                ],
                              ),
                            ),
                          ),
                          Visibility(
                            visible: (_damagedPckgsController.text
                                    .toString()
                                    .isNotEmpty &&
                                int.parse(_damagedPckgsController.text
                                        .toString()) >
                                    0 &&
                                ((_damageImg1FilePath != null &&
                                        _damageImg1FilePath!.isNotEmpty) ||
                                    (_damageImg2FilePath != null &&
                                        _damageImg2FilePath!.isNotEmpty))),
                            child: Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      // model.stamp = 'Y';
                                      showImagePickerDialog(context,
                                          (file) async {
                                        if (file != null) {
                                          debugPrint(
                                              'Damage Image 1 File data: ${file!.path}');
                                          setState(() {
                                            _damageImg1FilePath = file!.path;
                                          });
                                        } else {
                                          // model!.stamp = 'N';
                                          failToast("File not selected");
                                        }
                                      });
                                    },
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: SizeConfig
                                                  .smallHorizontalSpacing,
                                              vertical: SizeConfig
                                                  .smallVerticalSpacing),
                                          child: Text.rich(TextSpan(
                                              text: 'Image 1',
                                              children: <InlineSpan>[
                                                TextSpan(
                                                  text: '*',
                                                  style: TextStyle(
                                                      color: CommonColors
                                                          .dangerColor),
                                                )
                                              ])),
                                        ),
                                        Container(
                                            height:
                                                SizeConfig.largeVerticalSpacing,
                                            width: MediaQuery.sizeOf(context)
                                                    .width /
                                                2,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10),
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 10),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  const BorderRadius.all(
                                                      Radius.circular(5)),
                                              border: Border.all(
                                                  width: 1,
                                                  color: CommonColors
                                                      .colorPrimary!),
                                            ),
                                            child: _damageImg1FilePath == null
                                                ? Center(
                                                    child: Text(
                                                      "Select Image",
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                          color: CommonColors
                                                              .colorPrimary),
                                                    ),
                                                  )
                                                : Image.file(
                                                    File(_damageImg1FilePath!),
                                                    fit: BoxFit.fill,
                                                  )),
                                      ],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      // model.stamp = 'Y';
                                      showImagePickerDialog(context,
                                          (file) async {
                                        if (file != null) {
                                          debugPrint(
                                              'Damage Image 2 File data: ${file!.path}');
                                          setState(() {
                                            _damageImg2FilePath = file!.path;
                                          });
                                        } else {
                                          // model!.stamp = 'N';
                                          failToast("File not selected");
                                        }
                                      });
                                    },
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: SizeConfig
                                                  .smallHorizontalPadding!,
                                              vertical: SizeConfig
                                                  .smallVerticalPadding!),
                                          child: const Text.rich(
                                            TextSpan(
                                              text: 'Image 2',
                                            ),
                                          ),
                                        ),
                                        Container(
                                            height: SizeConfig
                                                .largeHorizontalSpacing,
                                            width: MediaQuery.sizeOf(context)
                                                    .width /
                                                2,
                                            padding: EdgeInsets.symmetric(
                                                horizontal: SizeConfig
                                                    .smallHorizontalPadding),
                                            margin: EdgeInsets.symmetric(
                                                horizontal: SizeConfig
                                                    .smallVerticalPadding),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(
                                                      SizeConfig.smallRadius)),
                                              border: Border.all(
                                                  width: 1,
                                                  color: CommonColors
                                                      .colorPrimary!),
                                            ),
                                            child: _damageImg2FilePath == null
                                                ? Center(
                                                    child: Text(
                                                      "Select Image",
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                          color: CommonColors
                                                              .colorPrimary),
                                                    ),
                                                  )
                                                : Image.file(
                                                    File(_damageImg2FilePath!),
                                                    fit: BoxFit.fill,
                                                  )),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          // Remarks
                          _buildFormField(
                            // label: 'Remarks',
                            label: getFormStringValue(
                                    "remarks", RETURN_TYPE.LabelName) ??
                                "Remarks",
                            isRequired: false,
                            icon: Icons.comment_outlined,
                            child: TextFormField(
                              focusNode: remarksFocus,
                              onTapOutside: (event) {
                                remarksFocus.unfocus();
                              },
                              controller: _remarksController,
                              style: TextStyle(
                                  fontSize: SizeConfig.mediumTextSize),
                              decoration: _inputDecoration(
                                'Enter any additional notes (optional)',
                                _remarksController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          _remarksController.clear();
                                          setState(() {});
                                        },
                                      )
                                    : null,
                              ),
                              maxLines: 3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig.horizontalPadding),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      spacing: 8,
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              model.sign = 'Y';
                              // showImagePickerDialog(
                              //   context,
                              //   (file) {
                              //     if (file != null) {
                              //       debugPrint('Signature file data: ${file!.path}');
                              //       setState(() {
                              //         _signatureFilePath = file.path;
                              //       });
                              //     } else {
                              //       model!.sign = 'N';
                              //       failToast('File not selected');
                              //     }
                              //   },
                              // );

                              showSignatureBottomSheet(context,
                                  (path, base64Path) {
                                // if (path != null) {
                                //   debugPrint("Signature path: $path");
                                //   debugPrint("Signature Base 64 path: $base64Path");
                                // } else {
                                //   debugPrint("Path is null");
                                //   failToast("File path is null");
                                // };

                                if (path != null && path.isNotEmpty) {
                                  debugPrint('Signature file data: $path');
                                  setState(() {
                                    _signatureFilePath = path;
                                  });
                                } else {
                                  model.sign = 'N';
                                  failToast(
                                      'Something went wrong. Please try again');
                                }
                              });
                            },
                            child: Container(
                              alignment: Alignment.center,
                              padding: EdgeInsets.symmetric(
                                  horizontal: SizeConfig.smallHorizontalPadding,
                                  vertical: SizeConfig.smallVerticalPadding),
                              decoration: BoxDecoration(
                                  color: CommonColors.primaryColorShade,
                                  borderRadius: BorderRadius.all(
                                      Radius.circular(SizeConfig.largeRadius))),
                              child: Text("Upload Signature",
                                  style: TextStyle(
                                      fontSize: SizeConfig.smallTextSize,
                                      color: CommonColors.White,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              model.stamp = 'Y';
                              showImagePickerDialog(context, (file) async {
                                if (file != null) {
                                  debugPrint('POD File data: ${file!.path}');
                                  setState(() {
                                    _podFilePath = file!.path;
                                  });
                                } else {
                                  model!.stamp = 'N';
                                  failToast("File not selected");
                                }
                              });
                            },
                            child: Container(
                              alignment: Alignment.center,
                              padding: EdgeInsets.symmetric(
                                  horizontal: SizeConfig.smallHorizontalPadding,
                                  vertical: SizeConfig.smallVerticalPadding),
                              decoration: BoxDecoration(
                                  color: CommonColors.primaryColorShade,
                                  borderRadius: BorderRadius.all(
                                      Radius.circular(SizeConfig.largeRadius))),
                              child: Text("Upload POD",
                                  style: TextStyle(
                                      fontSize: SizeConfig.smallTextSize,
                                      color: CommonColors.White,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Visibility(
                    visible: (_signatureFilePath != null &&
                            _signatureFilePath!.isNotEmpty) ||
                        (_podFilePath != null && _podFilePath!.isNotEmpty),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              model.sign = 'Y';
                              showSignatureBottomSheet(context,
                                  (path, base64Path) {
                                if (path != null && path.isNotEmpty) {
                                  debugPrint('Signature file data: $path');
                                  setState(() {
                                    _signatureFilePath = path;
                                  });
                                } else {
                                  model.sign = 'N';
                                  failToast(
                                      'Something went wrong. Please try again');
                                }
                              });
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal:
                                          SizeConfig.smallHorizontalPadding,
                                      vertical:
                                          SizeConfig.smallVerticalPadding),
                                  child: Text.rich(TextSpan(
                                      text: 'Singnature Image',
                                      children: <InlineSpan>[
                                        TextSpan(
                                          text: '*',
                                          style: TextStyle(
                                              color: CommonColors.dangerColor),
                                        )
                                      ])),
                                ),
                                Container(
                                    height: isSmallDevice ? 120 : 150,
                                    width: MediaQuery.sizeOf(context).width / 2,
                                    padding: EdgeInsets.symmetric(
                                        horizontal: SizeConfig
                                            .extraSmallHorizontalPadding,
                                        vertical: SizeConfig
                                            .extraSmallVerticalPadding),
                                    margin: EdgeInsets.symmetric(
                                        horizontal: SizeConfig
                                            .extraSmallHorizontalSpacing,
                                        vertical: SizeConfig
                                            .extraSmallVerticalSpacing),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(
                                              SizeConfig.mediumRadius)),
                                      border: Border.all(
                                          width: 1,
                                          color: CommonColors.colorPrimary!),
                                    ),
                                    child: _signatureFilePath == null
                                        ? Center(
                                            child: Text(
                                              "Select Image",
                                              style: TextStyle(
                                                  color: CommonColors
                                                      .colorPrimary),
                                            ),
                                          )
                                        : Image.file(
                                            File(_signatureFilePath!),
                                            fit: BoxFit.fill,
                                          )),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              model.stamp = 'Y';
                              showImagePickerDialog(context, (file) async {
                                if (file != null) {
                                  debugPrint('POD File data: ${file!.path}');
                                  setState(() {
                                    _podFilePath = file!.path;
                                  });
                                } else {
                                  model!.stamp = 'N';
                                  failToast("File not selected");
                                }
                              });
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: SizeConfig.horizontalPadding,
                                      vertical:
                                          SizeConfig.extraSmallVerticalPadding),
                                  child: Text.rich(TextSpan(
                                      text: 'POD Image',
                                      children: <InlineSpan>[
                                        TextSpan(
                                          text: '*',
                                          style: TextStyle(
                                              color: CommonColors.dangerColor),
                                        )
                                      ])),
                                ),
                                Container(
                                    height: isSmallDevice ? 120 : 150,
                                    width: MediaQuery.sizeOf(context).width / 2,
                                    padding: EdgeInsets.symmetric(
                                        horizontal: SizeConfig
                                            .extraSmallHorizontalPadding,
                                        vertical: SizeConfig
                                            .extraSmallVerticalPadding),
                                    margin: EdgeInsets.symmetric(
                                        horizontal: SizeConfig
                                            .extraSmallHorizontalSpacing,
                                        vertical: SizeConfig
                                            .extraSmallVerticalSpacing),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(
                                              SizeConfig.mediumRadius)),
                                      border: Border.all(
                                          width: 1,
                                          color: CommonColors.colorPrimary!),
                                    ),
                                    child: isNullOrEmpty(_podFilePath)
                                        ? Center(
                                            child: Text(
                                              "Select Image",
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  color: CommonColors
                                                      .colorPrimary),
                                            ),
                                          )
                                        : Image.file(
                                            File(_podFilePath!),
                                            fit: BoxFit.fill,
                                          )),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CommonColors.whiteShade,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(SizeConfig.largeRadius),
                        bottomRight: Radius.circular(SizeConfig.largeRadius),
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        List<String> imagePaths =
                            await showMultiImageBottomSheetDialog(
                                context, _deliveryNoteImages, false);
                        setState(() {
                          _deliveryNoteImages = imagePaths;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CommonColors.primaryColorShade,
                        foregroundColor: CommonColors.White,
                        padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.smallHorizontalPadding,
                            vertical: SizeConfig.smallVerticalPadding),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(SizeConfig.largeRadius),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Upload Delivery Images',
                        style: TextStyle(
                          fontSize: SizeConfig.smallTextSize,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CommonColors.whiteShade,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(SizeConfig.largeRadius),
                        bottomRight: Radius.circular(SizeConfig.largeRadius),
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        validatePod();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CommonColors.primaryColorShade,
                        foregroundColor: CommonColors.White,
                        padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.smallHorizontalPadding,
                            vertical: SizeConfig.smallVerticalPadding),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(SizeConfig.largeRadius),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Submit POD',
                        style: TextStyle(
                          fontSize: SizeConfig.smallTextSize,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
