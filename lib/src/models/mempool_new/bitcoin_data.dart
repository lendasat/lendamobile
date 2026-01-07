import 'dart:convert';

List<BlockData> blockDataFromJson(String str) =>
    List<BlockData>.from(json.decode(str).map((x) => BlockData.fromJson(x)));

class BlockData {
  String? id;
  int? height;
  int? version;
  int? timestamp;
  int? bits;
  int? nonce;
  num? difficulty;
  String? merkleRoot;
  int? txCount;
  int? size;
  int? weight;
  String? previousblockhash;
  int? mediantime;
  bool? stale;
  Extras? extras;

  BlockData({
    this.id,
    this.height,
    this.version,
    this.timestamp,
    this.bits,
    this.nonce,
    this.difficulty,
    this.merkleRoot,
    this.txCount,
    this.size,
    this.weight,
    this.previousblockhash,
    this.mediantime,
    this.stale,
    this.extras,
  });

  BlockData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    height = json['height'];
    version = json['version'];
    timestamp = json['timestamp'];
    bits = json['bits'];
    nonce = json['nonce'];
    difficulty = json['difficulty'];
    merkleRoot = json['merkle_root'];
    txCount = json['tx_count'];
    size = json['size'];
    weight = json['weight'];
    previousblockhash = json['previousblockhash'];
    mediantime = json['mediantime'];
    stale = json['stale'];
    extras =
        json['extras'] != null ? new Extras.fromJson(json['extras']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['height'] = this.height;
    data['version'] = this.version;
    data['timestamp'] = this.timestamp;
    data['bits'] = this.bits;
    data['nonce'] = this.nonce;
    data['difficulty'] = this.difficulty;
    data['merkle_root'] = this.merkleRoot;
    data['tx_count'] = this.txCount;
    data['size'] = this.size;
    data['weight'] = this.weight;
    data['previousblockhash'] = this.previousblockhash;
    data['mediantime'] = this.mediantime;
    data['stale'] = this.stale;
    if (this.extras != null) {
      data['extras'] = this.extras!.toJson();
    }
    return data;
  }
}

class Extras {
  int? reward;
  String? coinbaseRaw;

  // List<Null>? orphans;
  num? medianFee;
  List<num>? feeRange;
  int? totalFees;
  int? avgFee;
  int? avgFeeRate;
  int? utxoSetChange;
  num? avgTxSize;
  int? totalInputs;
  int? totalOutputs;
  int? totalOutputAmt;
  int? segwitTotalTxs;
  int? segwitTotalSize;
  int? segwitTotalWeight;
  var feePercentiles;
  num? virtualSize;
  String? coinbaseAddress;
  String? coinbaseSignature;
  String? coinbaseSignatureAscii;
  String? header;
  var utxoSetSize;
  var totalInputAmt;
  Pool? pool;
  num? matchRate;
  int? expectedFees;
  int? expectedWeight;
  num? similarity;

  Extras({
    this.reward,
    this.coinbaseRaw,
    // this.orphans,
    this.medianFee,
    this.feeRange,
    this.totalFees,
    this.avgFee,
    this.avgFeeRate,
    this.utxoSetChange,
    this.avgTxSize,
    this.totalInputs,
    this.totalOutputs,
    this.totalOutputAmt,
    this.segwitTotalTxs,
    this.segwitTotalSize,
    this.segwitTotalWeight,
    this.feePercentiles,
    this.virtualSize,
    this.coinbaseAddress,
    this.coinbaseSignature,
    this.coinbaseSignatureAscii,
    this.header,
    this.utxoSetSize,
    this.totalInputAmt,
    this.pool,
    this.matchRate,
    this.expectedFees,
    this.expectedWeight,
    this.similarity,
  });

  Extras.fromJson(Map<String, dynamic> json) {
    reward = json['reward'];
    coinbaseRaw = json['coinbaseRaw'];
    // if (json['orphans'] != null) {
    //   orphans = <Null>[];
    //   json['orphans'].forEach((v) {
    //     orphans!.add(new Null.fromJson(v));
    //   });
    // }
    medianFee = json['medianFee'];
    feeRange = json['feeRange'].cast<num>();
    totalFees = json['totalFees'];
    avgFee = json['avgFee'];
    avgFeeRate = json['avgFeeRate'];
    utxoSetChange = json['utxoSetChange'];
    avgTxSize = json['avgTxSize'];
    totalInputs = json['totalInputs'];
    totalOutputs = json['totalOutputs'];
    totalOutputAmt = json['totalOutputAmt'];
    segwitTotalTxs = json['segwitTotalTxs'];
    segwitTotalSize = json['segwitTotalSize'];
    segwitTotalWeight = json['segwitTotalWeight'];
    feePercentiles = json['feePercentiles'];
    virtualSize = json['virtualSize'];
    coinbaseAddress = json['coinbaseAddress'];
    coinbaseSignature = json['coinbaseSignature'];
    coinbaseSignatureAscii = json['coinbaseSignatureAscii'];
    header = json['header'];
    utxoSetSize = json['utxoSetSize'];
    totalInputAmt = json['totalInputAmt'];
    pool = json['pool'] != null ? new Pool.fromJson(json['pool']) : null;
    matchRate = json['matchRate'];
    expectedFees = json['expectedFees'];
    expectedWeight = json['expectedWeight'];
    similarity = json['similarity'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['reward'] = this.reward;
    data['coinbaseRaw'] = this.coinbaseRaw;
    // if (this.orphans != null) {
    //   data['orphans'] = this.orphans!.map((v) => v.toJson()).toList();
    // }
    data['medianFee'] = this.medianFee;
    data['feeRange'] = this.feeRange;
    data['totalFees'] = this.totalFees;
    data['avgFee'] = this.avgFee;
    data['avgFeeRate'] = this.avgFeeRate;
    data['utxoSetChange'] = this.utxoSetChange;
    data['avgTxSize'] = this.avgTxSize;
    data['totalInputs'] = this.totalInputs;
    data['totalOutputs'] = this.totalOutputs;
    data['totalOutputAmt'] = this.totalOutputAmt;
    data['segwitTotalTxs'] = this.segwitTotalTxs;
    data['segwitTotalSize'] = this.segwitTotalSize;
    data['segwitTotalWeight'] = this.segwitTotalWeight;
    data['feePercentiles'] = this.feePercentiles;
    data['virtualSize'] = this.virtualSize;
    data['coinbaseAddress'] = this.coinbaseAddress;
    data['coinbaseSignature'] = this.coinbaseSignature;
    data['coinbaseSignatureAscii'] = this.coinbaseSignatureAscii;
    data['header'] = this.header;
    data['utxoSetSize'] = this.utxoSetSize;
    data['totalInputAmt'] = this.totalInputAmt;
    if (this.pool != null) {
      data['pool'] = this.pool!.toJson();
    }
    data['matchRate'] = this.matchRate;
    data['expectedFees'] = this.expectedFees;
    data['expectedWeight'] = this.expectedWeight;
    data['similarity'] = this.similarity;
    return data;
  }
}

class Pool {
  int? id;
  String? name;
  String? slug;

  Pool({this.id, this.name, this.slug});

  Pool.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    slug = json['slug'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['slug'] = this.slug;
    return data;
  }
}
