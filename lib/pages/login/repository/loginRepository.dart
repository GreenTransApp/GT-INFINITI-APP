import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:gtlmd/api/HttpCalls.dart';
import 'package:gtlmd/common/Environment.dart';
import 'package:gtlmd/common/Utils.dart';
import 'package:gtlmd/common/commonResponse.dart';
import 'package:gtlmd/pages/login/isolates/loginIsolates.dart';
// import 'package:gtlmd/common/environment.dart';
import 'package:gtlmd/pages/login/models/UserCredsModel.dart';
import 'package:gtlmd/pages/login/models/ValidateLoginWithOtpModel.dart';
import 'package:gtlmd/pages/login/models/divisionModel.dart';
import 'package:gtlmd/pages/login/models/loginModel.dart';
import 'package:gtlmd/pages/login/models/userModel.dart';
import 'package:gtlmd/pages/orders/drsSelection/upsertDrsResponseModel.dart';
import 'package:gtlmd/service/connectionCheckService.dart';

class Loginrepository {
  Future<LoginModel> userLogin(Map<String, String> params) async {
    final hasInternet = await NetworkStatusService().hasConnection;

    if (!hasInternet) {
      throw Exception("No Internet available");
    }

    try {
      debugPrint('userLogin API Called');
      CommonResponse response =
          await apiPost("${loginBaseUrl}ValidateLogin", params);

      if (response.commandStatus != 1) {
        throw Exception(response.commandMessage ?? "Something went wrong");
      }

      List<dynamic> table = await compute<String, dynamic>(
          jsonDecode, response.dataSet.toString());
      LoginModel loginResponse = LoginModel.fromJson(table[0]);

      if (loginResponse.commandstatus != 1) {
        throw Exception(loginResponse.commandmessage ?? "Login failed");
      }

      saveInStorageLogin = jsonEncode(table[0]);
      authService.storagePush(ENV.loginPrefTag, saveInStorageLogin!);
      authService.isAuthenticated.add(true);

      savedLogin = loginResponse;

      Map<String, String> offlineCreds = {
        ENV.offlineLoginIdTag: loginResponse.username.toString(),
        ENV.offlineLoginPassTag: loginResponse.password.toString(),
      };
      authService.storagePush(
          ENV.offlineLoginCredsTag, jsonEncode(offlineCreds));

      return loginResponse;
    } on SocketException {
      throw Exception("No internet connection");
    } catch (err) {
      debugPrint('Error in userLogin: $err');
      rethrow;
    }
  }

  Future<UserModel> validateUserLogin(Map<String, String> params) async {
    final hasInternet = await NetworkStatusService().hasConnection;
    if (!hasInternet) {
      throw Exception("No Internet available");
    }

    try {
      CommonResponse resp =
          await apiPost("${loginBaseUrl}ValidateUserLogin", params);

      if (resp.commandStatus != 1) {
        throw Exception(resp.commandMessage ?? "Validation failed");
      }

      List<dynamic> table =
          await compute<String, dynamic>(jsonDecode, resp.dataSet.toString());
      UserModel validateduserResp = UserModel.fromJson(table[0]);

      if (validateduserResp.commandstatus != 1) {
        throw Exception(
            validateduserResp.commandmessage ?? "Validation failed");
      }

      saveInStorageUser = jsonEncode(table[0]);
      authService.storagePush(ENV.userPrefTag, saveInStorageUser!);
      savedUser = validateduserResp;

      return validateduserResp;
    } catch (err) {
      debugPrint('Error in validateUserLogin: $err');
      rethrow;
    }
  }

