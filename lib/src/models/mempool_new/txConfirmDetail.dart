// To parse this JSON data, do
//
//     final transactionConfirmedDetail = transactionConfirmedDetailFromJson(jsonString);

import 'dart:convert';

TransactionConfirmedDetail transactionConfirmedDetailFromJson(String str) =>
    TransactionConfirmedDetail.fromJson(json.decode(str));

String transactionConfirmedDetailToJson(TransactionConfirmedDetail data) =>
    json.encode(data.toJson());

class TransactionConfirmedDetail {
  String id;
  int height;
  int version;
  int timestamp;
  int bits;
  int nonce;
  double difficulty;
  String merkleRoot;
  int txCount;
  int size;
  int weight;
  String previousblockhash;
  int mediantime;
  bool stale;
  Extras extras;

  TransactionConfirmedDetail({
    required this.id,
    required this.height,
    required this.version,
    required this.timestamp,
    required this.bits,
    required this.nonce,
    required this.difficulty,
    required this.merkleRoot,
    required this.txCount,
    required this.size,
    required this.weight,
    required this.previousblockhash,
    required this.mediantime,
    required this.stale,
    required this.extras,
  });

  factory TransactionConfirmedDetail.fromJson(Map<String, dynamic> json) =>
      TransactionConfirmedDetail(
        id: json["id"] ?? "",
        height: json["height"] ?? 0,
        version: json["version"] ?? 0,
        timestamp: json["timestamp"] ?? 0,
        bits: json["bits"] ?? 0,
        nonce: json["nonce"] ?? 0,
        difficulty: (json["difficulty"] ?? 0).toDouble(),
        merkleRoot: json["merkle_root"] ?? "",
        txCount: json["tx_count"] ?? 0,
        size: json["size"] ?? 0,
        weight: json["weight"] ?? 0,
        previousblockhash: json["previousblockhash"] ?? "",
        mediantime: json["mediantime"] ?? 0,
        stale: json["stale"] ?? false,
        extras: Extras.fromJson(json["extras"] ?? {}),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "height": height,
        "version": version,
        "timestamp": timestamp,
        "bits": bits,
        "nonce": nonce,
        "difficulty": difficulty,
        "merkle_root": merkleRoot,
        "tx_count": txCount,
        "size": size,
        "weight": weight,
        "previousblockhash": previousblockhash,
        "mediantime": mediantime,
        "stale": stale,
        "extras": extras.toJson(),
      };
}

class Extras {
  int reward;
  String coinbaseRaw;
  List<dynamic> orphans;
  double medianFee;
  List<double> feeRange;
  int totalFees;
  int avgFee;
  int avgFeeRate;
  int utxoSetChange;
  double avgTxSize;
  int totalInputs;
  int totalOutputs;
  int totalOutputAmt;
  int segwitTotalTxs;
  int segwitTotalSize;
  int segwitTotalWeight;
  dynamic feePercentiles;
  double virtualSize;
  String coinbaseAddress;
  String coinbaseSignature;
  String coinbaseSignatureAscii;
  String header;
  dynamic utxoSetSize;
  dynamic totalInputAmt;
  Pool pool;
  double matchRate;
  int expectedFees;
  int expectedWeight;
  double similarity;

  Extras({
    required this.reward,
    required this.coinbaseRaw,
    required this.orphans,
    required this.medianFee,
    required this.feeRange,
    required this.totalFees,
    required this.avgFee,
    required this.avgFeeRate,
    required this.utxoSetChange,
    required this.avgTxSize,
    required this.totalInputs,
    required this.totalOutputs,
    required this.totalOutputAmt,
    required this.segwitTotalTxs,
    required this.segwitTotalSize,
    required this.segwitTotalWeight,
    required this.feePercentiles,
    required this.virtualSize,
    required this.coinbaseAddress,
    required this.coinbaseSignature,
    required this.coinbaseSignatureAscii,
    required this.header,
    required this.utxoSetSize,
    required this.totalInputAmt,
    required this.pool,
    required this.matchRate,
    required this.expectedFees,
    required this.expectedWeight,
    required this.similarity,
  });

