import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gtlmd/api/model/ApiCallParametersModel.dart';
import 'package:gtlmd/base/BaseRepository.dart';
import 'package:gtlmd/common/Utils.dart';
import 'package:gtlmd/common/toast.dart';
import 'package:gtlmd/pages/otexPickupScreen/models/OtexPickupInfoModel.dart';
import 'package:gtlmd/pages/otexPickupScreen/models/OtexPickupSplitInfo.dart';
import 'package:gtlmd/pages/otexPickupScreen/models/goodsTypeModel.dart';
import 'package:gtlmd/pages/otexPickupScreen/models/mailDetails.dart';
import 'package:gtlmd/pages/otexPickupScreen/models/packingTypeModel.dart';

import 'package:gtlmd/pages/otexPickupScreen/models/productTypeModel.dart';
import 'package:gtlmd/pages/otexPickupScreen/OtexPickupState.dart';
import 'package:gtlmd/pages/otexPickupScreen/OtexPickupRepoImpl.dart';
import 'package:gtlmd/pages/pickup/model/bookingTypeModel.dart';

// Import necessary models for search APIs
import 'package:gtlmd/pages/pickup/model/branchModel.dart';
import 'package:gtlmd/pages/pickup/model/customerModel.dart';
import 'package:gtlmd/pages/pickup/model/deliveryTypeModel.dart';
import 'package:gtlmd/pages/pickup/model/departmentModel.dart';
import 'package:gtlmd/pages/pickup/model/CngrCngeModel.dart';
import 'package:gtlmd/service/locationService/appLocationService.dart';
import 'package:gtlmd/service/locationService/locationService.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class OtexPickupProvider extends ChangeNotifier {
  OtexPickupState _state = OtexPickupState.initial();
  final OtexPickupRepoImpl _repo = OtexPickupRepoImpl();
  final BaseRepository _baseRepo = BaseRepository();
  OtexPickupState get state => _state;

  void initializeForm(
      {String? transactionId,
      String? grno,
      String? orderid,
      String? jobid,
      bool isReadOnly = false}) {
    _state = OtexPickupState(
      headerStatus: SectionStatus.idle,
      cardListStatus: SectionStatus.idle,
      info: OtexPickupInfoModel(orderid: int.parse(orderid.toString())),
      mailDetails: MailDetails(),
      splitInfo: [
        OtexPickupSplitInfo(),
      ],
      isSendingMail: false,
      permanentCardCount: 0,
      totalPalletQty: 0,
      hasTransactionId: transactionId != null && transactionId != "0",
      isMailDialogOpen: false,
      errorMessage: null,
      openVehicleArrival: false,
      vehicleArrivalUrl: '',
      isReadOnly: isReadOnly,
    );
    notifyListeners();

    if (transactionId != null && transactionId != "0") {
      fetchBookingDetails(transactionId, orderid, jobid); // <-- already here
    }
  }

  Future<void> fetchBookingDetails(
      String transactionid, String? orderid, String? jobid) async {
    // Set both sections to loading independently
    _state = _state.copyWith(
      headerStatus: SectionStatus.loading,
      cardListStatus: SectionStatus.loading,
      hasTransactionId: true,
    );
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2)); // simulate network

    try {
      Map<String, String> params = {
        "prmconnstring": savedLogin.companyid.toString(),
        "prmloginbranchcode": savedUser.loginbranchcode.toString(),
        "prmlogindivisionid": savedUser.logindivisionid.toString(),
        "prmusercode": savedUser.usercode.toString(),
        // "prmmenucode": 'GTLMD_OTEXPICKUP',
        "prmmenucode": menuCode,
        "prmsessionid": savedUser.sessionid.toString(),
        "prmindentid": transactionid,
        "prmorderid": orderid ?? '0',
        "prmjobid": (jobid) ?? '0'
      };
      List<dynamic> result = await _repo.getPickupDetails(params);

      OtexPickupInfoModel infoData = result[0] as OtexPickupInfoModel;
      infoData = infoData.copyWith(
          orderid: isNullOrEmpty(orderid) ? 0 : int.parse(orderid.toString()),
          signimagepath: infoData.signimagepath.toString());
      OtexPickupSplitInfo? si = null;

      if (result.length > 1) {
        si = result[1] as OtexPickupSplitInfo;
      }
      // List<OtexPickupSplitInfo> splitData =
      //     (result[1] as List).cast<OtexPickupSplitInfo>().toList();

      // if (splitData.isEmpty) {
      //   splitData = [OtexPickupSplitInfo()];
      // }

      OtexPickupSplitInfo splitInfo = OtexPickupSplitInfo(
          destName: infoData.destName,
          destCode: infoData.destCode,
          cngeName: infoData.cngeName,
          cngeCode: infoData.cngeCode,
          palletQty: infoData.pcs,
          grtype: infoData.grType,
          packingMethodName: infoData.packing,
          packingMethodCode: infoData.packingcode,
          grNo: si != null ? si.grNo : '',
          wayBillNo: si != null ? si.wayBillNo : '',
          weight: isNullOrEmpty(infoData.weight.toString())
              ? 0.0
              : double.tryParse(infoData.weight.toString()),
          actualWeight: isNullOrEmpty(infoData.weight.toString())
              ? 0.0
              : double.tryParse(infoData.weight.toString()),
          chargeableWeight: isNullOrEmpty(infoData.weight.toString())
              ? 0.0
              : double.tryParse(infoData.weight.toString()),
          volumetricWeight: isNullOrEmpty(infoData.weight.toString())
              ? 0.0
              : double.tryParse(infoData.weight.toString()),
          noOfBox: isNullOrEmpty(infoData.pcs.toString())
              ? 0
              : int.tryParse(infoData.pcs.toString()),
          freightAmt: isNullOrEmpty(infoData.freight.toString())
              ? 0.0
              : double.tryParse(infoData.freight.toString()),
          saidToContainName: infoData.goods);

      List<OtexPickupSplitInfo> splitData = [];
      splitData.add(splitInfo);

      _state = _state.copyWith(
        headerStatus: SectionStatus.success,
        cardListStatus: SectionStatus.success,
        info: infoData,
        splitInfo: splitData,
        // Both cards came from server so permanent count = 2
        permanentCardCount: splitData.where((c) => c.isSaved).length,
        totalPalletQty: infoData.pcs,
      );

      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        headerStatus: SectionStatus.failure,
        cardListStatus: SectionStatus.failure,
        errorMessage: _extractMessage(e),
      );
      notifyListeners();
    }
  }

  // API Call: Search Booking Branches for LOV Bottom Sheet
  Future<List<BranchModel>> searchBranches(String query) async {
    try {
      // final params = <String, String>{"SearchText": query, "SearchType": "B"};
      Map<String, String> params = {
        "prmcompanyid": savedLogin.companyid.toString(),
        "prmbranchcode": savedUser.loginbranchcode.toString(),
        "prmusercode": savedUser.usercode.toString(),
        "prmsessionid": savedUser.sessionid.toString(),
        "prmcharstr": query,
      };
      return await _repo.getBranchList(params);
    } catch (e) {
      _state = _state.copyWith(errorMessage: _extractMessage(e));
      notifyListeners();
      return [];
    }
  }

  // API Call: Search Customers for LOV Bottom Sheet
  Future<List<CustomerModel>> searchCustomers(String query) async {
    try {
      // final params = <String, String>{"SearchText": query};
      Map<String, String> params = {
        "prmcompanyid": savedUser.companyid.toString(),
        "prmbranchcode": savedUser.loginbranchcode.toString(),
        "prmusercode": savedUser.usercode.toString(),
        "prmsessionid": savedUser.sessionid.toString(),
        "prmcharstr": query,
      };
      return await _repo.getCustomerList(params);
    } catch (e) {
      _state = _state.copyWith(errorMessage: _extractMessage(e));
      notifyListeners();
      return [];
    }
  }

  // API Call: Search Departments for LOV Bottom Sheet
  Future<List<DepartmentModel>> searchDepartments(String query) async {
    final currentInfo = _state.info;
    if (isNullOrEmpty(currentInfo.custCode) ||
        isNullOrEmpty(currentInfo.orgCode)) {
      _state = _state.copyWith(
          errorMessage: "Booking Branch and customer mandatory");
      notifyListeners();
      return [];
    }
    try {
      // final params = <String, String>{"SearchText": query};
      Map<String, String> params = {
        "prmconnstring": savedUser.companyid.toString(),
        "prmcustcode": _state.info.custCode.toString(),
        "prmorgcode": _state.info.orgCode.toString(),
      };

      return await _repo.getDepartmentList(params);
    } catch (e) {
      _state = _state.copyWith(errorMessage: _extractMessage(e));
      notifyListeners();
      return [];
    }
  }

  // API Call: Search Shippers for LOV Bottom Sheet
  Future<List<CngrCngeModel>> searchShippers(String query) async {
    try {
      // Map<String, String> params = {
      //   "prmconnstring": savedUser.companyid.toString(),
      //   "prmbranchcode": savedUser.loginbranchcode.toString(),
      //   "prmgrtype": 'R',
      //   "prmcngrcnge": 'R',
      //   "prmcustcode": '',
      //   "prmcharstr": query,
      // };
      Map<String, String> p = {
        "BookingBranchCode": isNullOrEmpty(_state.info.orgCode)
            ? ''
            : _state.info.orgCode.toString(),
        'DestinationCode': '',
        'LOVType': 'R'
      };
      Map<String, String> params = {
        'prmconnstring': savedUser.companyid.toString(),
        'prmfilter': query,
        'prmeventname': 'ShortBookingCngr',
        'prmjsondatastr': jsonEncode(p),
        'prmloginbranchcode': savedUser.loginbranchcode.toString(),
        'prmlogindivisionid': savedUser.logindivisionid.toString(),
        'prmusercode': savedUser.usercode.toString(),
        'prmmenucode': 'GTI_WayBillTallySheetComp',
        'prmsessionid': savedUser.sessionid.toString()
      };
      return await _repo.getCngrCngeList(params, "R");
    } catch (e) {
      _state = _state.copyWith(errorMessage: _extractMessage(e));
      notifyListeners();
      return [];
    }
  }

  // API Call: Search Consignee (CngrCnge) for LOV Bottom Sheet
  Future<List<CngrCngeModel>> searchCngrCnge(
      String query, String cngrcnge) async {
    try {
      Map<String, String> p = {
        "BookingBranchCode": isNullOrEmpty(_state.info.orgCode)
            ? ''
            : _state.info.orgCode.toString(),
        'DestinationCode': '',
        'LOVType': cngrcnge
      };
      Map<String, String> params = {
        'prmconnstring': savedUser.companyid.toString(),
        'prmfilter': query,
        'prmeventname': 'ShortBookingCngr',
        'prmjsondatastr': jsonEncode(p),
        'prmloginbranchcode': savedUser.loginbranchcode.toString(),
        'prmlogindivisionid': savedUser.logindivisionid.toString(),
        'prmusercode': savedUser.usercode.toString(),
        'prmmenucode': 'GTI_WayBillTallySheetComp',
        'prmsessionid': savedUser.sessionid.toString()
      };
      return await _repo.getCngrCngeList(params, cngrcnge);
    } catch (e) {
      _state = _state.copyWith(errorMessage: _extractMessage(e));
      notifyListeners();
      return [];
    }
  }

  // API Call: Search Consignee (CngrCnge) for LOV Bottom Sheet
  Future<List<ProductTypeModel>> searchProductType(String query) async {
    try {
      Map<String, String> params = {
        "prmconnstring": savedUser.companyid.toString(),
        "prmloginbranchcode": savedUser.loginbranchcode.toString(),
        "prmlogindivisionid": savedUser.logindivisionid.toString(),
        "prmusercode": savedUser.usercode.toString(),
        "prmmenucode": '',
        "prmsessionid": savedUser.sessionid.toString(),
        "prmquery": query,
      };
      return await _repo.getProductTypeList(params);
    } catch (e) {
      _state = _state.copyWith(errorMessage: _extractMessage(e));
      notifyListeners();
      return [];
    }
  }

  // API Call: Search Consignee (CngrCnge) for LOV Bottom Sheet
  Future<List<GoodsTypeModel>> searchGoodsType(String query) async {
    try {
      Map<String, String> params = {
        "prmconnstring": savedUser.companyid.toString(),
        "prmloginbranchcode": savedUser.loginbranchcode.toString(),
        "prmlogindivisionid": savedUser.logindivisionid.toString(),
        "prmusercode": savedUser.usercode.toString(),
        "prmmenucode": '',
        "prmsessionid": savedUser.sessionid.toString(),
        "prmquery": query,
      };
      return await _repo.getGoodsList(params);
    } catch (e) {
      _state = _state.copyWith(errorMessage: _extractMessage(e));
      notifyListeners();
      return [];
    }
  }

  // API Call: Search Consignee (CngrCnge) for LOV Bottom Sheet
  Future<List<PackingTypeModel>> searchPackingType(String query) async {
    try {
      Map<String, String> params = {
        "prmconnstring": savedUser.companyid.toString(),
        "prmloginbranchcode": savedUser.loginbranchcode.toString(),
        "prmlogindivisionid": savedUser.logindivisionid.toString(),
        "prmusercode": savedUser.usercode.toString(),
        "prmmenucode": '',
        "prmsessionid": savedUser.sessionid.toString(),
        "prmquery": query,
      };
      return await _repo.getPackingTypeList(params);
    } catch (e) {
      _state = _state.copyWith(errorMessage: _extractMessage(e));
      notifyListeners();
      return [];
    }
  }

  // API Call: Search Consignee (CngrCnge) for LOV Bottom Sheet
  Future<List<BookingTypeModel>> searchBookingType(String query) async {
    try {
      Map<String, String> params = {
        "prmconnstring": savedUser.companyid.toString(),
        "prmloginbranchcode": savedUser.loginbranchcode.toString(),
        "prmlogindivisionid": savedUser.logindivisionid.toString(),
        "prmusercode": savedUser.usercode.toString(),
        "prmmenucode": '',
        "prmsessionid": savedUser.sessionid.toString(),
        "prmquery": query,
      };
      return await _repo.getBookingTypeList(params);
    } catch (e) {
      _state = _state.copyWith(errorMessage: _extractMessage(e));
      notifyListeners();
      return [];
    }
  }

  // API Call: Search Consignee (CngrCnge) for LOV Bottom Sheet
  Future<List<DeliveryTypeModel>> searchDeliveryType(String query) async {
    try {
      Map<String, String> params = {
        "prmconnstring": savedUser.companyid.toString(),
        "prmloginbranchcode": savedUser.loginbranchcode.toString(),
        "prmlogindivisionid": savedUser.logindivisionid.toString(),
        "prmusercode": savedUser.usercode.toString(),
        "prmmenucode": '',
        "prmsessionid": savedUser.sessionid.toString(),
        "prmquery": query,
      };
      return await _repo.getDeliveryTypeList(params);
    } catch (e) {
      _state = _state.copyWith(errorMessage: _extractMessage(e));
      notifyListeners();
      return [];
    }
  }

  // Clear the error message after it has been shown
  void clearError() {
    _state = _state.copyWith(clearError: true);
    notifyListeners();
  }

  void updateInfo(OtexPickupInfoModel info) {
    _state = _state.copyWith(info: info, clearError: true);
    notifyListeners();
  }

  void setCardCount(int count) {
    // Floor is max(1, permanentCardCount) — cannot go below saved bookings
    final floor = _state.permanentCardCount > 0 ? _state.permanentCardCount : 1;
    final clamped = count.clamp(floor, 100);
    final current = List<OtexPickupSplitInfo>.from(_state.splitInfo);

    if (clamped > current.length) {
      for (int i = current.length; i < clamped; i++) {
        current.add(OtexPickupSplitInfo());
      }
    } else if (clamped < current.length) {
      current.removeRange(clamped, current.length);
    }

    int totalPallets = 0;
    for (var card in current) {
      totalPallets += card.palletQty ?? 0;
    }

    _state = _state.copyWith(splitInfo: current, totalPalletQty: totalPallets);
    notifyListeners();
  }

  Future<bool> saveCardEntry(
      int index, List<String> bookingImages, String signImagePath,bool sendWhatsapp) async {
    if (index >= _state.splitInfo.length) return false;

    // // Validate total pieces before saving
    // final maxPcs = _state.info.pcs ?? 0;
    var totQty = 0;
    for (var item in _state.splitInfo) {
      totQty = item.palletQty ?? 0;
    }

    // if (maxPcs > 0 && totQty > maxPcs) {
    //   _state = _state.copyWith(
    //       errorMessage:
    //           "Total pieces across cards (${_state.totalPalletQty}) exceed the limit ($maxPcs).");
    //   notifyListeners();
    //   clearError();
    //   return false;
    // }

    // Update the state with the new info object
    String status =
        isNullOrEmpty(_state.splitInfo[index].wayBillNo) ? 'A' : 'U';

    _state = _state.copyWith(
        info: _state.info.copyWith(documentType: 'C', recStatus: status));
    String bookingImagesBase64 = "";
    List<String> base64Images = [];
    for (String image in bookingImages) {
      // bookingImagesBase64 += "${convertFilePathToBase64(image)}";
      base64Images.add(convertFilePathToBase64(image));
    }
    bookingImagesBase64 = base64Images.join(',');

    String? signImg;

    if (signImagePath.startsWith('http')) {
      signImg = await urlToBase64(signImagePath);
    } else {
      signImg = convertFilePathToBase64(signImagePath);
    }
    debugPrint("signImg $signImg");

    String currentAddress = "";
    final position = await LocationService().getCurrentLocation();

    final address =  AppLocationService().getAddressFromLatLng(
      position.latitude,
      position.longitude,
    );
    if (address != null) {
       currentAddress = address.toString();
      debugPrint("Current Address: $currentAddress");
    } else {
      failToast("Could not get your location.");
    }
    Map<String, dynamic> buildSaveJson() {
      return {
        // ── Basic Info ────────────────────────────────────────────
        'indentid': _state.info.indentId ?? 0,
        'documenttype': _state.info.documentType ?? '',
        'orgcode': _state.info.orgCode ?? '',
        'orgname': _state.info.orgCode ?? '',
        'grdt': convert2SmallDateTime(
            DateFormat('yyyy-MM-dd').format(DateTime.now())),
        'picktime': DateFormat('HH:mm').format(DateTime.now()),
        'cnmtno1': '',
        'cnmtno2': '',
        // 'grno': '',
        'grno': _state.splitInfo[0].wayBillNo.toString(),
        'contracttype': '',
        'referenceno': _state.info.referenceNo ?? '',

        // ── Pickup ────────────────────────────────────────────────
        'pickuppoint': _state.info.pickupPoint ?? '',
        'pickuppincode': _state.info.pickupPincode ?? '',
        'pickupaddress': _state.info.pickupAddress ?? '',

        // ── Destination / Delivery ────────────────────────────────
        'destcode': _state.info.destCode,
        'destname': _state.info.destName,
        'deliverypoint': _state.info.deliveryPoint ?? '',
        'deliverypincode': _state.info.deliveryPincode ?? '',
        'dlvaddress': _state.info.deliveryAddress ?? '',

        // ── GR / Booking ──────────────────────────────────────────
        'grtype': _state.info.grtype ?? '',
        'expecteddeliverydt': '',

        // ── Customer ──────────────────────────────────────────────
        'custcode': _state.info.custCode ?? '',
        'custname': _state.info.custName ?? '',
        'custgstno': _state.info.custGstNo ?? '',
        'custdeptid': int.tryParse(_state.info.custDeptId.toString()) ?? 0,
        'collectionstn': '',
        'billingbranchcode': '',

        // ── Consignor ─────────────────────────────────────────────
        'cngrdocumenttype': '',
        'cngrgstno': _state.info.cngrGstNo ?? '',
        'cngrdocnocode': _state.info.cngrDocNoCode ?? '',
        'cngrcode': _state.info.cngrCode ?? '',
        'cngr': _state.info.cngr ?? '',
        'cngrname': _state.info.cngrName ?? '',
        'cngrdealercode': '',
        'cngrtelno': _state.info.cngrMobileNo ?? '',
        'cngremail': _state.info.cngrMobileNo ?? '',
        'cngraddress': _state.info.cngrAddress ?? '',
        'cngrcity': _state.info.cngrCity,
        'cngrzipcode': _state.info.cngrZipCode ?? '',
        'cngrstate': _state.info.cngrState ?? '',
        'cngrcountry': _state.info.cngrCountry ?? '',

        // ── Consignee ─────────────────────────────────────────────
        'cngedocumenttype': '',
        'cngegstno': _state.info.cngeCode ?? '',
        'cngedocnocode': _state.info.cngeCode ?? '',
        'cngecode': _state.info.cngeCode ?? '',
        'cnge': _state.info.cngeName ?? '',
        'cngename': _state.info.cngeName ?? '',
        'cngedealercode': '',
        'cngetelno': _state.info.cngeMobileNo ?? '',
        'cngeemail': _state.info.cngeEmailId ?? '',
        'cngeaddress': _state.info.cngeAddress ?? '',
        'cngecity': _state.info.cngeCity ?? '',
        'cngezipcode': _state.info.cngeZipCode ?? '',
        'cngestate': _state.info.cngeState ?? '',
        'cngecountry': _state.info.cngeCountry ?? '',

        // ── Other Details ─────────────────────────────────────────
        'loadtype': _state.info.loadTypeCode ?? '',
        'productcode': _state.info.productCode ?? '',
        'dlvtype': _state.info.dlvType ?? '',
        'freighton': '',
        'valgoods': 0,
        'remarks': _state.info.remarks ?? '',
        'freight': _state.info.freight ?? 0,
        'orderid': 0,

        // ── Settings ──────────────────────────────────────────────
        'recstatus': status,
        'totalpckgs': _state.info.pcs.toString(),
        'totalvweight': double.tryParse(_state.info.totalVWeight.toString()) ?? 0,
        'totalaweight': double.tryParse(_state.info.totalAWeight.toString()) ?? 0,
        'totalcweight': double.tryParse(_state.info.totalCWeight.toString()) ?? 0,
        'indentrefrenceno': _state.info.orderid ?? 0,
        // 'noofbox': _state.info.pcs.toString(),
        'noofbox': totQty,
        'jobid': _state.info.jobid,
        "entrylocation": currentAddress,
        "entrylocationlat": position.latitude.toString()?? "",
        "entrylocationlong": position.longitude.toString() ?? "",
        "sendwhatsapp" : sendWhatsapp == true? 'Y' : 'N'
      };
    }

    Map<String, String> params = {
      // "companyId": savedUser.companyid.toString(),
      "prmjsondatastr": jsonEncode(buildSaveJson()),
      "prminvjsondatastr":
          jsonEncode(_state.splitInfo.map((e) => e.toJson()).toList()),
      "prmdocimgpath": bookingImagesBase64,
      "prmsignimgpath": isNullOrEmpty(signImg)
          ? ""
          // : convertFilePathToBase64(signImagePath),
          : signImg.toString(),
      "prmloginbranchcode": savedUser.loginbranchcode.toString(),
      "prmlogindivisionid": savedUser.logindivisionid.toString(),
      "prmusercode": savedUser.usercode.toString(),
      // "prmmenucode": 'GTLMD_OTEXPICKUP',
      "prmmenucode": menuCode,
      "prmsessionid": savedUser.sessionid.toString(),
    };

    try {
      final response = await _repo.savePickup(params);
      if (response.commandStatus == 1) {
        final updated = List<OtexPickupSplitInfo>.from(_state.splitInfo);

        String? newWayBillNo = response.grno;
        if (newWayBillNo == null || newWayBillNo.isEmpty) {
          newWayBillNo = updated[index].wayBillNo;
        }

        updated[index] = updated[index].copyWith(
          wayBillNo: newWayBillNo,
          isSaved: true,
        );
        final permanentCount = updated.where((c) => c.isSaved).length;
        final wasFirstSave = _state.permanentCardCount == 0;

        _state = _state.copyWith(
          splitInfo: updated,
          permanentCardCount: permanentCount,
          hasTransactionId: wasFirstSave ? true : _state.hasTransactionId,
        );
        _state = _state.copyWith(successMessage: response.commandMessage);
        notifyListeners();
        // if(!isNullOrEmpty(updated[index].wayBillNo)){
        //   await getMailDetails(updated[index].wayBillNo.toString());
        // }

        return true;
      } else {
        _state = _state.copyWith(errorMessage: response.commandMessage);
        notifyListeners();
        return false;
      }
    } catch (e) {
      _state = _state.copyWith(errorMessage: _extractMessage(e));
      notifyListeners();
      return false;
    }
  }

  Future<bool> getMailDetails(String grno) async {
    Map<String, String> params = {
      "prmconnstring": savedUser.companyid.toString(),
      "prmgrno": grno,
      "prmloginbranchcode": savedUser.loginbranchcode.toString(),
      "prmlogindivisionid": savedUser.logindivisionid.toString(),
      "prmusercode": savedUser.usercode.toString(),
      // "prmmenucode": 'GTAPP_PICKUPBOOKING',
      "prmmenucode": menuCode,
      "prmsessionid": savedUser.sessionid.toString(),
    };

    try {
      final response = await _repo.getMailDetails(params);
      if (response.commandstatus == 1) {
        if (_state.info.autoSendEmail == 'N') {
          _state =
              _state.copyWith(mailDetails: response, isMailDialogOpen: true);
          notifyListeners();
        } else {
          _state =
              _state.copyWith(mailDetails: response, isMailDialogOpen: false);
          notifyListeners();
          sendMail(
              email: response.toemailid.toString(),
              sendLabel: true,
              ccemails: response.ccemailids.toString());
        }
        return true;
      } else {
        return false;
      }
    } catch (e) {
      _state = _state.copyWith(
          errorMessage: _extractMessage(e), isMailDialogOpen: false);
      notifyListeners();
      return false;
    }
  }

  void closeMailDialog() {
    _state = _state.copyWith(isMailDialogOpen: false);
    notifyListeners();
  }

  // Add a dynamic card entry
  void addCardEntry() {
    final updatedList = List<OtexPickupSplitInfo>.from(_state.splitInfo)
      ..add(OtexPickupSplitInfo());
    _state = _state.copyWith(splitInfo: updatedList);
    notifyListeners();
  }

  void removeCardEntry(int index) {
    if (_state.splitInfo.length <= 1) return;

    final updatedList = List<OtexPickupSplitInfo>.from(_state.splitInfo)
      ..removeAt(index);

    int newTotal = 0;
    for (var card in updatedList) {
      newTotal += card.palletQty ?? 0;
    }

    _state = _state.copyWith(splitInfo: updatedList, totalPalletQty: newTotal);
    notifyListeners();
  }

  void updateCardData(int index, OtexPickupSplitInfo cardData) {
    if (index >= _state.splitInfo.length) return;
    final updatedList = List<OtexPickupSplitInfo>.from(_state.splitInfo);
    updatedList[index] = cardData;
    if (cardData.palletQty! > _state.info.pcs!) {
      _state.copyWith(errorMessage: "Pallet Qty cannot exceed total Pieces.");
      notifyListeners();
      return;
    }
    _state = _state.copyWith(
        splitInfo: updatedList, totalPalletQty: cardData.palletQty);
    notifyListeners();
  }

  Future<String> getPageLink() async {
    Map<String, String> params = {
      "prmconnstring": savedUser.companyid.toString(),
      "prmlinkpagemenucode": 'GTI_VEHICLEARRIVAL',
      'prmdrivercode': savedUser.drivercode.toString(),
      "prmusercode": savedUser.usercode.toString(),
      'prmmenucode': 'GTLMD_INFINITIOPSLINK',
      "prmsessionid": savedUser.sessionid.toString(),
      "prmloginbranchcode": savedUser.loginbranchcode.toString(),
      "prmloginbranchtype": savedUser.loginbranchtype.toString(),
    };

    try {
      final response = await _repo.getPageLink(params);
      if (response != null) {
        // Assuming the first result is the desired one
        _state = _state.copyWith(
            openVehicleArrival: true, vehicleArrivalUrl: response.pageLink);
        notifyListeners();
        return response.pageLink.toString();
      } else {
        // No operations found
        _state = _state.copyWith(
            openVehicleArrival: false,
            errorMessage: "No Menu found for the given details.");
        notifyListeners();
        return '';
      }
    } catch (e) {
      _state = _state.copyWith(errorMessage: _extractMessage(e));
      notifyListeners();
      return '';
    }
  }

  // Helper to extract clean message from Exception
  String _extractMessage(dynamic e) {
    if (e is Exception) {
      return e.toString().replaceFirst('Exception: ', '');
    }
    return e.toString();
  }

  // Bluetooth/Local Printer Call: Print Local labels
  Future<void> printLabel(int index) async {
    try {
      String base64 =
          await getStickerData(_state.splitInfo[index].wayBillNo.toString());
      if (!isNullOrEmpty(base64)) {
        String url = await convertBase64ToPdfUrl(
            base64, 'sticker_${DateTime.now().millisecondsSinceEpoch}');
        // await OpenFilex.open(url);
      }
    } catch (error) {
      _state = _state.copyWith(errorMessage: error.toString());
    }
  }

  // Bluetooth/Local Printer Call: Print Local Waybill
  Future<void> printWaybill(int index) async {
    await getBookingPrintLink(_state.splitInfo[index].wayBillNo.toString());
  }

  Future<void> getBookingPrintLink(String grno) async {
    try {
      Map<String, String> params = {
        "prmconnstring": savedUser.companyid.toString(),
        "prmgrno": grno,
        "prmusercode": savedUser.usercode.toString(),
        // "prmmenucode": "GTAPP_BOOKING",
        "prmmenucode": menuCode,
        "prmsessionid": savedUser.sessionid.toString(),
      };
      String url = await _baseRepo.getBookingPrint(params);
      debugPrint("printurl $url");
      if (!isNullOrEmpty(url)) {
        launchUrl(Uri.parse(url));
      }
    } catch (error) {
      _state = _state.copyWith(errorMessage: error.toString());
    }
  }

  Future<String> getBookingPdf(String grno, String menucode) async {
    String url = "";
    try {
      Map<String, String> params = {
        "prmconnstring": savedUser.companyid.toString(),
        "prmgrno": grno,
        "prmusercode": savedUser.usercode.toString(),
        "prmmenucode": menucode,
        "prmsessionid": savedUser.sessionid.toString(),
      };
      url = await _baseRepo.getBookingPrint(params);
      return url;
    } catch (error) {
      rethrow;
    }
  }

  Future<String> getStickerData(String grno) async {
    String base64 = "";
    try {
      Map<String, String> params = {
        "prmconnstring": savedUser.companyid.toString(),
        "prmloginbranchcode": savedUser.loginbranchcode.toString(),
        "prmlogindivisionid": savedUser.logindivisionid.toString(),
        "prmusercode": savedUser.usercode.toString(),
        "prmmenucode": menuCode,
        "prmsessionid": savedUser.sessionid.toString(),
        "prmgrno": grno,
        "prmfrom": "1",
        "prmto": _state.info.pcs.toString(),
        "prmprintmenucode": menuCode,
        "prmeventname": "PRINTSTICKER"
      };
      base64 = await _baseRepo.getStickerData(params);
    } catch (error) {
      rethrow;
    }
    return base64;
  }

  Future<bool> sendMail(
      {required String email,
      required bool sendLabel,
      required String ccemails}) async {
    _state = _state.copyWith(isSendingMail: true);
    notifyListeners();
    try {
      List<String> ccemailslist = ccemails.split(',');
      String cc = "";
      if (ccemailslist.isNotEmpty) {
        for (String x in ccemailslist) {
          cc += isNullOrEmpty(x) ? '' : x;
          cc += ',';
        }
      }

      if (cc.length == 1) {
        cc = '';
      }

      String url = await getBookingPdf(
          _state.splitInfo.first.wayBillNo.toString(),
          menuCode ?? "GTAPP_BOOKING");

      String labels =
          await getStickerData(_state.splitInfo.first.wayBillNo.toString());

      String? attachmentBase64 = await urlToBase64(url);
      if (!isNullOrEmpty(labels)) {
        if (isNullOrEmpty(attachmentBase64)) {
          attachmentBase64 = labels;
        } else {
          attachmentBase64 = "$attachmentBase64,$labels";
        }
      }
      String fileName =
          "${_state.splitInfo.first.wayBillNo.toString()}_BookingPrint.pdf";
      if (!isNullOrEmpty(labels)) {
        fileName =
            "$fileName,${_state.splitInfo.first.wayBillNo.toString()}_Sticker.pdf";
      }
      Map<String, String> params = {
        "prmusercode": savedUser.usercode.toString(),
        "prmalertsubject": _state.mailDetails.emailsubject.toString(),
        "prmalertmessage": _state.mailDetails.emailbody.toString(),
        "prmemailid": email,
        "prmfilenamewithext": fileName,
        "prmattachfile":
            isNullOrEmpty(attachmentBase64) ? '' : attachmentBase64!,
        "prmattachment": 'Y',
        "prmalertcc": cc,
        "prmemailtemplateid": _state.mailDetails.emailtemplateid.toString(),
        // "prmmenucode": 'GTLMD_OTEXPICKUP',
        "prmmenucode": menuCode,
        "prmsessionid": savedUser.sessionid.toString(),
      };

      final response = await _repo.scheduleMailAlert(params);
      if (response.commandStatus == 1) {
        _state = _state.copyWith(
          isMailDialogOpen: false,
          isSendingMail: false,
        );
        _state = _state.copyWith(successMessage: response.commandMessage);
        notifyListeners();
        return true;
      } else {
        _state = _state.copyWith(isSendingMail: false);
        notifyListeners();
        return false;
      }
    } catch (e) {
      _state = _state.copyWith(
          errorMessage: _extractMessage(e),
          isMailDialogOpen: false,
          isSendingMail: false);
      notifyListeners();
      return false;
    }
  }
}
