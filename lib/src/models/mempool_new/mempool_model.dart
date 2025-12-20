import 'package:ark_flutter/src/models/mempool_new/txPosition.dart';

class RbfTransactionModel {
  RbfTransaction rbfTransaction;

  RbfTransactionModel({required this.rbfTransaction});

  factory RbfTransactionModel.fromJson(Map<String, dynamic> json) =>
      RbfTransactionModel(
        rbfTransaction: RbfTransaction.fromJson(json["rbfTransaction"]),
      );

  Map<String, dynamic> toJson() => {"rbfTransaction": rbfTransaction.toJson()};
}

class RbfTransaction {
  String txid;

  RbfTransaction({required this.txid});

  factory RbfTransaction.fromJson(Map<String, dynamic> json) =>
      RbfTransaction(txid: json["txid"]);

  Map<String, dynamic> toJson() => {"txid": txid};
}

class MemPoolModel {
  MempoolInfo? mempoolInfo;
  num? vBytesPerSecond;
  List<MempoolBlocks>? mempoolBlocks;
  List<Transactions>? transactions;
  Fees? fees;
  List<Blocks>? blocks;
  Conversions? conversions;
  TxPosition? txPosition;
  BackendInfo? backendInfo;
  Da? da;
  List<RbfSummary>? rbfSummary;
  List<RbfSummary>? rbfLatestSummary;
  RbfTransaction? rbfTransaction;

  MemPoolModel({
    this.mempoolInfo,
    this.vBytesPerSecond,
    this.mempoolBlocks,
    this.transactions,
    this.fees,
    this.blocks,
    this.conversions,
    this.backendInfo,
    this.da,
    this.rbfSummary,
    this.txPosition,
    this.rbfLatestSummary,
    this.rbfTransaction,
  });

