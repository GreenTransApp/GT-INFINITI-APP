import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gtlmd/bottomSheet/multiImageBottomSheet.dart';
import 'package:gtlmd/bottomSheet/signatureBottomSheet.dart';
import 'package:gtlmd/common/Toast.dart';
import 'package:gtlmd/common/Utils.dart';
import 'package:gtlmd/common/colors.dart';
import 'package:gtlmd/common/genericBottomSheet.dart';
import 'package:gtlmd/common/imagePicker/alertBoxImagePicker.dart';
import 'package:gtlmd/design_system/size_config.dart';
import 'package:gtlmd/pages/otexPickupScreen/models/OtexPickupSplitInfo.dart';
import 'package:gtlmd/pages/otexPickupScreen/OtexPickupProvider.dart';

import 'package:gtlmd/pages/otexPickupScreen/widgets/lovPickerField.dart';
import 'package:gtlmd/pages/pickup/model/CngrCngeModel.dart';
import 'package:gtlmd/pages/pickup/model/branchModel.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class OtexPickupCard extends StatefulWidget {
  final int index;

  // No controller prop — reads from Provider directly.
  // No isFreightVisible prop — derived from state inside.
  // No onDelete prop — derived from state inside.
  const OtexPickupCard({
    super.key,
    required this.index,
  });

  @override
  State<OtexPickupCard> createState() => _OtexPickupCardState();
}

class _OtexPickupCardState extends State<OtexPickupCard> {
  bool _isCardExpanded = true;
  bool _isSaving = false;
  bool _isPrintingLabel = false;
  bool _isPrintingWaybill = false;

  // Only real text input controllers — LOV fields are gone
  final TextEditingController _palletQtyController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _freightController = TextEditingController();

  // Track what we've synced to avoid overwriting user edits mid-session
  bool _initialSyncDone = false;
  String? selected;
  // String? _itemImagePath = "";
  List<String> bookingImages = [];
  String _selectedSignaturePath = '';
  bool? sendWhatsapp = false;

