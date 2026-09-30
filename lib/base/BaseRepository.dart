import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gtlmd/api/HttpCalls.dart';
import 'package:gtlmd/common/Utils.dart';
import 'package:gtlmd/common/commonResponse.dart';
import 'package:gtlmd/optionMenu/operations/models/operationsModel.dart';
import 'package:gtlmd/pages/login/models/UpdatePasswordModel.dart';
import 'package:gtlmd/pages/mapView/models/mapConfigDetailModel.dart';
import 'package:gtlmd/pages/orders/drsSelection/model/DrsListModel.dart';
import 'package:gtlmd/pages/trips/tripDetail/Model/currentDeliveryModel.dart';

import 'package:gtlmd/service/connectionCheckService.dart';

class BaseRepository {
  StreamController<bool> viewDialog = StreamController();
  StreamController<String> isErrorLiveData = StreamController();
  StreamController<String> accResp = StreamController();
  StreamController<String> compAccPara = StreamController();
  StreamController<MapConfigDetailModel> mapConfigDetail = StreamController();
  StreamController<CommonUpdateModel> sendAlertResp = StreamController();
  StreamController<String> scannedCode = StreamController();
  StreamController<OperationsModel> urlModel = StreamController();

  // StreamController<List<CurrentDeliveryModel>> deliveryLiveData =
  //     StreamController();

  // StreamController<UpdateDeliveryModel> savePodCommonLiveData =
  //     StreamController();
  // StreamController<UpdateDeliveryModel> saveUnDeliveryList = StreamController();

  static const platform = MethodChannel('scan_channel');

  Future<String> scanBarcode() async {
    String barcode = "";
    try {
      platform.setMethodCallHandler((call) async {
        if (call.method == "onBarcodeScanned") {
          barcode = call.arguments as String;
          scannedCode.add(barcode);
          // print("Scanned barcode: $barcode");
        }
      });
    } catch (e) {
      // print("Error scanning barcode: $e");
      isErrorLiveData.add("Error scanning barcode: ${e.toString()}");
    }
    return barcode;
  }

  Future<void> getValueFromAccPara(Map<String, String> params) async {
    viewDialog.add(true);
    final hasInternet = await NetworkStatusService().hasConnection;
    if (hasInternet) {
      try {
        CommonResponse resp = await apiGet("${bookingUrl}GetKey", params);
        final rawMessage = resp.message?.toString() ?? "";
        print("Raw response message: $rawMessage");

        if (resp.commandStatus == 1) {
          accResp.add(rawMessage);
        } else {
          isErrorLiveData.add(resp.commandMessage ?? "Unknown error");
        }
      } catch (err) {
        isErrorLiveData.add("Exception: ${err.toString()}");
      } finally {
        viewDialog.add(false);
      }
    } else {
      viewDialog.add(false);
      isErrorLiveData.add("No Internet available");
    }
  }

  Future<void> getValueFromCompAccPara(Map<String, String> params) async {
    viewDialog.add(true);
    final hasInternet = await NetworkStatusService().hasConnection;
    if (hasInternet) {
      try {
        CommonResponse resp =
            await apiGet("${bookingUrl}GetValueFromCompAccPara", params);
        final rawMessage = resp.message?.toString() ?? "";
        print("Raw response message: $rawMessage");

        if (resp.commandStatus == 1) {
          compAccPara.add(rawMessage);
        } else {
          isErrorLiveData.add(resp.commandMessage ?? "Unknown error");
        }
      } catch (err) {
        isErrorLiveData.add("Exception: ${err.toString()}");
      } finally {
        viewDialog.add(false);
      }
    } else {
      viewDialog.add(false);
      isErrorLiveData.add("No Internet available");
    }
  }

  Future<void> getMapConfig(Map<String, String> params) async {
    viewDialog.add(true);
    final hasInternet = await NetworkStatusService().hasConnection;

    if (hasInternet) {
      try {
        // viewDialog.add(true);
        CommonResponse resp = await apiGet("${lmdUrl}/getMapConfig", params);
        if (resp.commandStatus == 1) {
          Map<String, dynamic> table = jsonDecode(resp.dataSet.toString());
          Iterable<MapEntry<String, dynamic>> entries = table.entries;
          for (final entry in entries) {
            if (entry.key == "Table") {
              List<dynamic> list2 = entry.value;
              List<MapConfigDetailModel> resultList = List.generate(
                  list2.length,
                  (index) => MapConfigDetailModel.fromJson(list2[index]));

              // var data = resultList;
              mapConfigDetail.add(resultList[0]);
            }
          }
        } else {
          isErrorLiveData.add(resp.commandMessage!);
        }
        viewDialog.add(false);
      } on SocketException catch (_) {
        isErrorLiveData.add("No Internet");
        viewDialog.add(false);
      } catch (err) {
        isErrorLiveData.add(err.toString());
        viewDialog.add(false);
      }
    } else {
      viewDialog.add(false);
      isErrorLiveData.add("No Internet available");
    }
  }