  MemPoolModel.fromJson(Map<String, dynamic> json) {
    mempoolInfo = json['mempoolInfo'] != null
        ? MempoolInfo.fromJson(json['mempoolInfo'])
        : null;
    vBytesPerSecond = json['vBytesPerSecond'];
    if (json['mempool-blocks'] != null) {
      mempoolBlocks = <MempoolBlocks>[];
      json['mempool-blocks'].forEach((v) {
        mempoolBlocks!.add(MempoolBlocks.fromJson(v));
      });
    }
    if (json['transactions'] != null) {
      transactions = <Transactions>[];
      json['transactions'].forEach((v) {
        transactions!.add(Transactions.fromJson(v));
      });
    }
    fees = json['fees'] != null ? Fees.fromJson(json['fees']) : null;
    if (json['blocks'] != null) {
      blocks = <Blocks>[];
      json['blocks'].forEach((v) {
        blocks!.add(Blocks.fromJson(v));
      });
    }
    conversions = json['conversions'] != null
        ? Conversions.fromJson(json['conversions'])
        : null;
    txPosition = json['txPosition'] != null
        ? TxPosition.fromJson(json['txPosition'])
        : null;
    backendInfo = json['backendInfo'] != null
        ? BackendInfo.fromJson(json['backendInfo'])
        : null;
    da = json['da'] != null ? Da.fromJson(json['da']) : null;
    rbfTransaction = json['rbfTransaction'] != null
        ? RbfTransaction.fromJson(json['rbfTransaction'])
        : null;

    if (json['rbfSummary'] != null) {
      rbfSummary = <RbfSummary>[];
      json['rbfSummary'].forEach((v) {
        rbfSummary!.add(RbfSummary.fromJson(v));
      });
    }

    if (json['rbfLatestSummary'] != null) {
      rbfSummary = <RbfSummary>[];
      json['rbfLatestSummary'].forEach((v) {
        rbfSummary!.add(RbfSummary.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (mempoolInfo != null) {
      data['mempoolInfo'] = mempoolInfo!.toJson();
    }
    data['vBytesPerSecond'] = vBytesPerSecond;
    if (mempoolBlocks != null) {
      data['mempool-blocks'] = mempoolBlocks!.map((v) => v.toJson()).toList();
    }
    if (transactions != null) {
      data['transactions'] = transactions!.map((v) => v.toJson()).toList();
    }
    if (fees != null) {
      data['fees'] = fees!.toJson();
    }
    if (blocks != null) {
      data['blocks'] = blocks!.map((v) => v.toJson()).toList();
    }
    if (conversions != null) {
      data['conversions'] = conversions!.toJson();
    }
    if (txPosition != null) {
      data['txPosition'] = txPosition!.toJson();
    }
    if (rbfTransaction != null) {
      data['rbfTransaction'] = rbfTransaction!.toJson();
    }
    if (backendInfo != null) {
      data['backendInfo'] = backendInfo!.toJson();
    }
    if (da != null) {
      data['da'] = da!.toJson();
    }
    if (rbfSummary != null) {
      data['rbfSummary'] = rbfSummary!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class MempoolInfo {
  bool? loaded;
  num? size;
  num? bytes;
  num? usage;
  num? totalFee;
  num? maxmempool;
  num? mempoolminfee;
  num? minrelaytxfee;
  num? incrementalrelayfee;
  num? unbroadcastcount;
  bool? fullrbf;

  MempoolInfo({
    this.loaded,
    this.size,
    this.bytes,
    this.usage,
    this.totalFee,
    this.maxmempool,
    this.mempoolminfee,
    this.minrelaytxfee,
    this.incrementalrelayfee,
    this.unbroadcastcount,
    this.fullrbf,
  });

  MempoolInfo.fromJson(Map<String, dynamic> json) {
    loaded = json['loaded'];
    size = json['size'];
    bytes = json['bytes'];
    usage = json['usage'];
    totalFee = json['total_fee'];
    maxmempool = json['maxmempool'];
    mempoolminfee = json['mempoolminfee'];
    minrelaytxfee = json['minrelaytxfee'];
    incrementalrelayfee = json['incrementalrelayfee'];
    unbroadcastcount = json['unbroadcastcount'];
    fullrbf = json['fullrbf'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['loaded'] = loaded;
    data['size'] = size;
    data['bytes'] = bytes;
    data['usage'] = usage;
    data['total_fee'] = totalFee;
    data['maxmempool'] = maxmempool;
    data['mempoolminfee'] = mempoolminfee;
    data['minrelaytxfee'] = minrelaytxfee;
    data['incrementalrelayfee'] = incrementalrelayfee;
    data['unbroadcastcount'] = unbroadcastcount;
    data['fullrbf'] = fullrbf;
    return data;
  }
}

class MempoolBlocks {
  num? blockSize;
  num? blockVSize;
  num? nTx;
  num? totalFees;
  num? medianFee;
  List<num>? feeRange;

  MempoolBlocks({
    this.blockSize,
    this.blockVSize,
    this.nTx,
    this.totalFees,
    this.medianFee,
    this.feeRange,
  });

  MempoolBlocks.fromJson(Map<String, dynamic> json) {
    blockSize = json['blockSize'];
    blockVSize = json['blockVSize'];
    nTx = json['nTx'];
    totalFees = json['totalFees'];
    medianFee = json['medianFee'];
    feeRange = json['feeRange'].cast<num>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['blockSize'] = blockSize;
    data['blockVSize'] = blockVSize;
    data['nTx'] = nTx;
    data['totalFees'] = totalFees;
    data['medianFee'] = medianFee;
    data['feeRange'] = feeRange;
    return data;
  }
}

class Transactions {
  String? txid;
  num? fee;
  num? vsize;
  num? value;
  num? rate;

  Transactions({this.txid, this.fee, this.vsize, this.value, this.rate});

  Transactions.fromJson(Map<String, dynamic> json) {
    txid = json['txid'];
    fee = json['fee'];
    vsize = json['vsize'];
    value = json['value'];
    rate = json['rate'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['txid'] = txid;
    data['fee'] = fee;
    data['vsize'] = vsize;
    data['value'] = value;
    data['rate'] = rate;
    return data;
  }
}

class Fees {
  num? fastestFee;
  num? halfHourFee;
  num? hourFee;
  num? economyFee;
  num? minimumFee;

  Fees({
    this.fastestFee,
    this.halfHourFee,
    this.hourFee,
    this.economyFee,
    this.minimumFee,
  });

  Fees.fromJson(Map<String, dynamic> json) {
    fastestFee = json['fastestFee'];
    halfHourFee = json['halfHourFee'];
    hourFee = json['hourFee'];
    economyFee = json['economyFee'];
    minimumFee = json['minimumFee'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['fastestFee'] = fastestFee;
    data['halfHourFee'] = halfHourFee;
    data['hourFee'] = hourFee;
    data['economyFee'] = economyFee;
    data['minimumFee'] = minimumFee;
    return data;
  }
}

class Blocks {
  String? id;
  num? height;
  num? version;
  num? timestamp;
  num? bits;
  num? nonce;
  num? difficulty;
  String? merkleRoot;
  num? txCount;
  num? size;
  num? weight;
  String? previousblockhash;
  num? mediantime;
  bool? stale;

  Blocks({
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
  });

  Blocks.fromJson(Map<String, dynamic> json) {
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
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['height'] = height;
    data['version'] = version;
    data['timestamp'] = timestamp;
    data['bits'] = bits;
    data['nonce'] = nonce;
    data['difficulty'] = difficulty;
    data['merkle_root'] = merkleRoot;
    data['tx_count'] = txCount;
    data['size'] = size;
    data['weight'] = weight;
    data['previousblockhash'] = previousblockhash;
    data['mediantime'] = mediantime;
    data['stale'] = stale;
    return data;
  }
}

class Pool {
  num? id;
  String? name;
  String? slug;

  Pool({this.id, this.name, this.slug});

  Pool.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    slug = json['slug'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['slug'] = slug;
    return data;
  }
}

class Conversions {
  num? time;
  num? uSD;
  num? eUR;
  num? gBP;
  num? cAD;
  num? cHF;
  num? aUD;
  num? jPY;

  Conversions({
    this.time,
    this.uSD,
    this.eUR,
    this.gBP,
    this.cAD,
    this.cHF,
    this.aUD,
    this.jPY,
  });

  Conversions.fromJson(Map<String, dynamic> json) {
    time = json['time'];
    uSD = json['USD'];
    eUR = json['EUR'];
    gBP = json['GBP'];
    cAD = json['CAD'];
    cHF = json['CHF'];
    aUD = json['AUD'];
    jPY = json['JPY'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['time'] = time;
    data['USD'] = uSD;
    data['EUR'] = eUR;
    data['GBP'] = gBP;
    data['CAD'] = cAD;
    data['CHF'] = cHF;
    data['AUD'] = aUD;
    data['JPY'] = jPY;
    return data;
  }
}

class BackendInfo {
  String? hostname;
  String? version;
  String? gitCommit;
  bool? lightning;

  BackendInfo({this.hostname, this.version, this.gitCommit, this.lightning});

  BackendInfo.fromJson(Map<String, dynamic> json) {
    hostname = json['hostname'];
    version = json['version'];
    gitCommit = json['gitCommit'];
    lightning = json['lightning'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['hostname'] = hostname;
    data['version'] = version;
    data['gitCommit'] = gitCommit;
    data['lightning'] = lightning;
    return data;
  }
}

class Da {
  num? progressPercent;
  num? difficultyChange;
  num? estimatedRetargetDate;
  num? remainingBlocks;
  num? remainingTime;
  num? previousRetarget;
  num? previousTime;
  num? nextRetargetHeight;
  num? timeAvg;
  num? timeOffset;
  num? expectedBlocks;

  Da({
    this.progressPercent,
    this.difficultyChange,
    this.estimatedRetargetDate,
    this.remainingBlocks,
    this.remainingTime,
    this.previousRetarget,
    this.previousTime,
    this.nextRetargetHeight,
    this.timeAvg,
    this.timeOffset,
    this.expectedBlocks,
  });

  Da.fromJson(Map<String, dynamic> json) {
    progressPercent = json['progressPercent'];
    difficultyChange = json['difficultyChange'];
    estimatedRetargetDate = json['estimatedRetargetDate'];
    remainingBlocks = json['remainingBlocks'];
    remainingTime = json['remainingTime'];
    previousRetarget = json['previousRetarget'];
    previousTime = json['previousTime'];
    nextRetargetHeight = json['nextRetargetHeight'];
    timeAvg = json['timeAvg'];
    timeOffset = json['timeOffset'];
    expectedBlocks = json['expectedBlocks'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['progressPercent'] = progressPercent;
    data['difficultyChange'] = difficultyChange;
    data['estimatedRetargetDate'] = estimatedRetargetDate;
    data['remainingBlocks'] = remainingBlocks;
    data['remainingTime'] = remainingTime;
    data['previousRetarget'] = previousRetarget;
    data['previousTime'] = previousTime;
    data['nextRetargetHeight'] = nextRetargetHeight;
    data['timeAvg'] = timeAvg;
    data['timeOffset'] = timeOffset;
    data['expectedBlocks'] = expectedBlocks;
    return data;
  }
}

class RbfSummary {
  String? txid;
  bool? mined;
  bool? fullRbf;
  num? oldFee;
  num? oldVsize;
  num? newFee;
  num? newVsize;

  RbfSummary({
    this.txid,
    this.mined,
    this.fullRbf,
    this.oldFee,
    this.oldVsize,
    this.newFee,
    this.newVsize,
  });

  RbfSummary.fromJson(Map<String, dynamic> json) {
    txid = json['txid'];
    mined = json['mined'];
    fullRbf = json['fullRbf'];
    oldFee = json['oldFee'];
    oldVsize = json['oldVsize'];
    newFee = json['newFee'];
    newVsize = json['newVsize'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['txid'] = txid;
    data['mined'] = mined;
    data['fullRbf'] = fullRbf;
    data['oldFee'] = oldFee;
    data['oldVsize'] = oldVsize;
    data['newFee'] = newFee;
    data['newVsize'] = newVsize;
    return data;
  }
}
