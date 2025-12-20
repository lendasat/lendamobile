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
    cpfp: Cpfp.fromJson(json["cpfp"] ?? {}),
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
    ancestors: json["ancestors"] != null
        ? List<Ancestor>.from(
            json["ancestors"].map((x) => Ancestor.fromJson(x)),
          )
        : [],
    bestDescendant: json["bestDescendant"],
    descendants: json["descendants"] != null
        ? List<dynamic>.from(json["descendants"].map((x) => x))
        : [],
    effectiveFeePerVsize: json["effectiveFeePerVsize"] != null
        ? json["effectiveFeePerVsize"]?.toDouble()
        : 0.0,
    sigops: json["sigops"] ?? 0,
    adjustedVsize: json["adjustedVsize"]?.toDouble() ?? 0.0,
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