  Future<void> getInfinitiOpsLink(Map<String, String> params) async {
    viewDialog.add(true);
    final hasInternet = await NetworkStatusService().hasConnection;
    if (!hasInternet) {
      throw Exception("No Internet available");
    }

    try {
      CommonResponse resp =
          await apiPostWithModel("${lmdUrl}GetInfinitiPageLink", params);
           
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
        if (result.commandstatus == 1) {
          urlModel.add(result);
        } else {
          isErrorLiveData.add(
              result.commandmessage ?? "Something went wrong. Please try again");
        }
       
      } else {
        isErrorLiveData.add(
            resp.commandMessage ?? "Something went wrong. Please try again");
        debugPrint('Error in : ${resp.commandMessage}');
        viewDialog.add(false);
      }
    } catch (err) {
      viewDialog.add(false);
      debugPrint('Error in getSingleOperation: $err');
      rethrow;
    }finally {
      viewDialog.add(false);
    }
  }

  Future<String> getBookingPrint(Map<String, String> params) async {
    viewDialog.add(true);
    final hasInternet = await NetworkStatusService().hasConnection;
    if (!hasInternet) {
      throw Exception("No Internet available");
    }

    try {
      CommonResponse resp = await apiGet("${bookingUrl}PrintGR", params);
      if (resp.commandStatus != 1) {
        throw Exception(resp.commandMessage ?? "Error occurred");
      }
      viewDialog.add(false);
      if (resp.commandStatus == 1) {
        String url = "";
        if (!isNullOrEmpty(resp.message.toString())) {
          url = resp.message.toString();
        } else {
            throw Exception(resp.commandMessage ?? "Error occurred");
        }
       return url; 
      } else {
        isErrorLiveData.add(
            resp.commandMessage ?? "Something went wrong. Please try again");
      }
    } catch (err) {
      viewDialog.add(false);
      debugPrint('Error in getSingleOperation: $err');
      rethrow;
    }
    return '';
  }

  Future<void> sendShareAlert(Map<String, String> params) async {
     viewDialog.add(true);
    final hasInternet = await NetworkStatusService().hasConnection;

    if (hasInternet) {
      try {
        // viewDialog.add(true);
        CommonResponse resp = await apiPostWithModel("${lmdUrl}sendShareAlertFromLMD", params);
        if (resp.commandStatus == 1) {
          Map<String, dynamic> table = jsonDecode(resp.dataSet.toString());
          Iterable<MapEntry<String, dynamic>> entries = table.entries;
          for (final entry in entries) {
            if (entry.key == "Table") {
              List<dynamic> list2 = entry.value;
              List<CommonUpdateModel> resultList = List.generate(
                  list2.length,
                  (index) => CommonUpdateModel.fromJson(list2[index]));
              sendAlertResp.add(resultList[0]);
            }
          }
        } else {
          isErrorLiveData.add(resp.commandMessage!);
        }
        viewDialog.add(false);
      } on SocketException catch (_) {
        isErrorLiveData.add("No Internet");
        viewDialog.add(false);
      } catch (err) {
        isErrorLiveData.add(err.toString());
        viewDialog.add(false);
      }
    } else {
      viewDialog.add(false);
      isErrorLiveData.add("No Internet available");
    }
  }

  Future<String> getStickerData(Map<String, String> params) async {
    final hasInternet = await NetworkStatusService().hasConnection;
    if (!hasInternet) {
      throw Exception("No Internet available");
    }

    try {
      CommonResponse resp = await apiGet("${lmdUrl}GetStickerData", params);
      if (resp.commandStatus != 1) {
        throw Exception(resp.commandMessage ?? "Error occurred");
      }

      if (resp.commandStatus == 1) {
        String url = resp.message.toString();
        return url;
      } else {
        debugPrint('Error in : ${resp.commandMessage}');
      }
    } catch (err) {
      debugPrint('Error in getStickerData: $err');
      rethrow;
    }
    return '';
  }
}
