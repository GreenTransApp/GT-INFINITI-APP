import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:gtlmd/api/HttpCalls.dart';
import 'package:gtlmd/common/commonResponse.dart';
import 'package:gtlmd/optionMenu/operations/models/operationsModel.dart';
import 'package:gtlmd/pages/otexPickupScreen/models/OtexPickupInfoModel.dart';
import 'package:gtlmd/pages/otexPickupScreen/models/OtexPickupSplitInfo.dart';
import 'package:gtlmd/pages/otexPickupScreen/models/goodsTypeModel.dart';
import 'package:gtlmd/pages/otexPickupScreen/models/mailDetails.dart';
import 'package:gtlmd/pages/otexPickupScreen/models/packingTypeModel.dart';

import 'package:gtlmd/pages/otexPickupScreen/models/productTypeModel.dart';
import 'package:gtlmd/pages/pickup/model/CngrCngeModel.dart';
import 'package:gtlmd/pages/pickup/model/bookingTypeModel.dart';
import 'package:gtlmd/pages/pickup/model/branchModel.dart';
import 'package:gtlmd/pages/pickup/model/customerModel.dart';
import 'package:gtlmd/pages/pickup/model/deliveryTypeModel.dart';
import 'package:gtlmd/pages/pickup/model/departmentModel.dart';
import 'package:gtlmd/pages/pickup/model/pinCodeModel.dart';
import 'package:gtlmd/pages/pickup/model/savePickupRespModel.dart';
import 'package:gtlmd/service/connectionCheckService.dart';