  Future<ValidateLoginwithOtpModel> validateLoginWithOtp(
      Map<String, String> params) async {
    final hasInternet = await NetworkStatusService().hasConnection;
    if (!hasInternet) {
      throw Exception("No Internet available");
    }

    try {
      CommonResponse resp =
          await apiGet("${lmdUrl}GetLoginOtpForValidate", params);

      if (resp.commandStatus != 1) {
        throw Exception(resp.commandMessage ?? "OTP validation failed");
      }

      Map<String, dynamic> table =
          await compute<String, dynamic>(jsonDecode, resp.dataSet.toString());
      List<dynamic> list = table.values.first;

      if (list.isEmpty) {
        throw Exception("Invalid response from server");
      }

      ValidateLoginwithOtpModel result =
          ValidateLoginwithOtpModel.fromJson(list[0]);

      if (result.commandstatus != 1) {
        throw Exception(result.commandmessage ?? "OTP validation failed");
      }

      return result;
    } on SocketException {
      throw Exception("No Internet");
    } catch (err) {
      debugPrint('Error in validateLoginWithOtp: $err');
      rethrow;
    }
  }

  Future<UserCredsModel> validateUserMobileFromD2D(
      Map<String, String> params) async {
    final hasInternet = await NetworkStatusService().hasConnection;
    if (!hasInternet) {
      throw Exception("No Internet available");
    }

    try {
      CommonResponse resp =
          await apiPost("${loginBaseUrl}ValidatedUserMobileNoFromD2d", params);

      if (resp.commandStatus != 1) {
        throw Exception(resp.commandMessage ?? "Mobile validation failed");
      }

      Map<String, dynamic> table =
          await compute<String, dynamic>(jsonDecode, resp.dataSet.toString());
      List<dynamic> list = table.values.first;

      if (list.isEmpty) {
        throw Exception("Invalid response from server");
      }

      UserCredsModel result = UserCredsModel.fromJson(list[0]);

      if (result.commandstatus != 1) {
        throw Exception(result.commandmessage ?? "Mobile validation failed");
      }

      return result;
    } on SocketException {
      throw Exception("No Internet");
    } catch (err) {
      debugPrint('Error in validateUserMobileFromD2D: $err');
      rethrow;
    }
  }

  Future<int> updatePassword(Map<String, String> params) async {
    final hasInternet = await NetworkStatusService().hasConnection;
    if (!hasInternet) {
      throw Exception("No Internet available");
    }

    try {
      CommonResponse resp =
          await apiPost("${homeBaseUrl}ChangePasswordForLMD", params);

      if (resp.commandStatus != 1) {
        throw Exception(resp.commandMessage ?? "Password change failed");
      }

      return resp.commandStatus!;
    } on SocketException {
      throw Exception("No Internet");
    } catch (err) {
      debugPrint('Error in updatePassword: $err');
      rethrow;
    }
  }

  Future<UpsertTripResponseModel> validateDivision(
      Map<String, String> params) async {
    final hasInternet = await NetworkStatusService().hasConnection;
    if (!hasInternet) {
      throw Exception("No Internet available");
    }

    try {
      CommonResponse resp =
          await apiPost("${loginBaseUrl}ValidateDivision", params);

      if (resp.commandStatus != 1) {
        throw Exception(resp.commandMessage ?? "Division validation failed");
      }

      Map<String, dynamic> table =
          await compute<String, dynamic>(jsonDecode, resp.dataSet.toString());
      List<dynamic> list = table.values.first;

      if (list.isEmpty) {
        throw Exception("Invalid response from server");
      }

      UpsertTripResponseModel result =
          UpsertTripResponseModel.fromJson(list[0]);
      return result;
    } on SocketException {
      throw Exception("No Internet");
    } catch (err) {
      debugPrint('Error in updatePassword: $err');
      rethrow;
    }
  }

  Future<List<DivisionModel>> getDivisionList(
      Map<String, String> params) async {
    final hasInternet = await NetworkStatusService().hasConnection;
    if (!hasInternet) {
      throw Exception("No Internet available");
    }

    try {
      CommonResponse resp =
          await apiGet("${loginBaseUrl}GetDivisionList", params);

      if (resp.commandStatus != 1) {
        throw Exception(resp.commandMessage ?? "List failed");
      }

      if (resp.commandStatus == 1 && resp.dataSet != null) {
        List<DivisionModel> resultList =
            await compute(parseDivisionListIsolate, resp.dataSet!);
        return resultList;
      } else {
        return [];
      }
    } on SocketException {
      throw Exception("No Internet");
    } catch (err) {
      debugPrint('Error in validateLoginWithOtp: $err');
      rethrow;
    }
  }
}
