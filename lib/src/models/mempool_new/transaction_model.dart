class TransactionModel {
  String? txid;
  int? version;
  int? locktime;
  List<Vin>? vin;
  List<Prevout>? vout;
  int? size;
  int? weight;
  int? sigops;
  int? fee;
  Status? status;

  TransactionModel({
    this.txid,
    this.version,
    this.locktime,
    this.vin,
    this.vout,
    this.size,
    this.sigops,
    this.weight,
    this.fee,
    this.status,
  });

  TransactionModel.fromJson(Map<String, dynamic> json) {
    txid = json['txid'];
    version = json['version'];
    locktime = json['locktime'];
    if (json['vin'] != null) {
      vin = <Vin>[];
      json['vin'].forEach((v) {
        vin!.add(new Vin.fromJson(v));
      });
    }
    if (json['vout'] != null) {
      vout = <Prevout>[];
      json['vout'].forEach((v) {
        vout!.add(new Prevout.fromJson(v));
      });
    }
    size = json['size'];
    weight = json['weight'];
    sigops = json['sigops'];
    fee = json['fee'];
    status =
        json['status'] != null ? new Status.fromJson(json['status']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['txid'] = txid;
    data['version'] = version;
    data['locktime'] = locktime;
    if (vin != null) {
      data['vin'] = vin!.map((v) => v.toJson()).toList();
    }
    if (vout != null) {
      data['vout'] = vout!.map((v) => v.toJson()).toList();
    }
    data['size'] = size;
    data['weight'] = weight;
    data['sigops'] = sigops;
    data['fee'] = fee;
    if (status != null) {
      data['status'] = status!.toJson();
    }
    return data;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TransactionModel) return false;
    return this.txid == other.txid && this.txid != null && other.txid != null;
  }

  @override
  int get hashCode => this.txid == null ? super.hashCode : this.txid.hashCode;
}

class Vin {
  String? txid;
  int? vout;
  Prevout? prevout;
  String? scriptsig;
  String? scriptsigAsm;
  String? inner_witnessscript_asm;
  String? inner_redeemscript_asm;
  List<String>? witness;
  bool? isCoinbase;
  int? sequence;

  Vin({
    this.txid,
    this.vout,
    this.prevout,
    this.scriptsig,
    this.scriptsigAsm,
    this.inner_witnessscript_asm,
    this.inner_redeemscript_asm,
    this.witness,
    this.isCoinbase,
    this.sequence,
  });

  factory Vin.fromJson(Map<String, dynamic> json) => Vin(
        txid: json["txid"],
        vout: json["vout"],
        prevout:
            json["prevout"] == null ? null : Prevout.fromJson(json["prevout"]),
        scriptsig: json["scriptsig"],
        inner_redeemscript_asm: json["inner_redeemscript_asm"] ?? '',
        inner_witnessscript_asm: json["inner_witnessscript_asm"] ?? '',
        scriptsigAsm: json["scriptsig_asm"],
        witness: json["witness"] == null
            ? []
            : List<String>.from(json["witness"]!.map((x) => x)),
        isCoinbase: json["is_coinbase"],
        sequence: json["sequence"],
      );

  Map<String, dynamic> toJson() => {
        "txid": txid,
        "vout": vout,
        "prevout": prevout?.toJson(),
        "scriptsig": scriptsig,
        "scriptsig_asm": scriptsigAsm,
        "inner_witnessscript_asm": inner_witnessscript_asm,
        "inner_redeemscript_asm": inner_redeemscript_asm,
        "witness":
            witness == null ? [] : List<dynamic>.from(witness!.map((x) => x)),
        "is_coinbase": isCoinbase,
        "sequence": sequence,
      };
}

class Prevout {
  String? scriptpubkey;
  String? scriptpubkeyAsm;
  String? scriptpubkeyType;
  String? scriptpubkeyAddress;
  int? value;

  Prevout({
    this.scriptpubkey,
    this.scriptpubkeyAsm,
    this.scriptpubkeyType,
    this.scriptpubkeyAddress,
    this.value,
  });

  Prevout.fromJson(Map<String, dynamic> json) {
    scriptpubkey = json['scriptpubkey'];
    scriptpubkeyAsm = json['scriptpubkey_asm'];
    scriptpubkeyType = json['scriptpubkey_type'];
    scriptpubkeyAddress = json['scriptpubkey_address'];
    value = json['value'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['scriptpubkey'] = scriptpubkey;
    data['scriptpubkey_asm'] = scriptpubkeyAsm;
    data['scriptpubkey_type'] = scriptpubkeyType;
    data['scriptpubkey_address'] = scriptpubkeyAddress;
    data['value'] = value;
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
    data['confirmed'] = confirmed;
    data['block_height'] = blockHeight;
    data['block_hash'] = blockHash;
    data['block_time'] = blockTime;
    return data;
  }
}
