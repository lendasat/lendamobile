class TransactionDetailsModel {
  String txid;
  int version;
  int locktime;
  List<Vin> vin;
  List<Vout> vout;
  int size;
  int weight;
  int fee;
  Status status;

  TransactionDetailsModel({
    required this.txid,
    required this.version,
    required this.locktime,
    required this.vin,
    required this.vout,
    required this.size,
    required this.weight,
    required this.fee,
    required this.status,
  });

  factory TransactionDetailsModel.fromJson(Map<String, dynamic> json) =>
      TransactionDetailsModel(
        txid: json["txid"],
        version: json["version"],
        locktime: json["locktime"],
        vin: List<Vin>.from(json["vin"].map((x) => Vin.fromJson(x))),
        vout: List<Vout>.from(json["vout"].map((x) => Vout.fromJson(x))),
        size: json["size"],
        weight: json["weight"],
        fee: json["fee"],
        status: Status.fromJson(json["status"]),
      );

  Map<String, dynamic> toJson() => {
        "txid": txid,
        "version": version,
        "locktime": locktime,
        "vin": List<dynamic>.from(vin.map((x) => x.toJson())),
        "vout": List<dynamic>.from(vout.map((x) => x.toJson())),
        "size": size,
        "weight": weight,
        "fee": fee,
        "status": status.toJson(),
      };
}

class Status {
  bool confirmed;
  int blockHeight;
  String blockHash;
  int blockTime;

  Status({
    required this.confirmed,
    required this.blockHeight,
    required this.blockHash,
    required this.blockTime,
  });

  factory Status.fromJson(Map<String, dynamic> json) => Status(
        confirmed: json["confirmed"],
        blockHeight: json["block_height"],
        blockHash: json["block_hash"],
        blockTime: json["block_time"],
      );

  Map<String, dynamic> toJson() => {
        "confirmed": confirmed,
        "block_height": blockHeight,
        "block_hash": blockHash,
        "block_time": blockTime,
      };
}

class Vin {
  String txid;
  int vout;
  Vout? prevout;
  String scriptsig;
  String scriptsigAsm;
  List<String>? witness;
  bool isCoinbase;
  int sequence;
  String? innerRedeemscriptAsm;
  String? innerWitnessscriptAsm;

  Vin({
    required this.txid,
    required this.vout,
    required this.prevout,
    required this.scriptsig,
    required this.scriptsigAsm,
    this.witness,
    required this.isCoinbase,
    required this.sequence,
    this.innerRedeemscriptAsm,
    this.innerWitnessscriptAsm,
  });

  factory Vin.fromJson(Map<String, dynamic> json) => Vin(
        txid: json["txid"],
        vout: json["vout"],
        prevout:
            json["prevout"] == null ? null : Vout.fromJson(json["prevout"]),
        scriptsig: json["scriptsig"],
        scriptsigAsm: json["scriptsig_asm"],
        witness: json["witness"] == null
            ? []
            : List<String>.from(json["witness"]!.map((x) => x)),
        isCoinbase: json["is_coinbase"],
        sequence: json["sequence"],
        innerRedeemscriptAsm: json["inner_redeemscript_asm"],
        innerWitnessscriptAsm: json["inner_witnessscript_asm"],
      );

  Map<String, dynamic> toJson() => {
        "txid": txid,
        "vout": vout,
        "prevout": prevout?.toJson(),
        "scriptsig": scriptsig,
        "scriptsig_asm": scriptsigAsm,
        "witness":
            witness == null ? [] : List<dynamic>.from(witness!.map((x) => x)),
        "is_coinbase": isCoinbase,
        "sequence": sequence,
        "inner_redeemscript_asm": innerRedeemscriptAsm,
        "inner_witnessscript_asm": innerWitnessscriptAsm,
      };
}

class Vout {
  String scriptpubkey;
  String scriptpubkeyAsm;
  String scriptpubkeyType;
  String? scriptpubkeyAddress;
  int value;

  Vout({
    required this.scriptpubkey,
    required this.scriptpubkeyAsm,
    required this.scriptpubkeyType,
    this.scriptpubkeyAddress,
    required this.value,
  });

  factory Vout.fromJson(Map<String, dynamic> json) => Vout(
        scriptpubkey: json["scriptpubkey"],
        scriptpubkeyAsm: json["scriptpubkey_asm"],
        scriptpubkeyType: json["scriptpubkey_type"],
        scriptpubkeyAddress: json["scriptpubkey_address"],
        value: json["value"],
      );

  Map<String, dynamic> toJson() => {
        "scriptpubkey": scriptpubkey,
        "scriptpubkey_asm": scriptpubkeyAsm,
        "scriptpubkey_type": scriptpubkeyType,
        "scriptpubkey_address": scriptpubkeyAddress,
        "value": value,
      };
}
