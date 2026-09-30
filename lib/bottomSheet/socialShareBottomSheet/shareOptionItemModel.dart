

import 'package:gtlmd/bottomSheet/socialShareBottomSheet/socialShareBottomSheet.dart';

class ShareOptionitemModel {
  String? itemlogo;
  OptionType? itemtype;
  String? itemname;

  ShareOptionitemModel({
    this.itemlogo,
    this.itemtype,
    this.itemname,
  });

  ShareOptionitemModel.fromJson(Map<String, dynamic> json) {
    itemlogo = json['itemlogo'];
    itemname = json['itemname'];

    final type = json['itemtype'];

    if (type != null) {
      itemtype = OptionType.values.firstWhere(
        (e) => e.name == type,
        orElse: () => OptionType.WHATSAPP,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'itemlogo': itemlogo,
      'itemtype': itemtype?.name,
      'itemname': itemname,
    };
  }
}