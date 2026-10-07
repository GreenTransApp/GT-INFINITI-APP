class DeliveryDetailModel {
  int? commandstatus;
  String? commandmessage;
  String? grno;
  String? cngename;
  String? cngemobile;
  String? pcs;
  String? undeliverreason;
  String? deliverystatus;
  String? statusColor;
  int? sequenceno;
  int? planningid;
  String? manifestno;
  String? manifesttype;

  String? consignmenttype;
  String? pickupstatus;
  String? reversepickupstatus;
  String? consignmenttypeview;
  int? transactionid;
  String? useracceptancestatus;
  String? userallocationstatus;
  String? isOtpRequired;
  String? isVerified;
  int? orderid;
  String? cngeaddress;
  String? reached;
  String? reachedlat;
  String? reachedlong;
  String? generatedGr;
  String? deliverylat;
  String? deliverylong;
  String? pickuplat;
  String? pickuplong;
  int? tripid;
  String? dispatchdatetime;
  String? dispatchdate;
  String? dispatchtime;
  String? vehiclecode;
  int? startreadingkm;
  String? startreadingimg;
  String? validationerrmsg;
  String? candeliver;
  String? directdelivery;
  String? reachedatdatetime;
  String? pickupstatusupdateon;
  String? deliverystatusupdateon;
  String? reachedAtDlvPoint;
  String? reachedAtDlvPointDt;
  String? pickupdeparted;
  String? pickupdeparteddattime;
  String? orgcode;
  String? destcode;
  String? orgname;
  String? destname;
  int? jobid;
  String? showdeparted;
  String? referenceno;
  String? cngrname;
  String? cngraddress;
  String? cngrmobileno;
  

  DeliveryDetailModel(
      {this.commandstatus,
      this.commandmessage,
      this.grno,
      this.cngename,
      this.cngemobile,
      this.pcs,
      this.undeliverreason,
      this.deliverystatus,
      this.statusColor,
      this.sequenceno,
      this.planningid,
      this.manifestno,
      this.manifesttype,
      this.consignmenttype,
      this.pickupstatus,
      this.reversepickupstatus,
      this.consignmenttypeview,
      this.transactionid,
      this.isOtpRequired,
      this.isVerified,
      this.orderid,
      this.cngeaddress,
      this.reached,
      this.reachedlat,
      this.reachedlong,
      this.generatedGr,
      this.deliverylat,
      this.deliverylong,
      this.pickuplat,
      this.pickuplong,
      this.tripid,
      this.dispatchdatetime,
      this.dispatchdate,
      this.dispatchtime,
      this.vehiclecode,
      this.startreadingkm,
      this.startreadingimg,
      this.validationerrmsg,
      this.candeliver,
      this.directdelivery,
      this.reachedatdatetime,
      this.pickupstatusupdateon,
      this.deliverystatusupdateon,
      this.reachedAtDlvPoint,
      this.reachedAtDlvPointDt,
      this.pickupdeparted,
      this.pickupdeparteddattime,
      this.orgcode,
       this.destcode,
       this.orgname,
       this.destname,
       this.jobid,
       this.showdeparted,
       this.referenceno,
       this.cngrname,
       this.cngraddress,
       this.cngrmobileno,
      });

  factory DeliveryDetailModel.fromJson(Map<String, dynamic> json) {
    return DeliveryDetailModel(
      commandstatus: json['commandstatus'],
      commandmessage: json['commandmessage'],
      grno: json['grno'],
      cngename: json['cngename'],
      cngemobile: json['cngemobile'],
      pcs: json['pcs'],
      undeliverreason: json['undeliverreason'],
      deliverystatus: json['deliverystatus'],
      statusColor: json['statusColor'],
      sequenceno: json['sequenceno'],
      planningid: json['planningid'],
      manifestno: json['manifestno'],
      manifesttype: json['manifesttype'],
      consignmenttype: json['consignmenttype'],
      pickupstatus: json['pickupstatus'],
      reversepickupstatus: json['reversepickupstatus'],
      consignmenttypeview: json['consignmenttypeview'],
      transactionid: json['transactionid'],
      isOtpRequired: json['isotprequired'],
      isVerified: json['isverified'],
      orderid: json['orderid'],
      cngeaddress: json['cngeaddress'],
      reached: json['reached'],
      reachedlat: json['reachedlat'],
      reachedlong: json['reachedlong'],
      generatedGr: json['generatedgr'],
      deliverylat: json['deliverylat'],
      deliverylong: json['deliverylong'],
      pickuplat: json['pickuplat'],
      pickuplong: json['pickuplong'],
      tripid: json['tripid'],
      dispatchdatetime: json['dispatchdatetime'],
      dispatchdate: json['dispatchdate'],
      dispatchtime: json['dispatchtime'],
      vehiclecode: json['vehiclecode'],
      startreadingkm: json['startreadingkm'],
      startreadingimg: json['startreadingimg'],
      validationerrmsg: json['validationerrmsg'],
      candeliver: json['candeliver'],
      directdelivery: json['directdelivery'],
      reachedatdatetime: json['reachedatdatetime'],
      pickupstatusupdateon: json['pickupstatusupdateon'],
      deliverystatusupdateon: json['deliverystatusupdateon'],
      reachedAtDlvPoint: json['reacheddlvpoint'],
      reachedAtDlvPointDt: json['reacheddlvpointdt'],
      pickupdeparted: json['pickupdeparted'],
      pickupdeparteddattime: json['pickupdeparteddattime'],
      orgcode: json['orgcode'],
      orgname: json['orgname'],
      destcode: json['destcode'],
      destname: json['destname'],
      jobid: json['jobid'],
      showdeparted: json['showdeparted'],
      referenceno: json['referenceno'],
      cngrname: json['cngrname'],
      cngraddress: json['cngraddress'],
      cngrmobileno: json['cngrmobileno'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'commandstatus': commandstatus,
      'commandmessage': commandmessage,
      'grno': grno,
      'cngename': cngename,
      'cngemobile': cngemobile,
      'pcs': pcs,
      'undeliverreason': undeliverreason,
      'deliverystatus': deliverystatus,
      'statusColor': statusColor,
      'sequenceno': sequenceno,
      'planningid': planningid,
      'manifestno': manifestno,
      'manifesttype': manifesttype,
      'consignmenttype': consignmenttype,
      'pickupstatus': pickupstatus,
      'reversepickupstatus': reversepickupstatus,
      'consignmenttypeview': consignmenttypeview,
      'transactionid': transactionid,
      'isotprequired': isOtpRequired,
      'isverified': isVerified,
      'orderid': orderid,
      'cngeaddress': cngeaddress,
      'reached': reached,
      'reachedlat': reachedlat,
      'reachedlong': reachedlong,
      'generatedgr': generatedGr,
      'deliverylat': deliverylat,
      'deliverylong': deliverylong,
      'pickuplat': pickuplat,
      'pickuplong': pickuplong,
      'tripid': tripid,
      'dispatchdatetime': dispatchdatetime,
      'dispatchdate': dispatchdate,
      'dispatchtime': dispatchtime,
      'vehiclecode': vehiclecode,
      'startreadingkm': startreadingkm,
      'startreadingimg': startreadingimg,
      'validationerrmsg': validationerrmsg,
      'candeliver': candeliver,
      'directdelivery': directdelivery,
      'reachedatdatetime': reachedatdatetime,
      'pickupstatusupdateon': pickupstatusupdateon,
      'deliverystatusupdateon': deliverystatusupdateon,
      'reacheddlvpoint': reachedAtDlvPoint,
      'reacheddlvpointdt': reachedAtDlvPointDt,
      'pickupdeparted': pickupdeparted,
      'pickupdeparteddattime': pickupdeparteddattime,
      'orgcode': orgcode,
      'orgname': orgname,
      'destcode': destcode,
      'destname': destname,
      'jobid': jobid,
      'showdeparted': showdeparted,
      'referenceno': referenceno,
      'cngrname': cngrname,
      'cngraddress': cngraddress,
      'cngrmobileno': cngrmobileno,
    };
  }
}