  @override
  void initState() {
    super.initState();
    // Sync once after first frame so provider is available
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncFromState());
    
  }

  void _syncFromState() {
    
    // if (_initialSyncDone || !mounted) return;
    final provider = context.read<OtexPickupProvider>();
    final cards = provider.state.splitInfo;

    if (_selectedSignaturePath.isEmpty &&
        (provider.state.info.signimagepath?.isNotEmpty ?? false)) {
      _selectedSignaturePath = provider.state.info.signimagepath!;
    }
    if (widget.index >= cards.length) return;
    // if (imgData.length > 0) {
    //   for (int i = 0; i <= imgData.length; i++) {
    //     bookingImages.add(imgData[i].imagePath ?? "");
    //   }
    // }

    final card = cards[widget.index];
    _palletQtyController.text = card.palletQty?.toString() ?? "0";
    _weightController.text = card.weight?.toString() ?? "";
    _freightController.text = card.freightAmt?.toString() ?? "";


    _initialSyncDone = true;
  }

  @override
  void dispose() {
    _palletQtyController.dispose();
    _weightController.dispose();
    _freightController.dispose();
    super.dispose();
  }

  // ── Sheet openers ──────────────────────────────────────────

  void _openDestinationSheet(
      BuildContext context, OtexPickupProvider provider) {
    showGenericApiBottomSheet<BranchModel>(
      context: context,
      title: "Search Destination",
      fetchItems: (query) => provider.searchBranches(query),
      itemTitle: (b) => b.stnName ?? 'Unknown',
      itemSubtitle: (b) => "Code: ${b.stnCode ?? ''} | Zip: ${b.zipCode ?? ''}",
      onSelected: (b) {
        final card = provider.state.splitInfo[widget.index];
        provider.updateCardData(
          widget.index,
          card.copyWith(destName: b.stnName, destCode: b.stnCode),
        );
      },
    );
  }

  void _openConsigneeSheet(BuildContext context, OtexPickupProvider provider) {
    showGenericApiBottomSheet<CngrCngeModel>(
      context: context,
      title: "Search Consignee",
      fetchItems: (query) => provider.searchCngrCnge(query, 'E'),
      itemTitle: (c) => c.name ?? 'Unknown',
      itemSubtitle: (c) => "Code: ${c.code ?? ''}",
      onSelected: (c) {
        final card = provider.state.splitInfo[widget.index];
        provider.updateCardData(
          widget.index,
          card.copyWith(cngeName: c.name, cngeCode: c.code),
        );
      },
    );
  }

  // ── Actions ────────────────────────────────────────────────

  Future<void> _handleSave(OtexPickupProvider provider) async {
    // Basic card-level validation before hitting provider
    final card = provider.state.splitInfo[widget.index];
    // if (card.destCode == null || card.destCode!.isEmpty) {
    //   _showValidationSnack("Please select a Destination");
    //   return;
    // }
    // if (card.cngeCode == null || card.cngeCode!.isEmpty) {
    //   _showValidationSnack("Please select a Consignee");
    //   return;
    // }
    // if (card.packingMethodCode == null || card.packingMethodCode!.isEmpty) {
    //   _showValidationSnack("Please select a Packing Method");
    //   return;
    // }
    // if (card.saidToContainCode == null || card.saidToContainCode!.isEmpty) {
    //   _showValidationSnack("Please select Said To Contain");
    //   return;
    // }
    final palletQty = int.tryParse(_palletQtyController.text) ?? 0;
    if (palletQty <= 0) {
      _showValidationSnack("Pallet Quantity must be greater than 0");
      return;
    }
    // final isFreightVisible = provider.state.info.bookingTypeCode == "PP";
    // if (isFreightVisible) {
    //   final freight = double.tryParse(_freightController.text) ?? 0;
    //   if (freight <= 0) {
    //     _showValidationSnack("Freight Amount must be greater than 0");
    //     return;
    //   }
    // }
    if (bookingImages.isEmpty) {
      _showValidationSnack("Please upload booking image");
      return;
    }

    if (isNullOrEmpty(_selectedSignaturePath)) {
      _showValidationSnack("Please upload signature");
      return;
    }
    setState(() => _isSaving = true);
    final success = await provider.saveCardEntry(
        widget.index, bookingImages, _selectedSignaturePath,sendWhatsapp?? false);
    if (mounted) setState(() => _isSaving = false);

    if (success && mounted) {
      // Auto-collapse on successful save — clean UX signal to user
      // setState(() => _isCardExpanded = false);
    }
  }

  Future<void> _handlePrintLabel(OtexPickupProvider provider) async {
    setState(() => _isPrintingLabel = true);
    await provider.printLabel(widget.index);
    if (mounted) setState(() => _isPrintingLabel = false);
  }

  Future<void> _handlePrintWaybill(OtexPickupProvider provider) async {
    setState(() => _isPrintingWaybill = true);
    await provider.printWaybill(widget.index);
    if (mounted) setState(() => _isPrintingWaybill = false);
  }

  void _handleClear(OtexPickupProvider provider, bool isSaved) {
    _palletQtyController.text = "0";
    _weightController.clear();
    _freightController.clear();
    // _itemImagePath = "";
    bookingImages.clear();
    _selectedSignaturePath = "";
    // Preserve waybill and isSaved when clearing — only reset editable fields
    final current = provider.state.splitInfo[widget.index];
    provider.updateCardData(
      widget.index,
      OtexPickupSplitInfo(
        wayBillNo: current.wayBillNo, // keep waybill
        isSaved: current.isSaved, // keep saved status
      ),
    );
  }

  void _showValidationSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
                child: Text(message, style: const TextStyle(fontSize: 13))),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Selector: this card only rebuilds when ITS slot in the list changes,
    // or when bookingTypeCode changes (freight visibility).
    // Other cards saving won't cause this card to rebuild.


    return Selector<OtexPickupProvider,
        ({OtexPickupSplitInfo card, bool isFreightVisible, bool canDelete})>(
      selector: (_, p) {
  //       if (isNullOrEmpty(_selectedSignaturePath)&&
  //     !isNullOrEmpty(p.state.info.signimagepath?.toString())) {
  //   _selectedSignaturePath = p.state.info.signimagepath!;
  // }
        // _selectedSignaturePath = p.state.info.signimagepath.toString();
        final cards = p.state.splitInfo;
        final card = widget.index < cards.length
            ? cards[widget.index]
            : OtexPickupSplitInfo();
        return (
          card: card,
          isFreightVisible: p.state.info.bookingTypeCode == "PP",
          // Can delete only if: more than 1 card total AND this card is not saved
          canDelete:
              cards.length > 1 && widget.index >= p.state.permanentCardCount,
        );
      },
      builder: (context, data, _) {
        final card = data.card;
        final isFreightVisible = data.isFreightVisible;
        final canDelete = data.canDelete;
        final isSaved = card.isSaved;
        final provider = context.read<OtexPickupProvider>();
        if (_palletQtyController.text != (card.palletQty?.toString() ?? "")) {
          _palletQtyController.text = card.palletQty?.toString() ?? "";
        }

        if (_weightController.text != (card.weight?.toString() ?? "")) {
          _weightController.text = card.weight?.toString() ?? "";
        }

        if (_freightController.text != (card.freightAmt?.toString() ?? "")) {
          _freightController.text = card.freightAmt?.toString() ?? "";
        }

        if (_selectedSignaturePath.isEmpty &&
            (provider.state.info.signimagepath?.isNotEmpty ?? false)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;

            setState(() {
              _selectedSignaturePath = provider.state.info.signimagepath!;
            });
          });
        }
        return Card(
          surfaceTintColor: Colors.white,
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            // Green border when saved — instant visual feedback
            side: BorderSide(
              color: isSaved
                  ? Colors.green.shade400
                  : (CommonColors.grey400 ?? Colors.grey),
              width: isSaved ? 1.5 : 0.5,
            ),
          ),
          child: Column(
            children: [
              // ── Card Header ──
              _buildCardHeader(provider, card, isSaved, canDelete),

              // ── Card Body ──
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState: _isCardExpanded
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                secondChild: const SizedBox.shrink(),
                firstChild: _buildCardBody(
                  context,
                  provider,
                  card,
                  isSaved,
                  isFreightVisible,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCardHeader(
    OtexPickupProvider provider,
    OtexPickupSplitInfo card,
    bool isSaved,
    bool canDelete,
  ) {
    return InkWell(
      onTap: () => setState(() => _isCardExpanded = !_isCardExpanded),
      borderRadius: BorderRadius.vertical(
        top: const Radius.circular(12),
        bottom: Radius.circular(_isCardExpanded ? 0 : 12),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: SizeConfig.smallVerticalPadding,
          horizontal: SizeConfig.mediumHorizontalSpacing,
        ),
        decoration: BoxDecoration(
          // Subtle green tint on header when saved
          color: isSaved ? Colors.green.shade50 : Colors.blueGrey.shade50,
          borderRadius: BorderRadius.vertical(
            top: const Radius.circular(12),
            bottom: Radius.circular(_isCardExpanded ? 0 : 12),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor:
                  isSaved ? Colors.green.shade600 : CommonColors.colorPrimary,
              child: isSaved
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : Text(
                      "${widget.index + 1}",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Consignment Entry ${widget.index + 1}",
                    style: TextStyle(
                      fontSize: SizeConfig.smallTextSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.blueGrey.shade800,
                    ),
                  ),
                  // Show waybill inline on header when saved — user sees it collapsed
                  if (isSaved && card.wayBillNo != null)
                    Text(
                      "WB: ${card.wayBillNo}",
                      style: TextStyle(
                        fontSize: SizeConfig.extraSmallTextSize,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            if (canDelete)
              IconButton(
                icon: Icon(Icons.delete_outline,
                    color: CommonColors.red, size: 20),
                onPressed: () => context
                    .read<OtexPickupProvider>()
                    .removeCardEntry(widget.index),
              ),
            Icon(
              _isCardExpanded
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              color: Colors.blueGrey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardBody(
    BuildContext context,
    OtexPickupProvider provider,
    OtexPickupSplitInfo card,
    bool isSaved,
    bool isFreightVisible,
  ) {
    return Container(
      color: CommonColors.White,
      padding: EdgeInsets.all(SizeConfig.mediumHorizontalSpacing),
      child: Column(
        children: [
          // 1. Waybill — always disabled, server-generated
          _buildFormField(
            label: "WayBill Number",
            isRequired: false,
            icon: Icons.receipt_long_outlined,
            child: LovPickerField(
              value: card.wayBillNo,
              placeholder: "To Be Generated",
              onTap: null, // always locked
            ),
          ),
          SizedBox(height: SizeConfig.mediumVerticalSpacing),

          // 2. Destination
          _buildFormField(
            label: "Destination",
            isRequired: true,
            icon: Icons.pin_drop_outlined,
            child: LovPickerField(
              value: card.destName,
              placeholder: "Select Destination",
              onTap: null,
              // onTap: () => _openDestinationSheet(context, provider),
            ),
          ),
          SizedBox(height: SizeConfig.mediumVerticalSpacing),

          // 3. Consignee
          _buildFormField(
            label: "Consignee",
            isRequired: true,
            icon: Icons.person_pin_outlined,
            child: LovPickerField(
              value: card.cngeName,
              placeholder: "Select Consignee",
              onTap: null,
              // onTap: () => _openConsigneeSheet(context, provider),
            ),
          ),
          SizedBox(height: SizeConfig.mediumVerticalSpacing),

          // 4. Pallet Qty + Weight
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildFormField(
                  label: "Pallet Qty",
                  isRequired: true,
                  icon: Icons.grid_view_outlined,
                  child: TextFormField(
                    controller: _palletQtyController,
                    enabled: !provider.state.isReadOnly,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      // Blocks 0 as first character
                      // FilteringTextInputFormatter.deny(RegExp(r'^0')),
                    ],
                    decoration: _inputDecoration("Qty"),
                    onChanged: (val) {
                      final parsed = int.tryParse(val) ?? 0;
                      final current = provider.state.splitInfo[widget.index];
                      provider.updateCardData(
                          widget.index, current.copyWith(palletQty: parsed));
                    },
                  ),
                ),
              ),
              SizedBox(width: SizeConfig.mediumHorizontalSpacing),
              Expanded(
                child: _buildFormField(
                  label: "Weight (KG)",
                  isRequired: true,
                  icon: Icons.monitor_weight_outlined,
                  child: TextFormField(
                    controller: _weightController,
                    enabled: false,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}$')),
                    ],
                    decoration: _inputDecoration("KG"),
                    // onChanged: (val) {
                    //   final parsed = double.tryParse(val) ?? 0;
                    //   final current = provider.state.splitInfo[widget.index];
                    //   provider.updateCardData(
                    //       widget.index, current.copyWith(weight: parsed));
                    // },
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.mediumVerticalSpacing),

          // 5. Packing Method + Said To Contain
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildFormField(
                  label: "Packing",
                  isRequired: true,
                  icon: Icons.workspaces_outline,
                  child: LovPickerField(
                    value: card.packingMethodName,
                    placeholder: "Select",
                    onTap: null,
                    // onTap: () => _openPackingMethodSheet(context, provider),
                  ),
                ),
              ),
              SizedBox(width: SizeConfig.mediumHorizontalSpacing),
              Expanded(
                child: _buildFormField(
                  label: "Said To Contain",
                  isRequired: true,
                  icon: Icons.inventory_outlined,
                  child: LovPickerField(
                    value: card.saidToContainName,
                    placeholder: "Select",
                    onTap: null,
                    // onTap: () => _openSaidToContainSheet(context, provider),
                  ),
                ),
              ),
            ],
          ),

          // 6. Freight — only when booking type is PP
          if (isFreightVisible) ...[
            SizedBox(height: SizeConfig.mediumVerticalSpacing),
            _buildFormField(
              label: "Freight Amount",
              isRequired: true,
              icon: Icons.currency_rupee_outlined,
              child: TextFormField(
                controller: _freightController,
                enabled: false,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}$')),
                ],
                decoration: _inputDecoration("Enter Amount"),
                // onChanged: (val) {
                //   final parsed = double.tryParse(val) ?? 0;
                //   final current = provider.state.splitInfo[widget.index];
                //   provider.updateCardData(
                //       widget.index, current.copyWith(freightAmt: parsed));
                // },
              ),
            ),
          ],

          /// upload  document
          SizedBox(height: SizeConfig.mediumVerticalSpacing),
          Container(
            padding: EdgeInsets.symmetric(
                vertical: SizeConfig.verticalPadding,
                horizontal: SizeConfig.horizontalPadding),
            decoration: BoxDecoration(
                border: Border.all(color: CommonColors.grey400!, width: 1),
                borderRadius:
                    BorderRadius.all(Radius.circular(SizeConfig.largeRadius))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.black54,
                    ),
                    SizedBox(
                      width: SizeConfig.mediumHorizontalSpacing,
                    ),
                    const Text(
                      "DOCUMENT UPLOAD",
                      style: TextStyle(color: Colors.black87),
                    ),
                    Expanded(
                        child: Align(
                      alignment: AlignmentGeometry.centerRight,
                      child: InkWell(
                        child: const Icon(
                          Icons.file_upload_outlined,
                          color: Colors.black54,
                          // size: 24,
                        ),
                        onTap: provider.state.isReadOnly
                            ? null
                            : () async {
                                // showImagePickerDialog(context, (file) async {
                                //   if (file != null) {
                                //     debugPrint(' data: ${file.path}');
                                //     setState(() {
                                //       _itemImagePath = file.path;
                                //     });
                                //   } else {
                                //     failToast("File not selected");
                                //   }
                                // });
                                List<String> imagePaths =
                                    await showMultiImageBottomSheetDialog(
                                        context, bookingImages, false);

                                bookingImages = imagePaths;
                              },
                      ),
                    ))
                  ],
                ),

                // Padding(
                //   padding: EdgeInsets.all(SizeConfig.mediumVerticalSpacing),
                //   child: SizedBox(
                //     height: 200,
                //     width: MediaQuery.sizeOf(context).width,
                //     child: Container(
                //       decoration: BoxDecoration(
                //           color: CommonColors.grey300,
                //           borderRadius: BorderRadius.all(
                //               Radius.circular(SizeConfig.largeIconSize))),
                //       child: isNullOrEmpty(_itemImagePath)
                //           ? InkWell(
                //               child: const Column(
                //                 mainAxisAlignment: MainAxisAlignment.center,
                //                 crossAxisAlignment: CrossAxisAlignment.center,
                //                 children: [
                //                   Icon(
                //                     Icons.file_upload_outlined,
                //                     color: Colors.black54,
                //                   ),
                //                   Text(
                //                     "Upload Image",
                //                     style: TextStyle(color: Colors.black87),
                //                   ),
                //                   Text(
                //                     "Click the upload button above",
                //                     style: TextStyle(color: Colors.black87),
                //                   )
                //                 ],
                //               ),
                //               onTap: () {
                //                 showImagePickerDialog(context, (file) async {
                //                   if (file != null) {
                //                     debugPrint(' data: ${file.path}');
                //                     setState(() {
                //                       _itemImagePath = file.path;
                //                     });
                //                   } else {
                //                     failToast("File not selected");
                //                   }
                //                 });
                //               },
                //             )
                //           : Image.file(
                //               File(_itemImagePath!),
                //               fit: BoxFit.contain,
                //             ),
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
          SizedBox(
            height: SizeConfig.mediumVerticalSpacing,
          ),
        
          Container(
            padding: EdgeInsets.symmetric(
                vertical: SizeConfig.verticalPadding,
                horizontal: SizeConfig.horizontalPadding),
            decoration: BoxDecoration(
                border: Border.all(color: CommonColors.grey400!, width: 1),
                borderRadius:
                BorderRadius.all(Radius.circular(SizeConfig.largeRadius))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Symbols.signature_rounded,
                      color: Colors.black54,
                    ),
                    SizedBox(
                      width: SizeConfig.mediumHorizontalSpacing,
                    ),
                    const Text(
                      "SIGNATURE UPLOAD",
                      style: TextStyle(color: Colors.black87),
                    ),


                    Expanded(
                        child: Align(
                          alignment: AlignmentGeometry.centerRight,
                          child: InkWell(
                            child: const Icon(
                              Symbols.signature_rounded,
                              color: Colors.black54,
                              // size: 24,
                            ),
                            onTap: provider.state.isReadOnly
                                ? null
                                : () {
                              showSignatureBottomSheet(context,
                                      (path, base64) {
                                    if (!isNullOrEmpty(path)) {
                                      setState(() {
                                        _selectedSignaturePath = path;
                                      });
                                    } else {
                                      failToast('Please input signature again.');
                                    }
                                  });
                            },
                          ),
                        ))
                  ],
                ),
                Padding(
                  padding: EdgeInsets.all(SizeConfig.mediumVerticalSpacing),
                  child: SizedBox(
                    height: 200,
                    width: MediaQuery.sizeOf(context).width,
                    child: Container(
                      decoration: BoxDecoration(
                          color: CommonColors.grey300,
                          borderRadius: BorderRadius.all(
                              Radius.circular(SizeConfig.largeIconSize))),
                            child: _selectedSignaturePath.isNotEmpty
                      ? (_selectedSignaturePath.startsWith("http")
                          ? Image.network(
                              _selectedSignaturePath,
                              fit: BoxFit.contain,
                            )
                          : Image.file(
                              File(_selectedSignaturePath),
                              fit: BoxFit.contain,
                            ))
                      : InkWell(
                          onTap: provider.state.isReadOnly
                              ? null
                              : () {
                                  showSignatureBottomSheet(context, (path, base64) {
                                    if (!isNullOrEmpty(path)) {
                                      setState(() {
                                        _selectedSignaturePath = path;
                                      });
                                    }
                                  });
                                },
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.file_upload_outlined),
                              Text("Click to Sign"),
                              Text("Click the signature button above"),
                            ],
                          ),
                        ),)
                                  
                  ,
                        ),
                      ),

                    ],
                  ),

          ),
          SizedBox(
            height: SizeConfig.extraSmallVerticalPadding,
          ),
         
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text("Send Whatsappp Message",style: TextStyle(fontWeight: FontWeight.bold,fontSize: SizeConfig.extraSmallTextSize)),
            Checkbox(
               activeColor: CommonColors.colorPrimary,
               value: sendWhatsapp,
               onChanged: (checked) {
                 sendWhatsapp = checked;
                 setState(() {}); }),
          ],
        ),
          SizedBox(
            height: SizeConfig.extraSmallVerticalPadding,
          ),

          // ── Buttons ──
          // const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),

          // Print row
          Row(
            children: [
              // Expanded(
              //   child: OutlinedButton.icon(
              //     // Print label only available after save
              //     onPressed: (isSaved || provider.state.isReadOnly) &&
              //             !_isPrintingLabel
              //         ? () => _handlePrintLabel(provider)
              //         : null,
              //     icon: _isPrintingLabel
              //         ? const SizedBox(
              //             width: 12,
              //             height: 12,
              //             child: CircularProgressIndicator(
              //                 strokeWidth: 2, color: CommonColors.appBarColor),
              //           )
              //         : const Icon(Icons.print_outlined, size: 14),
              //     label: Text(
              //       _isPrintingLabel ? "Printing..." : "Print Label",
              //       style: const TextStyle(fontSize: 10),
              //     ),
              //     style: OutlinedButton.styleFrom(
              //       padding: const EdgeInsets.symmetric(vertical: 10),
              //       foregroundColor: CommonColors.colorPrimary,
              //       disabledForegroundColor: Colors.grey.shade400,
              //       side: BorderSide(
              //           color: (isSaved || provider.state.isReadOnly)
              //               ? CommonColors.appBarColor
              //               : Colors.grey.shade300),
              //       shape: RoundedRectangleBorder(
              //           borderRadius: BorderRadius.circular(6)),
              //     ),
              //   ),
              // ),
              const SizedBox(width: 4),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: (isSaved || provider.state.isReadOnly) &&
                          !_isPrintingWaybill && !isNullOrEmpty(card.wayBillNo)
                      ? () => _handlePrintWaybill(provider)
                      : null,
                  icon: _isPrintingWaybill
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: CommonColors.appBarColor),
                        )
                      : const Icon(Icons.description_outlined, size: 14),
                  label: Text(
                    _isPrintingWaybill ? "Printing..." : "Print Waybill",
                    style: const TextStyle(fontSize: 10),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    foregroundColor: CommonColors.colorPrimary,
                    disabledForegroundColor: Colors.grey.shade400,
                    side: BorderSide(
                        color: (isSaved || provider.state.isReadOnly && !isNullOrEmpty(card.wayBillNo))
                            ? CommonColors.appBarColor
                            : Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ),
              // const SizedBox(width: 4),
              // Expanded(
              //   child: OutlinedButton.icon(
              //     onPressed: () => _handleClear(provider, isSaved),
              //     icon: const Icon(Icons.refresh, size: 14),
              //     label: const Text("Clear", style: TextStyle(fontSize: 10)),
              //     style: OutlinedButton.styleFrom(
              //       padding: const EdgeInsets.symmetric(vertical: 10),
              //       foregroundColor: Colors.grey.shade700,
              //       side: BorderSide(color: Colors.grey.shade400),
              //       shape: RoundedRectangleBorder(
              //           borderRadius: BorderRadius.circular(6)),
              //     ),
              //   ),
              // ),
            ],
          ),
          const SizedBox(height: 8),

          // Save button — full width, shows loader while saving
          if (!provider.state.isReadOnly)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_isSaving) ? null : () => _handleSave(provider),
                icon: _isSaving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(
                        isSaved
                            ? Icons.check_circle
                            : Icons.check_circle_outline,
                        size: 16,
                      ),
                label: Text(
                  isSaved 
                      ? 'Update Way Bill'
                      : _isSaving
                          ? "Saving..."
                          : "Save Way Bill",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: CommonColors.colorPrimary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                  elevation: 0,
                ),
              ),
            ),

          if (!provider.state.isReadOnly) const SizedBox(height: 8),
          // Vechicle Arrival button — full width,
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────

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
                size: SizeConfig.largeIconSize, color: const Color(0xFF64748B)),
            SizedBox(width: SizeConfig.extraSmallHorizontalSpacing),
            Text.rich(TextSpan(children: [
              TextSpan(
                text: label,
                style: TextStyle(
                  fontSize: SizeConfig.smallTextSize,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF334155),
                ),
              ),
              if (isRequired)
                TextSpan(
                  text: ' *',
                  style: TextStyle(
                      color: CommonColors.red, fontWeight: FontWeight.bold),
                ),
            ])),
          ],
        ),
        SizedBox(height: SizeConfig.smallVerticalSpacing),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
          color: CommonColors.grey400, fontSize: SizeConfig.smallTextSize),
      contentPadding: EdgeInsets.symmetric(
        horizontal: SizeConfig.smallHorizontalPadding,
        vertical: SizeConfig.smallVerticalPadding,
      ),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SizeConfig.largeRadius),
          borderSide: const BorderSide(color: CommonColors.appBarColor)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SizeConfig.largeRadius),
          borderSide: const BorderSide(color: CommonColors.appBarColor)),
      disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SizeConfig.largeRadius),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SizeConfig.largeRadius),
          borderSide: BorderSide(
              color:
                  CommonColors.primaryColorShade ?? CommonColors.colorPrimary!,
              width: 1.5)),
    );
  }
}

// Private stub for hardcoded LOV options
class _SimpleOption {
  final String name;
  final String code;
  const _SimpleOption(this.name, this.code);
}