class OtexPickupRepoImpl {
  Future<List<BranchModel>> getBranchList(Map<String, String> params) async {
    final hasInternet = await NetworkStatusService().hasConnection;
    if (!hasInternet) {
      throw Exception("No Internet available");
    }

    try {
      CommonResponse resp =
          await apiGet("${bookingUrl}GetBranchListWithSearchType", params);

      if (resp.commandStatus != 1) {
        throw Exception(resp.commandMessage ?? "Failed to fetch branch list");
      }

      Map<String, dynamic> table = jsonDecode(resp.dataSet.toString());
      List<dynamic> list = table.values.first;
      List<BranchModel> resultList = List.generate(
          list.length, (index) => BranchModel.fromJson(list[index]));
      return resultList;
    } on SocketException catch (_) {
      throw Exception("No Internet");
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  Future<List<CngrCngeModel>> getCngrCngeList(
      Map<String, String> params, String type) async {
    final hasInternet = await NetworkStatusService().hasConnection;
    if (!hasInternet) {
      throw Exception("No Internet available");
    }

    try {
      // CommonResponse resp = await apiGet("${lmdUrl}showcngrcnge", params);
      CommonResponse resp =
          await apiGet("${lmdUrl}GetOtexCustCngrCngeList", params);

      if (resp.commandStatus != 1) {
        throw Exception(
            resp.commandMessage ?? "Failed to fetch consignor/consignee list");
      }

      Map<String, dynamic> table = jsonDecode(resp.dataSet.toString());
      List<dynamic> list = table.values.first;
      List<CngrCngeModel> resultList = List.generate(
          list.length, (index) => CngrCngeModel.fromJson(list[index]));
      return resultList;
    } on SocketException catch (_) {
      throw Exception("No Internet");
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  Future<List<ProductTypeModel>> getProductTypeList(
      Map<String, String> params) async {
    final hasInternet = await NetworkStatusService().hasConnection;
    if (!hasInternet) {
      throw Exception("No Internet available");
    }

    try {
      CommonResponse resp = await apiGet("${lmdUrl}GetProductTypeLov", params);

      if (resp.commandStatus != 1) {
        throw Exception(
            resp.commandMessage ?? "Failed to fetch booking type list");
      }

      Map<String, dynamic> table = jsonDecode(resp.dataSet.toString());
      List<dynamic> list = table.values.first;
      List<ProductTypeModel> resultList = List.generate(
          list.length, (index) => ProductTypeModel.fromJson(list[index]));
      return resultList;
    } on SocketException catch (_) {
      throw Exception("No Internet");
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  Future<List<PackingTypeModel>> getPackingTypeList(
      Map<String, String> params) async {
    final hasInternet = await NetworkStatusService().hasConnection;
    if (!hasInternet) {
      throw Exception("No Internet available");
    }

    try {
      CommonResponse resp = await apiGet("${lmdUrl}GetPackingTypeLov", params);

      if (resp.commandStatus != 1) {
        throw Exception(
            resp.commandMessage ?? "Failed to fetch packing type list");
      }

      Map<String, dynamic> table = jsonDecode(resp.dataSet.toString());
      List<dynamic> list = table.values.first;
      List<PackingTypeModel> resultList = List.generate(
          list.length, (index) => PackingTypeModel.fromJson(list[index]));
      return resultList;
    } on SocketException catch (_) {
      throw Exception("No Internet");
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  Future<List<GoodsTypeModel>> getGoodsList(Map<String, String> params) async {
    final hasInternet = await NetworkStatusService().hasConnection;
    if (!hasInternet) {
      throw Exception("No Internet available");
    }

    try {
      CommonResponse resp = await apiGet("${lmdUrl}GetGoodsLov", params);

      if (resp.commandStatus != 1) {
        throw Exception(
            resp.commandMessage ?? "Failed to fetch goods type list");
      }

      Map<String, dynamic> table = jsonDecode(resp.dataSet.toString());
      List<dynamic> list = table.values.first;
      List<GoodsTypeModel> resultList = List.generate(
          list.length, (index) => GoodsTypeModel.fromJson(list[index]));
      return resultList;
    } on SocketException catch (_) {
      throw Exception("No Internet");
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  Future<List<BookingTypeModel>> getBookingTypeList(
      Map<String, String> params) async {
    final hasInternet = await NetworkStatusService().hasConnection;
    if (!hasInternet) {
      throw Exception("No Internet available");
    }

    try {
      CommonResponse resp = await apiGet("${lmdUrl}GetBookingTypeLov", params);

      if (resp.commandStatus != 1) {
        throw Exception(
            resp.commandMessage ?? "Failed to fetch booking type list");
      }

      Map<String, dynamic> table = jsonDecode(resp.dataSet.toString());
      List<dynamic> list = table.values.first;
      List<BookingTypeModel> resultList = List.generate(
          list.length, (index) => BookingTypeModel.fromJson(list[index]));
      return resultList;
    } on SocketException catch (_) {
      throw Exception("No Internet");
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  Future<List<DeliveryTypeModel>> getDeliveryTypeList(
      Map<String, String> params) async {
    final hasInternet = await NetworkStatusService().hasConnection;
    if (!hasInternet) {
      throw Exception("No Internet available");
    }

    try {
      CommonResponse resp = await apiGet("${lmdUrl}GetDeliveryTypeLov", params);

      if (resp.commandStatus != 1) {
        throw Exception(
            resp.commandMessage ?? "Failed to fetch delivery type list");
      }

      Map<String, dynamic> table = jsonDecode(resp.dataSet.toString());
      List<dynamic> list = table.values.first;
      List<DeliveryTypeModel> resultList = List.generate(
          list.length, (index) => DeliveryTypeModel.fromJson(list[index]));
      return resultList;
    } on SocketException catch (_) {
      throw Exception("No Internet");
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  Future<List<CustomerModel>> getCustomerList(
      Map<String, String> params) async {
    final hasInternet = await NetworkStatusService().hasConnection;
    if (!hasInternet) {
      throw Exception("No Internet available");
    }

    try {
      CommonResponse resp =
          await apiGet("${lmdUrl}GetViewAllCustomerList", params);

      if (resp.commandStatus != 1) {
        throw Exception(resp.commandMessage ?? "Failed to fetch customer list");
      }

      Map<String, dynamic> table = jsonDecode(resp.dataSet.toString());
      List<dynamic> list = table.values.first;
      List<CustomerModel> resultList = List.generate(
          list.length, (index) => CustomerModel.fromJson(list[index]));
      return resultList;
    } on SocketException catch (_) {
      throw Exception("No Internet");
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  Future<List<DepartmentModel>> getDepartmentList(
      Map<String, String> params) async {
    final hasInternet = await NetworkStatusService().hasConnection;
    if (!hasInternet) {
      throw Exception("No Internet available");
    }

    try {
      CommonResponse resp = await apiGet("${bookingUrl}GetDepartment", params);

      if (resp.commandStatus != 1) {
        throw Exception(
            resp.commandMessage ?? "Failed to fetch department list");
      }

      Map<String, dynamic> table = jsonDecode(resp.dataSet.toString());
      List<dynamic> list = table.values.first;
      List<DepartmentModel> resultList = List.generate(
          list.length, (index) => DepartmentModel.fromJson(list[index]));
      return resultList;
    } on SocketException catch (_) {
      throw Exception("No Internet");
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  Future<List<PinCodeModel>> getPincodeList(Map<String, String> params) async {
    final hasInternet = await NetworkStatusService().hasConnection;
    if (!hasInternet) {
      throw Exception("No Internet available");
    }

    try {
      CommonResponse resp = await apiGet("${bookingUrl}getPinCodeList", params);

      if (resp.commandStatus != 1) {
        throw Exception(resp.commandMessage ?? "Failed to fetch pincode list");
      }

      Map<String, dynamic> table = jsonDecode(resp.dataSet.toString());
      List<dynamic> list = table.values.first;
      List<PinCodeModel> resultList = List.generate(
          list.length, (index) => PinCodeModel.fromJson(list[index]));
      return resultList;
    } on SocketException catch (_) {
      throw Exception("No Internet");
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  Future<SavePickupRespModel> savePickup(Map<String, String> params) async {
    final hasInternet = await NetworkStatusService().hasConnection;
    if (!hasInternet) {
      throw Exception("No Internet available");
    }

    try {
      //  CommonResponse resp =
          // await apiPostWithModel("${lmdUrl}UpsertOtexPickup_V2", params);

      CommonResponse resp =
          await apiPostWithModel("${lmdUrl}UpsertOtexPickup", params);

      if (resp.commandStatus == 1) {
        Map<String, dynamic> table = jsonDecode(resp.dataSet.toString());
        List<dynamic> list = table.values.first;
        List<SavePickupRespModel> resultList = List.generate(
            list.length, (index) => SavePickupRespModel.fromJson(list[index]));
        return resultList[0];
      }
    } on SocketException catch (_) {
      throw Exception("No Internet");
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
    return SavePickupRespModel();
  }

  Future<List<dynamic>> getPickupDetails(Map<String, String> params) async {
    final hasInternet = await NetworkStatusService().hasConnection;
    if (!hasInternet) {
      throw Exception("No Internet available");
    }

    try {
      CommonResponse resp =
          await apiGet("${lmdUrl}GetOtexPickupDetail", params);

      if (resp.commandStatus != 1) {
        throw Exception(resp.commandMessage ?? "Failed to fetch branch list");
      }

      Map<String, dynamic> table = jsonDecode(resp.dataSet.toString());
      Iterable<MapEntry<String, dynamic>> entries = table.entries;
      OtexPickupInfoModel infoModel = OtexPickupInfoModel();
      List<OtexPickupSplitInfo> splitInfo = [];
    
      for (final entry in entries) {
        if (entry.key == 'Table' || entry.key == 'Table1') {
          List<dynamic> list = entry.value;
          List<OtexPickupInfoModel> resultList = List.generate(list.length,
              (index) => OtexPickupInfoModel.fromJson(list[index]));
          if (resultList.isNotEmpty) {
            infoModel = resultList[0];
          }
        } else if (entry.key == 'Table2') {
          List<dynamic> list = entry.value;
          splitInfo = List.generate(list.length,
              (index) => OtexPickupSplitInfo.fromJson(list[index]));
        } 
      }
      List<dynamic> result = [];
      result.add(infoModel);
      if (splitInfo.isNotEmpty) {
        result.add(splitInfo);
      } else {
        result.add(const OtexPickupSplitInfo());
      }
      
      // }
      return result;
    } on SocketException catch (_) {
      throw Exception("No Internet");
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  Future<MailDetails> getMailDetails(Map<String, String> params) async {
    final hasInternet = await NetworkStatusService().hasConnection;
    if (!hasInternet) {
      throw Exception("No Internet available");
    }

    try {
      CommonResponse resp = await apiGet("${lmdUrl}GetMailDetails", params);

      if (resp.commandStatus != 1) {
        throw Exception(resp.commandMessage ?? "Failed to fetch branch list");
      }

      Map<String, dynamic> table = jsonDecode(resp.dataSet.toString());
      Iterable<MapEntry<String, dynamic>> entries = table.entries;
      MailDetails mailDetails = MailDetails();
      for (final entry in entries) {
        if (entry.key == 'Table') {
          List<dynamic> list = entry.value;
          List<MailDetails> resultList = List.generate(
              list.length, (index) => MailDetails.fromJson(list[index]));
          if (resultList.isNotEmpty) {
            mailDetails = resultList[0];
          }
        }
      }

      return mailDetails;
    } on SocketException catch (_) {
      throw Exception("No Internet");
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  Future<OperationsModel?> getPageLink(Map<String, String> params) async {
    final hasInternet = await NetworkStatusService().hasConnection;
    if (!hasInternet) {
      throw Exception("No Internet available");
    }

    try {
      CommonResponse resp = await apiGet("${lmdUrl}GetPageLink", params);
      if (resp.commandStatus != 1) {
        throw Exception(resp.commandMessage ?? "Single Operation fetch failed");
      }

      if (resp.commandStatus == 1 && resp.dataSet != null) {
        // OperationsModel? result =
        //     await compute(parseSingleOperationIsolate, resp.dataSet!);
        Map<String, dynamic> table =
            await compute<String, dynamic>(jsonDecode, resp.dataSet.toString());
        List<dynamic> list = table.values.first;
        OperationsModel result = OperationsModel.fromJson(list[0]);

        return result;
      } else {
        return null;
      }
    } catch (err) {
      debugPrint('Error in getSingleOperation: $err');
      rethrow;
    }
  }

  Future<SavePickupRespModel> scheduleMailAlert(
      Map<String, String> params) async {
    final hasInternet = await NetworkStatusService().hasConnection;
    if (!hasInternet) {
      throw Exception("No Internet available");
    }

    try {
      CommonResponse resp =
          await apiPostWithModel("${lmdUrl}ScheduleMailAlert", params);

      if (resp.commandStatus == 1) {
        Map<String, dynamic> table = jsonDecode(resp.dataSet.toString());
        List<dynamic> list = table.values.first;
        List<SavePickupRespModel> resultList = List.generate(
            list.length, (index) => SavePickupRespModel.fromJson(list[index]));
        return resultList[0];
      } else {
        throw Exception(resp.commandMessage ?? "Failed to send mail");
      }
    } on SocketException catch (_) {
      throw Exception("No Internet");
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }
}
