class OutspendsModel {
  bool? spent;
  String? txid;
  int? vin;
  Status? status;

  OutspendsModel({this.spent, this.txid, this.vin, this.status});

  OutspendsModel.fromJson(Map<String, dynamic> json) {
    spent = json['spent'];
    txid = json['txid'];
    vin = json['vin'];
    status =
        json['status'] != null ? new Status.fromJson(json['status']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['spent'] = this.spent;
    data['txid'] = this.txid;
    data['vin'] = this.vin;
    if (this.status != null) {
      data['status'] = this.status!.toJson();
    }
    return data;
  }
}

class Status {
  bool? confirmed;
  int? blockHeight;
  String? blockHash;
  int? blockTime;

  Status({this.confirmed, this.blockHeight, this.blockHash, this.blockTime});

  Status.fromJson(Map<String, dynamic> json) {
    confirmed = json['confirmed'];
    blockHeight = json['block_height'];
    blockHash = json['block_hash'];
    blockTime = json['block_time'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['confirmed'] = this.confirmed;
    data['block_height'] = this.blockHeight;
    data['block_hash'] = this.blockHash;
    data['block_time'] = this.blockTime;
    return data;
  }
}
