  import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:gtlmd/api/HttpCalls.dart';
import 'package:gtlmd/base/BaseRepository.dart';
import 'package:gtlmd/common/commonResponse.dart';

import 'package:gtlmd/pages/home/Model/menuModel.dart';
import 'package:gtlmd/pages/home/Model/moduleModel.dart';
import 'package:gtlmd/service/connectionCheckService.dart';

class UserDashboardRepository  extends BaseRepository {
  final StreamController<List<ModulesModel>> moduleList =
      StreamController();
  final StreamController<List<MenuModel>> menuList =
      StreamController();
  final StreamController<bool> loadingDialog = StreamController();
  final StreamController<String> errorDialog = StreamController();


 getModuleList(Map<String, String> params) async {
    loadingDialog.add(true);
    final hasInternet = await NetworkStatusService().hasConnection;

    if (hasInternet) {
      try {
        CommonResponse resp =
            await apiGet("${homeBaseUrl}getAppModules", params);
        if (resp.commandStatus == 1) {
          Map<String, dynamic> table = jsonDecode(resp.dataSet.toString());
          Iterable<MapEntry<String, dynamic>> entries = table.entries;
          for (final entry in entries) {
            if (entry.key == "Table") {
              List<dynamic> list1 = entry.value;
              List<ModulesModel> resultList = List.generate(
                  list1.length,
                  (index) => ModulesModel.fromJson(list1[index]));
              if (resultList.isNotEmpty) {
                moduleList.add(resultList);
              } else {
                moduleList.add([]);
              }
            }
          }
        } else {
          errorDialog.add(resp.commandMessage!);
        }
        loadingDialog.add(false);
      } on SocketException catch (_) {
        errorDialog.add("No Internet");
        loadingDialog.add(false);
      } catch (err) {
        errorDialog.add(err.toString());
        loadingDialog.add(false);
      }
      loadingDialog.add(false);
    } else {
      loadingDialog.add(false);
      errorDialog.add("No Internet available");
    }
  }

 getMenu(Map<String, String> params) async {
    loadingDialog.add(true);
    final hasInternet = await NetworkStatusService().hasConnection;

    if (hasInternet) {
      try {
        CommonResponse resp =
            await apiGet("${homeBaseUrl}getMenu", params);
        if (resp.commandStatus == 1) {
          Map<String, dynamic> table = jsonDecode(resp.dataSet.toString());
          Iterable<MapEntry<String, dynamic>> entries = table.entries;
          for (final entry in entries) {
            if (entry.key == "Table") {
              List<dynamic> list1 = entry.value;
              List<MenuModel> resultList = List.generate(
                  list1.length,
                  (index) => MenuModel.fromJson(list1[index]));
              if (resultList.isNotEmpty) {
                menuList.add(resultList);
              } else {
                menuList.add([]);
              }
            }
          }
        } else {
          errorDialog.add(resp.commandMessage!);
        }
        loadingDialog.add(false);
      } on SocketException catch (_) {
        errorDialog.add("No Internet");
        loadingDialog.add(false);
      } catch (err) {
        errorDialog.add(err.toString());
        loadingDialog.add(false);
      }
      loadingDialog.add(false);
    } else {
      loadingDialog.add(false);
      errorDialog.add("No Internet available");
    }
  }

  }