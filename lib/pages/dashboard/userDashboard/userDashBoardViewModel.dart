import 'dart:async';

import 'package:gtlmd/base/baseViewModel.dart';
import 'package:gtlmd/pages/dashboard/userDashboard/userDashboardRepository.dart';
import 'package:gtlmd/pages/home/Model/menuModel.dart';
import 'package:gtlmd/pages/home/Model/moduleModel.dart';

class UserDashboardViewModel extends BaseViewModel {
UserDashboardRepository  _repo = UserDashboardRepository();
  StreamController<List<ModulesModel>> moduleLiveData = StreamController();
  StreamController<List<MenuModel>> menuLiveData = StreamController();
  StreamController<bool> loadingDialog = StreamController<bool>();
  StreamController<String> errorDialog = StreamController<String>();

UserDashboardViewModel() {
    loadingDialog = _repo.loadingDialog;
    errorDialog = _repo.errorDialog;
    menuLiveData = _repo.menuList;
    moduleLiveData = _repo.moduleList;
  }

Future<void> getModuleList(Map<String, String> params) async {
    await _repo.getModuleList(params);
  }

Future<void> getMenu(Map<String, String> params) async {
    await _repo.getMenu(params);
  }
}

