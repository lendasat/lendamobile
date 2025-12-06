class TransactionRbfModel {
  Replacements replacements;
  List<String> replaces;

  TransactionRbfModel({required this.replacements, required this.replaces});

  factory TransactionRbfModel.fromJson(Map<String, dynamic> json) =>
      TransactionRbfModel(
        replacements: Replacements.fromJson(json["replacements"]),
        replaces: List<String>.from(json["replaces"].map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
    "replacements": replacements.toJson(),
    "replaces": List<dynamic>.from(replaces.map((x) => x)),
  };
}

class Replacements {
  Tx tx;
  int time;
  bool fullRbf;
  List<Replace> replaces;
  bool mined;

  Replacements({
    required this.tx,
    required this.time,
    required this.fullRbf,
    required this.replaces,
    required this.mined,
  });

  factory Replacements.fromJson(Map<String, dynamic> json) => Replacements(
    tx: Tx.fromJson(json["tx"]),
    time: json["time"],
    fullRbf: json["fullRbf"],
    replaces: List<Replace>.from(
      json["replaces"].map((x) => Replace.fromJson(x)),
    ),
    mined: json["mined"],
  );

  Map<String, dynamic> toJson() => {
    "tx": tx.toJson(),
    "time": time,
    "fullRbf": fullRbf,
    "replaces": List<dynamic>.from(replaces.map((x) => x.toJson())),
    "mined": mined,
  };
}

class Replace {
  Tx tx;
  int time;
  bool fullRbf;
  List<Replace> replaces;
  int interval;

  Replace({
    required this.tx,
    required this.time,
    required this.fullRbf,
    required this.replaces,
    required this.interval,
  });

  factory Replace.fromJson(Map<String, dynamic> json) => Replace(
    tx: Tx.fromJson(json["tx"]),
    time: json["time"],
    fullRbf: json["fullRbf"],
    replaces: List<Replace>.from(
      json["replaces"].map((x) => Replace.fromJson(x)),
    ),
    interval: json["interval"],
  );

  Map<String, dynamic> toJson() => {
    "tx": tx.toJson(),
    "time": time,
    "fullRbf": fullRbf,
    "replaces": List<dynamic>.from(replaces.map((x) => x.toJson())),
    "interval": interval,
  };
}

class Tx {
  String txid;
  int fee;
  double vsize;
  int value;
  double rate;
  bool rbf;
  bool? fullRbf;
  bool? mined;

  Tx({
    required this.txid,
    required this.fee,
    required this.vsize,
    required this.value,
    required this.rate,
    required this.rbf,
    this.fullRbf,
    this.mined,
  });

  factory Tx.fromJson(Map<String, dynamic> json) => Tx(
    txid: json["txid"],
    fee: json["fee"],
    vsize: json["vsize"]?.toDouble(),
    value: json["value"],
    rate: json["rate"]?.toDouble(),
    rbf: json["rbf"],
    fullRbf: json["fullRbf"],
    mined: json["mined"],
  );

  Map<String, dynamic> toJson() => {
    "txid": txid,
    "fee": fee,
    "vsize": vsize,
    "value": value,
    "rate": rate,
    "rbf": rbf,
    "fullRbf": fullRbf,
    "mined": mined,
  };
}
