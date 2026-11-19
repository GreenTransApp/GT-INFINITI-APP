import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:gtlmd/base/BaseRepository.dart';
import 'package:gtlmd/common/Colors.dart';
import 'package:gtlmd/common/alertBox/loadingAlertWithCancel.dart';
import 'package:gtlmd/common/toast.dart';
import 'package:gtlmd/common/utils.dart';
import 'package:gtlmd/design_system/size_config.dart';
import 'package:gtlmd/pages/deliveryDetail/Model/deliveryDetailModel.dart';
import 'package:gtlmd/pages/podEntry/Model/stickerModel.dart';
import 'package:gtlmd/pages/podEntry/podEntryViewModel.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

class ScanAndLoad extends StatefulWidget {
  List<PodStickerModel> stickersList;
  final DeliveryDetailModel deliveryDetailModel;
  ScanAndLoad(
      {super.key,
      required this.stickersList,
      required this.deliveryDetailModel});

  @override
  State<ScanAndLoad> createState() => _ScanAndLoadState();
}

class _ScanAndLoadState extends State<ScanAndLoad> {
  bool _selectAll = false;
  late LoadingAlertService loadingAlertService;
  PodEntryViewModel viewModel = PodEntryViewModel();
  List<PodStickerModel> selectedStickers = [];
  List<PodStickerModel> unSelectedStickersList = [];
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;
  bool showScan = false;
  List<PodStickerModel> stickersList = [];
  List<PodStickerModel> filteredStickers = [];
  BaseRepository baseRepo = BaseRepository();
  final TextEditingController _searchController = TextEditingController();
  DeliveryDetailModel modelDetail = DeliveryDetailModel();
  @override
  initState() {
    super.initState();
    setObservers();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => loadingAlertService = LoadingAlertService(context: context));
    stickersList = widget.stickersList;
    modelDetail = widget.deliveryDetailModel;
    filteredStickers = stickersList;
    baseRepo.scanBarcode();
  }

  setObservers() {
    viewModel.viewDialog.stream.listen((showLoading) {
      if (showLoading) {
        loadingAlertService.showLoading();
      } else {
        loadingAlertService.hideLoading();
      }
    });

    viewModel.isErrorLiveData.stream.listen((errMsg) {
      if (isNullOrEmpty(errMsg)) {
        failToast("Something went wrong");
      } else {
        failToast(errMsg.toString());
      }
    });

    viewModel.updatedstickerLiveData.stream.listen((resp) {
      if (resp.commandstatus == 1) {
        successToast("Sticker Scaned successful");
        // selectGr(resp.stickerno.toString());
      } else {
        failToast(resp.commandmessage!.toString() ?? "Something went wrong");
      }
    });
  }

  void updatePodSticker(List<PodStickerModel> stickersList) {
    List<String> stickerNoList = List.empty(growable: true);
    for (int i = 0; i < stickersList.length; i++) {
      PodStickerModel listData = stickersList[i];
      stickerNoList.add(listData.stickerno.toString());
    }

    Map<String, dynamic> params = {
      "prmcompanyid": savedUser.companyid.toString(),
      "prmusercode": savedUser.usercode.toString(),
      "prmbranchcode": savedUser.loginbranchcode.toString(),
      "prmgrno":isNullOrEmpty(modelDetail.generatedGr) ?  modelDetail.grno.toString():modelDetail.generatedGr.toString(),
      "prmstickerno": stickerNoList.join(",") + ",",
      "prmmanifestno": modelDetail.manifestno.toString(),
      "prmsessionid": savedUser.sessionid.toString(),
    };

    // loadingAlertService.showLoading();

    viewModel.updateScanedSticker(params);
  }

  void _applyFilterAndSort({String? query}) {
    final searchQuery = query ?? _searchController.text;

    // Filtering
    List<PodStickerModel> result = stickersList;
    if (searchQuery.isNotEmpty) {
      result = stickersList
          .where((sticker) => sticker.stickerno!
              .toLowerCase()
              .contains(searchQuery.toLowerCase()))
          .toList();
    } else {
      result = List.from(stickersList);
    }

    // Sorting: Selected items first, then alphabetically/original order
    result.sort((a, b) {
      if (a.isreceived == b.isreceived) return 0;
      return a.isreceived == true ? -1 : 1;
    });

    setState(() {
      filteredStickers = result;
    });
  }

  void _filterStickers(String query) {
    _applyFilterAndSort(query: query);
  }

  void _toggleSelectAll() {
    setState(() {
      _selectAll = !_selectAll;
      for (var item in stickersList) {
        item.isreceived = _selectAll;
      }
    });
    _applyFilterAndSort();
  }

  selectGr(Barcode gr) {
    // selectGr(String scanedSticker) {
    for (PodStickerModel sticker in stickersList) {
      if (sticker.stickerno == gr.code) {
        if (sticker.isreceived == true) {
          selectedStickers.remove(sticker);
          unSelectedStickersList.add(sticker);
          sticker.isreceived = false;
        } else {
          selectedStickers.add(sticker);
          unSelectedStickersList.remove(sticker);
          sticker.isreceived = true;
        }
      }else{
          failToast("Sticker not found in the list");
      }
    }
    _applyFilterAndSort();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
        selectGr(scanData);
        // updatePodSticker(scanData.code.toString());
        showScan = false;
      });
    });
  }

  Widget _buildSummaryCard() {
    int total = stickersList.length;
    int selected = stickersList.where((s) => s.isreceived == true).length;
    int remaining = total - selected;
    double progress = total > 0 ? selected / total : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).toInt()),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStat("Total", total.toString(), Colors.blue),
              _buildStat("Deliver", selected.toString(), Colors.green),
              _buildStat("Pending", remaining.toString(), Colors.orange),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor:
                  AlwaysStoppedAnimation<Color>(CommonColors.colorPrimary!),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: CommonColors.colorPrimary,
        foregroundColor: CommonColors.White,
        title: const Text('Scan And Load'),
        actions: [
          IconButton(
            icon: Icon(
                _selectAll ? Icons.check_box : Icons.check_box_outline_blank),
            onPressed: _toggleSelectAll,
            tooltip: "Toggle Select All",
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSummaryCard(),
            if (showScan)
              Container(
                height: 200,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: CommonColors.colorPrimary!, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: QRView(
                    key: qrKey,
                    onQRViewCreated: _onQRViewCreated,
                    overlay: QrScannerOverlayShape(
                      borderColor: CommonColors.colorPrimary!,
                      borderRadius: 10,
                      borderLength: 30,
                      borderWidth: 10,
                      cutOutSize: 150,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                onChanged: _filterStickers,
                decoration: InputDecoration(
                  hintText: "Search Sticker No.",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
            Expanded(
              child: filteredStickers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.isNotEmpty
                                ? 'No matching stickers'
                                : 'Sticker list is empty',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: filteredStickers.length,
                      itemBuilder: (context, index) {
                        var data = filteredStickers[index];
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: data.isreceived == true
                                  ? Colors.green.withAlpha((0.5 * 255).toInt())
                                  : Colors.grey.shade200,
                            ),
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: data.isreceived == true
                                    ? Colors.green
                                        .withAlpha((0.1 * 255).toInt())
                                    : Colors.blue
                                        .withAlpha((0.1 * 255).toInt()),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                data.isreceived == true
                                    ? Icons.qr_code_scanner
                                    : Icons.qr_code,
                                color: data.isreceived == true
                                    ? Colors.green
                                    : Colors.blue,
                              ),
                            ),
                            title: Text(
                              data.stickerno!,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            trailing: Checkbox(
                              activeColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4)),
                              value: data.isreceived,
                              onChanged: (value) {
                                Barcode barcode = Barcode(
                                  data.stickerno!,
                                  BarcodeFormat.qrcode,
                                  data.stickerno!.codeUnits,
                                );
                                selectGr(barcode);
                                // updatePodSticker(barcode.code.toString());
                              },
                            ),
                            onTap: () {
                              Barcode barcode = Barcode(
                                data.stickerno!,
                                BarcodeFormat.qrcode,
                                data.stickerno!.codeUnits,
                              );
                              selectGr(barcode);
                              // updatePodSticker(barcode.code.toString());
                            },
                          ),
                        );
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.05 * 255).toInt()),
                    offset: const Offset(0, -5),
                    blurRadius: 10,
                  )
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // Collect current state of stickers
                            final selected = stickersList
                                .where((s) => s.isreceived == true)
                                .toList();
                            final unselected = stickersList
                                .where((s) => s.isreceived == false)
                                .toList();

                            // Navigator.of(context).pop({
                            //   "selected": selected,
                            //   "unselected": unselected
                            // });
                            updatePodSticker(selected);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: CommonColors.colorPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "LOAD SELECTED ITEMS",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: SizeConfig.smallHorizontalSpacing),
                    InkWell(
                      onTap: () {
                        setState(() {
                          showScan = !showScan;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: CommonColors.colorPrimary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          showScan
                              ? Icons.camera_alt
                              : Icons.camera_alt_outlined,
                          color: CommonColors.White,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
