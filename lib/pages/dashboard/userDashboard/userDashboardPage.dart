import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gtlmd/common/Colors.dart';
import 'package:gtlmd/common/Toast.dart';
import 'package:gtlmd/common/Utils.dart';
import 'package:gtlmd/common/alertBox/loadingAlertWithCancel.dart';

import 'package:gtlmd/common/navDrawer/navDrawer.dart';
import 'package:gtlmd/design_system/size_config.dart';
import 'package:gtlmd/pages/dashboard/userDashboard/userDashBoardViewModel.dart';
import 'package:gtlmd/pages/home/Model/menuModel.dart';
import 'package:gtlmd/pages/home/Model/moduleModel.dart';
import 'package:gtlmd/pages/home/homeScreenPage.dart';

class UserDashboardPage extends StatefulWidget {
  const UserDashboardPage({super.key});

  @override
  State<UserDashboardPage> createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage> {
  UserDashboardViewModel _viewModel = UserDashboardViewModel();
  List<ModulesModel> moduleList = List.empty(growable: true);
  List<MenuModel> menuList = List.empty(growable: true);
  List<MenuModel> menuTypeList = List.empty(growable: true);
  List<MenuModel> filteredMenuList = List.empty(growable: true);
  late LoadingAlertService loadingAlertService;
  String selectedModule = 'OPERATIONS';
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadingAlertService = LoadingAlertService(context: context);
    });
    setObservers();
    dataSetUp();
  }

  dataSetUp() {
    getUserData().then((user) => {
          if (user.commandstatus == null || user.commandstatus == -1)
            {
              authService.logout(context),
              throw Exception("User data not found.")
            }
          else
            {
              if (isNullOrEmpty(user.drivercode))
                {
                  authService.validateDevice(context),
                  getModules(),
                }
              else
                {
                  Get.off(HomeScreen()),
                }
            }
        });
  }

  setObservers() {
    _viewModel.loadingDialog.stream.listen((show) {
      show
          ? loadingAlertService.showLoading()
          : loadingAlertService.hideLoading();
    });

    _viewModel.errorDialog.stream.listen((error) {
      failToast(error);
    });

    _viewModel.moduleLiveData.stream.listen((listData) {
      if (listData.isNotEmpty) {
        setState(() {
          moduleList = listData;
          getMenu();
        });
      } else {
        moduleList.clear();
      }
    });
    _viewModel.menuLiveData.stream.listen((listData) {
      if (listData.isNotEmpty) {
        setState(() {
          menuList = listData;
          filteredMenuList.clear();
          //  for (int i = 0; i < menuList.length; i++) {
          //   if (selectedModule == menuList.elementAt(i).modulename) {
          //     filteredMenuList.add(menuList.elementAt(i));
          //   }
          //    }
          for (var items in menuList) {
            var menuCode = items.menucode ?? '';
            if (items.page == 'NO_DISPLAY' || items.exestr == 'NO_DISPLAY') {
              debugPrint("NO_DISPLAY PAGE: ${items.menuname}");
              continue;
            }
            if (items.menucode == 'GTAPP_OPENDAILYLOG') {
              debugPrint("GTAPP_OPENDAILYLOG: ${items.menuname}");
            }
            if (selectedModule == items.modulename) {
              if (items.menucode!.contains('WMSAPP')) {
                debugPrint("${items.menuname}");
                continue;
              }

              if (items.menutype == "MENU") {
                menuTypeList.add(items);
              } else {
                if (menuCode.indexOf('GTAPPLX') >= 0) {
                  continue;
                } else {
                  filteredMenuList.add(items);
                }
              }
            }
          }
        });
      } else {
        menuList.clear();
      }
    });
  }

  Future<void> getModules() async {
    Map<String, String> params = {
      "prmconnstring": savedUser.companyid.toString(),
      "prmapp": "GREENTRANS",
    };
    await _viewModel.getModuleList(params);
  }

  Future<void> getMenu() async {
    Map<String, String> params = {
      "prmconstring": savedUser.companyid.toString(),
      "prmusercode": savedUser.usercode.toString(),
      "prmapp": "GREENTRANS",
    };
    await _viewModel.getMenu(params);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          drawerEnableOpenDragGesture: true,
          appBar: AppBar(
            backgroundColor: CommonColors.colorPrimary,
            automaticallyImplyLeading: false,
            title: Text(
              'Home',
              style: TextStyle(
                  color: CommonColors.white,
                  fontSize: SizeConfig.extraLargeIconSize),
            ),
          ),
          drawer: SideMenu(),
          body: Column(
            children: [
              SizedBox(
                height: SizeConfig.screenHeight * 0.1,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: moduleList.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 16),
                      child: Container(
                        width: SizeConfig.screenWidth * 0.3,
                        decoration: BoxDecoration(
                          color: CommonColors.colorPrimary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                            child: Text(moduleList[index].modulename ?? "")),
                      ),
                    );
                  },
                ),
              ),
              // Expanded(
              //   child: ListView.builder(
              //     itemCount: filteredMenuList.length,
              //     itemBuilder: (context, index) {
              //       return ListTile(
              //         title: Text(filteredMenuList[index].displayname ?? ""),
              //       );
              //     },
              //   ),
              // ),
              Expanded(
                  child: ListView.builder(
                      itemCount: menuTypeList.length,
                      itemBuilder: ((context, index) {
                        final group = menuTypeList[index];
                        final groupItems = filteredMenuList
                            .where((item) => item.parentcode == group.menucode)
                            .toList();
                        if (groupItems.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                            padding: EdgeInsets.symmetric(horizontal:SizeConfig.smallHorizontalPadding, vertical: SizeConfig.smallVerticalPadding),
                              child: Text(
                                group.displayname ?? "",
                                style: TextStyle(
                                    fontSize: SizeConfig.smallTextSize,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            ...groupItems.map((item) => ListTile(
                                  title: Container(
                                    padding: EdgeInsets.symmetric(horizontal:SizeConfig.smallHorizontalPadding, vertical: SizeConfig.smallVerticalPadding),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: const Color(0xFFCCCCCC)),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(item.displayname ?? "")),
                                ))
                          ],
                        );
                      })))
            ],
          )),
    );
  }
}
