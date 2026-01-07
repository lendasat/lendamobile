class TxModel {
  Tx tx;
  TxPosition txPosition;

  TxModel({required this.tx, required this.txPosition});

  factory TxModel.fromJson(Map<String, dynamic> json) => TxModel(
        tx: Tx.fromJson(json["tx"]),
        txPosition: TxPosition.fromJson(json["txPosition"]),
      );

  Map<String, dynamic> toJson() => {
        "tx": tx.toJson(),
        "txPosition": txPosition.toJson(),
      };
}

class Tx {
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
  double adjustedVsize;
  double feePerVsize;
  double adjustedFeePerVsize;
  double effectiveFeePerVsize;
  int firstSeen;
  int uid;
  List<int> inputs;
  bool cpfpDirty;
  bool cpfpChecked;
  List<Ancestor> ancestors;
  List<dynamic> descendants;
  dynamic bestDescendant;
  Position position;

  Tx({
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
    required this.cpfpDirty,
    required this.cpfpChecked,
    required this.ancestors,
    required this.descendants,
    required this.bestDescendant,
    required this.position,
  });

  factory Tx.fromJson(Map<String, dynamic> json) => Tx(
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
        adjustedVsize: json["adjustedVsize"]?.toDouble(),
        feePerVsize: json["feePerVsize"]?.toDouble(),
        adjustedFeePerVsize: json["adjustedFeePerVsize"]?.toDouble(),
        effectiveFeePerVsize: json["effectiveFeePerVsize"]?.toDouble(),
        firstSeen: json["firstSeen"],
        uid: json["uid"],
        inputs: List<int>.from(json["inputs"].map((x) => x)),
        cpfpDirty: json["cpfpDirty"],
        cpfpChecked: json["cpfpChecked"],
        ancestors: List<Ancestor>.from(
          json["ancestors"].map((x) => Ancestor.fromJson(x)),
        ),
        descendants: List<dynamic>.from(json["descendants"].map((x) => x)),
        bestDescendant: json["bestDescendant"],
        position: Position.fromJson(json["position"]),
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
        "cpfpDirty": cpfpDirty,
        "cpfpChecked": cpfpChecked,
        "ancestors": List<dynamic>.from(ancestors.map((x) => x.toJson())),
        "descendants": List<dynamic>.from(descendants.map((x) => x)),
        "bestDescendant": bestDescendant,
        "position": position.toJson(),
      };
}

class Ancestor {
  String txid;
  int fee;
  int weight;

  Ancestor({required this.txid, required this.fee, required this.weight});

  factory Ancestor.fromJson(Map<String, dynamic> json) =>
      Ancestor(txid: json["txid"], fee: json["fee"], weight: json["weight"]);

  Map<String, dynamic> toJson() => {"txid": txid, "fee": fee, "weight": weight};
}

class Position {
  int block;
  double vsize;

  Position({required this.block, required this.vsize});

  factory Position.fromJson(Map<String, dynamic> json) =>
      Position(block: json["block"], vsize: json["vsize"]?.toDouble());

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

  Vin({
    required this.txid,
    required this.vout,
    required this.prevout,
    required this.scriptsig,
    required this.scriptsigAsm,
    required this.witness,
    required this.isCoinbase,
    required this.sequence,
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

class TxPositionModel {
  TxPosition txPosition;

  TxPositionModel({required this.txPosition});

  factory TxPositionModel.fromJson(Map<String, dynamic> json) =>
      TxPositionModel(txPosition: TxPosition.fromJson(json["txPosition"]));

  Map<String, dynamic> toJson() => {"txPosition": txPosition.toJson()};
}

class TxPosition {
  String txid;
  Position position;
  Cpfp cpfp;

  TxPosition({required this.txid, required this.position, required this.cpfp});

  factory TxPosition.fromJson(Map<String, dynamic> json) => TxPosition(
        txid: json["txid"],
        position: Position.fromJson(json["position"]),
        cpfp: Cpfp.fromJson(json["cpfp"]),
      );

  Map<String, dynamic> toJson() => {
        "txid": txid,
        "position": position.toJson(),
        "cpfp": cpfp.toJson(),
      };
}

class Cpfp {
  List<Ancestor> ancestors;
  dynamic bestDescendant;
  List<dynamic> descendants;
  double effectiveFeePerVsize;
  int sigops;
  double adjustedVsize;

  Cpfp({
    required this.ancestors,
    required this.bestDescendant,
    required this.descendants,
    required this.effectiveFeePerVsize,
    required this.sigops,
    required this.adjustedVsize,
  });

  factory Cpfp.fromJson(Map<String, dynamic> json) => Cpfp(
        ancestors: List<Ancestor>.from(
          json["ancestors"].map((x) => Ancestor.fromJson(x)),
        ),
        bestDescendant: json["bestDescendant"],
        descendants: List<dynamic>.from(json["descendants"].map((x) => x)),
        effectiveFeePerVsize: json["effectiveFeePerVsize"]?.toDouble(),
        sigops: json["sigops"],
        adjustedVsize: json["adjustedVsize"]?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        "ancestors": List<dynamic>.from(ancestors.map((x) => x.toJson())),
        "bestDescendant": bestDescendant,
        "descendants": List<dynamic>.from(descendants.map((x) => x)),
        "effectiveFeePerVsize": effectiveFeePerVsize,
        "sigops": sigops,
        "adjustedVsize": adjustedVsize,
      };
}