  factory Extras.fromJson(Map<String, dynamic> json) => Extras(
        reward: json["reward"] ?? 0,
        coinbaseRaw: json["coinbaseRaw"] ?? "",
        orphans: json["orphans"] != null
            ? List<dynamic>.from(json["orphans"].map((x) => x))
            : [],
        medianFee: (json["medianFee"] ?? 0).toDouble(),
        feeRange: json["feeRange"] != null
            ? List<double>.from(
                json["feeRange"].map((x) => (x ?? 0).toDouble()))
            : [],
        totalFees: json["totalFees"] ?? 0,
        avgFee: json["avgFee"] ?? 0,
        avgFeeRate: json["avgFeeRate"] ?? 0,
        utxoSetChange: json["utxoSetChange"] ?? 0,
        avgTxSize: (json["avgTxSize"] ?? 0).toDouble(),
        totalInputs: json["totalInputs"] ?? 0,
        totalOutputs: json["totalOutputs"] ?? 0,
        totalOutputAmt: json["totalOutputAmt"] ?? 0,
        segwitTotalTxs: json["segwitTotalTxs"] ?? 0,
        segwitTotalSize: json["segwitTotalSize"] ?? 0,
        segwitTotalWeight: json["segwitTotalWeight"] ?? 0,
        feePercentiles: json["feePercentiles"],
        virtualSize: (json["virtualSize"] ?? 0).toDouble(),
        coinbaseAddress: json["coinbaseAddress"] ?? "",
        coinbaseSignature: json["coinbaseSignature"] ?? "",
        coinbaseSignatureAscii: json["coinbaseSignatureAscii"] ?? "",
        header: json["header"] ?? "",
        utxoSetSize: json["utxoSetSize"],
        totalInputAmt: json["totalInputAmt"],
        pool: json["pool"] != null
            ? Pool.fromJson(json["pool"])
            : Pool(id: 0, name: "", slug: ""),
        matchRate: (json["matchRate"] ?? 0).toDouble(),
        expectedFees: json["expectedFees"] ?? 0,
        expectedWeight: json["expectedWeight"] ?? 0,
        similarity: (json["similarity"] ?? 0).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        "reward": reward,
        "coinbaseRaw": coinbaseRaw,
        "orphans": List<dynamic>.from(orphans.map((x) => x)),
        "medianFee": medianFee,
        "feeRange": List<dynamic>.from(feeRange.map((x) => x)),
        "totalFees": totalFees,
        "avgFee": avgFee,
        "avgFeeRate": avgFeeRate,
        "utxoSetChange": utxoSetChange,
        "avgTxSize": avgTxSize,
        "totalInputs": totalInputs,
        "totalOutputs": totalOutputs,
        "totalOutputAmt": totalOutputAmt,
        "segwitTotalTxs": segwitTotalTxs,
        "segwitTotalSize": segwitTotalSize,
        "segwitTotalWeight": segwitTotalWeight,
        "feePercentiles": feePercentiles,
        "virtualSize": virtualSize,
        "coinbaseAddress": coinbaseAddress,
        "coinbaseSignature": coinbaseSignature,
        "coinbaseSignatureAscii": coinbaseSignatureAscii,
        "header": header,
        "utxoSetSize": utxoSetSize,
        "totalInputAmt": totalInputAmt,
        "pool": pool.toJson(),
        "matchRate": matchRate,
        "expectedFees": expectedFees,
        "expectedWeight": expectedWeight,
        "similarity": similarity,
      };
}

class Pool {
  int id;
  String name;
  String slug;

  Pool({required this.id, required this.name, required this.slug});

  factory Pool.fromJson(Map<String, dynamic> json) => Pool(
        id: json["id"] ?? 0,
        name: json["name"] ?? "",
        slug: json["slug"] ?? "",
      );

  Map<String, dynamic> toJson() => {"id": id, "name": name, "slug": slug};
}
