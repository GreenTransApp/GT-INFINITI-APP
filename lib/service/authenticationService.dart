import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gtlmd/api/ApiResponse.dart';
import 'package:gtlmd/common/CommonResponse.dart' hide CommonResponse;
import 'package:gtlmd/common/Environment.dart';
import 'package:gtlmd/common/Toast.dart';
import 'package:gtlmd/common/commonResponse.dart';
import 'package:gtlmd/pages/dashboard/userDashboard/userDashboardPage.dart';
import 'package:gtlmd/pages/home/Model/validateDeviceModel.dart';
import 'package:gtlmd/pages/home/homeScreenPage.dart';
import 'package:gtlmd/navigateRoutes/Routes.dart';
import 'package:gtlmd/navigateRoutes/RoutesName.dart';
import 'package:gtlmd/pages/home/isolates.dart';
import 'package:gtlmd/pages/login/models/loginModel.dart';
import 'package:gtlmd/pages/login/models/userModel.dart';
import 'package:gtlmd/pages/updateVersionScreen/updateVersionScreen.dart';
import 'package:gtlmd/service/connectionCheckService.dart';
import 'package:path/path.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:gtlmd/pages/login/viewModel/loginProvider.dart';

import '../api/HttpCalls.dart';
import '../common/Utils.dart';

class AuthenticationService {
  AuthService() {
    isLogin();
  }

  BehaviorSubject<bool?> isAuthenticated = BehaviorSubject<bool?>.seeded(null);
  String token = '';

  void storagePush(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    debugPrint("Storage KEY: $key");
    debugPrint("Storage VAL: $value");
    await prefs.setString(key, value);
  }

  Future<void> isLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(ENV.userPrefTag);
    if (token != null) {
      isAuthenticated.add(true);
    } else {
      isAuthenticated.add(false);
    }
  }

  Future<String?> storageGet(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final String? resp = prefs.getString(key);
    return resp;
  }

  void storageRemove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  void storageClear() async {
    // final prefs = await SharedPreferences.getInstance();
    storageRemove(ENV.userPrefTag);
    storageRemove(ENV.loginPrefTag);
    // await prefs.clear();
  }

  void login(BuildContext context) {
    isAuthenticated.add(true);
    //   UserModel userData = UserModel();
    //   getUserData().then((user) => {
    //           if (user.commandstatus == null || user.commandstatus == -1)
    //             throw Exception("")
    //           else
    //             {
    //               userData = user,
    //             }
    //         });
    // if(isNullOrEmpty(userData.drivercode)){
    // Get.off(UserDashboardPage());
    // }else{
    Get.off(HomeScreen());
    // }
  }

  void logout(BuildContext context) {
    storageClear();
    try {
      context.read<LoginProvider>().resetState();
    } catch (e) {
      debugPrint("Error resetting LoginProvider: $e");
    }
    Routes.goToPage(RoutesName.login, "Login");
  }

  // Future<ValidateDeviceModel> verifyDevice() async {
  //   final UserModel userData = await getUserData();
  //   final LoginModel login = await getLoginData();
  //   String deviceId = await getDeviceId();
  //   final params = <String, String>{
  //     "prmconstring": login.companyid.toString(),
  //     "prmusercode": userData.usercode.toString(),
  //     "prmpassword": userData.password.toString(),
  //     "prmappversion": ENV.appVersion,
  //     "prmapp": ENV.appName,
  //     // "prmdeviceid": getUuid(),
  //     "prmdeviceid": deviceId,
  //     "prmsessionid": userData.sessionid.toString(),
  //     "prmappplatform": Platform.isAndroid ? "ANDROID" : "IOS",
  //   };

  //   final hasInternet = await NetworkStatusService().hasConnection;

  //   if (!hasInternet) {
  //     throw Exception("No Internet available");
  //   }

  //   try {
  //     final CommonResponse resp =
  //         await apiPost("${loginBaseUrl}ValidateDevice", params);

  //     if (resp.commandStatus != 1) {
  //       throw Exception(
  //         resp.commandMessage ?? "Device validation failed",
  //       );
  //     }

  //     final Map<String, dynamic> rawMap = await compute(
  //       parseValidateDeviceIsolate,
  //       resp.dataSet.toString(),
  //     );

  //     final ValidateDeviceModel response = ValidateDeviceModel.fromJson(rawMap);
  //     return response;
  //   } on SocketException {
  //     throw Exception("No Internet");
  //   }
  // }
 Future<ValidateDeviceModel> verifyDevice() async {
  final UserModel userData = await getUserData();
  final LoginModel login = await getLoginData();
  final String deviceId = await getDeviceId();

  final params = <String, String>{
    "prmconstring": login.companyid.toString(),
    "prmusercode": userData.usercode.toString(),
    "prmpassword": userData.password.toString(),
    "prmappversion": ENV.appVersion,
    "prmapp": ENV.appName,
    "prmdeviceid": deviceId,
    "prmsessionid": userData.sessionid.toString(),
    "prmappplatform": Platform.isAndroid ? "ANDROID" : "IOS",
  };

  final hasInternet =
      await NetworkStatusService().hasConnection;

  if (!hasInternet) {
    throw Exception("No Internet available");
  }

  try {
    final CommonResponse resp =
        await apiPost("${loginBaseUrl}ValidateDevice", params);

    final result = ApiResponse.get(resp);

    if (!result.success) {
      throw Exception(
        result.errorMessage ?? "Device validation failed",
      );
    }

    final Map<String, dynamic> resultData = result.data!;

    // Get actual ValidateDevice data from Table
    final dynamic table = resultData["Table"];

    if (table.isNotEmpty) {
      final ValidateDeviceModel response =
          ValidateDeviceModel.fromJson(
        Map<String, dynamic>.from(table.first),
      );

      return response;
    }

    throw Exception("Device validation data not available");

  } on SocketException {
    throw Exception("No Internet");
  }
}

 Future<void> validateDevice(BuildContext context) async {
  try {
    final ValidateDeviceModel response = await verifyDevice();

    if (response.validlogin == "N") {
      failToast(
        response.commandmessage ?? "Invalid login.",
      );

      logout(context);
      return;
    }

    if (response.singledevice == "N") {
      failToast(
        response.commandmessage ?? "Device is already logged in another device.",
      );
      logout(context);
      return;
    }

    if (response.requiredaupdate == "Y") {
      storageClear();
      Get.offAll(const UpdateVersionScreen());
      return;
    }

    // Device validation successful
  } catch (err) {
    failToast(err.toString());
    logout(context);
  }
}
}
