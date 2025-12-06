class TransactionCacheModel {
  String txid;
  int version;
  int locktime;
  List<Vin> vin;
  List<Vout> vout;
  int size;
  int weight;
  int sigops;
  int fee;
  Status status;
  int order;
  int vsize;
  int adjustedVsize;
  int feePerVsize;
  int adjustedFeePerVsize;
  int effectiveFeePerVsize;
  int firstSeen;
  int uid;
  List<dynamic> inputs;
  Position position;
  dynamic bestDescendant;
  bool cpfpChecked;

  TransactionCacheModel({
    required this.txid,
    required this.version,
    required this.locktime,
    required this.vin,
    required this.vout,
    required this.size,
    required this.weight,
    required this.sigops,
    required this.fee,
    required this.status,
    required this.order,
    required this.vsize,
    required this.adjustedVsize,
    required this.feePerVsize,
    required this.adjustedFeePerVsize,
    required this.effectiveFeePerVsize,
    required this.firstSeen,
    required this.uid,
    required this.inputs,
    required this.position,
    required this.bestDescendant,
    required this.cpfpChecked,
  });

  factory TransactionCacheModel.fromJson(Map<String, dynamic> json) =>
      TransactionCacheModel(
        txid: json["txid"],
        version: json["version"],
        locktime: json["locktime"],
        vin: List<Vin>.from(json["vin"].map((x) => Vin.fromJson(x))),
        vout: List<Vout>.from(json["vout"].map((x) => Vout.fromJson(x))),
        size: json["size"],
        weight: json["weight"],
        sigops: json["sigops"],
        fee: json["fee"],
        status: Status.fromJson(json["status"]),
        order: json["order"],
        vsize: json["vsize"],
        adjustedVsize: json["adjustedVsize"],
        feePerVsize: json["feePerVsize"],
        adjustedFeePerVsize: json["adjustedFeePerVsize"],
        effectiveFeePerVsize: json["effectiveFeePerVsize"],
        firstSeen: json["firstSeen"],
        uid: json["uid"],
        inputs: List<dynamic>.from(json["inputs"].map((x) => x)),
        position: Position.fromJson(json["position"]),
        bestDescendant: json["bestDescendant"],
        cpfpChecked: json["cpfpChecked"],
      );

  Map<String, dynamic> toJson() => {
    "txid": txid,
    "version": version,
    "locktime": locktime,
    "vin": List<dynamic>.from(vin.map((x) => x.toJson())),
    "vout": List<dynamic>.from(vout.map((x) => x.toJson())),
    "size": size,
    "weight": weight,
    "sigops": sigops,
    "fee": fee,
    "status": status.toJson(),
    "order": order,
    "vsize": vsize,
    "adjustedVsize": adjustedVsize,
    "feePerVsize": feePerVsize,
    "adjustedFeePerVsize": adjustedFeePerVsize,
    "effectiveFeePerVsize": effectiveFeePerVsize,
    "firstSeen": firstSeen,
    "uid": uid,
    "inputs": List<dynamic>.from(inputs.map((x) => x)),
    "position": position.toJson(),
    "bestDescendant": bestDescendant,
    "cpfpChecked": cpfpChecked,
  };
}

class Position {
  int block;
  int vsize;

  Position({required this.block, required this.vsize});

  factory Position.fromJson(Map<String, dynamic> json) =>
      Position(block: json["block"], vsize: json["vsize"]);

  Map<String, dynamic> toJson() => {"block": block, "vsize": vsize};
}

class Status {
  bool confirmed;

  Status({required this.confirmed});

  factory Status.fromJson(Map<String, dynamic> json) =>
      Status(confirmed: json["confirmed"]);

  Map<String, dynamic> toJson() => {"confirmed": confirmed};
}

class Vin {
  String txid;
  int vout;
  Vout prevout;
  String scriptsig;
  String scriptsigAsm;
  List<String> witness;
  bool isCoinbase;
  int sequence;
  String innerWitnessscriptAsm;

  Vin({
    required this.txid,
    required this.vout,
    required this.prevout,
    required this.scriptsig,
    required this.scriptsigAsm,
    required this.witness,
    required this.isCoinbase,
    required this.sequence,
    required this.innerWitnessscriptAsm,
  });

  factory Vin.fromJson(Map<String, dynamic> json) => Vin(
    txid: json["txid"],
    vout: json["vout"],
    prevout: Vout.fromJson(json["prevout"]),
    scriptsig: json["scriptsig"],
    scriptsigAsm: json["scriptsig_asm"],
    witness: List<String>.from(json["witness"].map((x) => x)),
    isCoinbase: json["is_coinbase"],
    sequence: json["sequence"],
    innerWitnessscriptAsm: json["inner_witnessscript_asm"],
  );

  Map<String, dynamic> toJson() => {
    "txid": txid,
    "vout": vout,
    "prevout": prevout.toJson(),
    "scriptsig": scriptsig,
    "scriptsig_asm": scriptsigAsm,
    "witness": List<dynamic>.from(witness.map((x) => x)),
    "is_coinbase": isCoinbase,
    "sequence": sequence,
    "inner_witnessscript_asm": innerWitnessscriptAsm,
  };
}

class Vout {
  String scriptpubkey;
  String scriptpubkeyAsm;
  String scriptpubkeyType;
  String scriptpubkeyAddress;
  int value;

  Vout({
    required this.scriptpubkey,
    required this.scriptpubkeyAsm,
    required this.scriptpubkeyType,
    required this.scriptpubkeyAddress,
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
