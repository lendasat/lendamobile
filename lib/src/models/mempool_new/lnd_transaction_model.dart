class BitcoinTransaction {
  String? txHash;
  String? amount;
  dynamic numConfirmations;
  String blockHash;
  dynamic blockHeight;
  dynamic timeStamp;
  String? totalFees;
  List<String> destAddresses;
  List<OutputDetail> outputDetails;
  String? rawTxHex; // Make nullable if not always provided
  String? label; // Make nullable if not always provided
  List<PreviousOutpoint> previousOutpoints;

  static int _parseTimestamp(Map<String, dynamic> json) {
    int parsedTimestamp = 0;

    // Try different timestamp fields in order of preference
    // 1. Try time_stamp field
    if (json['time_stamp'] != null && json['time_stamp'] != 0) {
      if (json['time_stamp'] is int) {
        parsedTimestamp = json['time_stamp'];
      } else if (json['time_stamp'] is String) {
        parsedTimestamp = int.tryParse(json['time_stamp']) ?? 0;
      }
    }

    // 2. Try timestamp field (alternative naming)
    if (parsedTimestamp == 0 &&
        json['timestamp'] != null &&
        json['timestamp'] != 0) {
      if (json['timestamp'] is int) {
        parsedTimestamp = json['timestamp'];
      } else if (json['timestamp'] is String) {
        parsedTimestamp = int.tryParse(json['timestamp']) ?? 0;
      }
    }

    // 3. Try last_updated field
    if (parsedTimestamp == 0 && json['last_updated'] != null) {
      if (json['last_updated'] is int) {
        parsedTimestamp = json['last_updated'];
      } else if (json['last_updated'] is String) {
        parsedTimestamp = int.tryParse(json['last_updated']) ?? 0;
      }
    }

    // 4. Try block_time field
    if (parsedTimestamp == 0 &&
        json['block_time'] != null &&
        json['block_time'] != 0) {
      if (json['block_time'] is int) {
        parsedTimestamp = json['block_time'];
      } else if (json['block_time'] is String) {
        parsedTimestamp = int.tryParse(json['block_time']) ?? 0;
      }
    }

    // If we have a timestamp that looks like milliseconds (very large number), convert to seconds
    if (parsedTimestamp > 9999999999) {
      print(
          '⚠️ BitcoinTransaction: Timestamp appears to be in milliseconds ($parsedTimestamp), converting to seconds');
      parsedTimestamp = parsedTimestamp ~/ 1000;
    }

    // 5. Log warning if no timestamp found
    if (parsedTimestamp == 0) {
      print(
          '⚠️ BitcoinTransaction: No valid timestamp found. Available fields: ${json.keys.toList()}');
      print(
          '⚠️ Timestamp values - time_stamp: ${json['time_stamp']}, timestamp: ${json['timestamp']}, last_updated: ${json['last_updated']}, block_time: ${json['block_time']}');
    }

    return parsedTimestamp;
  }

  BitcoinTransaction({
    required this.txHash,
    required this.amount,
    required this.numConfirmations,
    required this.blockHash,
    required this.blockHeight,
    required this.timeStamp,
    required this.totalFees,
    required this.destAddresses,
    required this.outputDetails,
    this.rawTxHex, // Remove required if nullable
    this.label, // Remove required if nullable
    required this.previousOutpoints,
  });

  factory BitcoinTransaction.fromJson(Map<String, dynamic> json) {
    return BitcoinTransaction(
      txHash: json['tx_hash']?.toString() ?? '',
      amount: json['amount']?.toString() ?? '',
      numConfirmations: json['num_confirmations'],
      blockHash: json['block_hash']?.toString() ?? '',
      blockHeight: json['block_height'],
      timeStamp: _parseTimestamp(json),
      totalFees: json['total_fees']?.toString() ?? '',
      destAddresses: json['dest_addresses'] != null
          ? List<String>.from(json['dest_addresses'].map((x) => x.toString()))
          : [],
      outputDetails: json['output_details'] != null
          ? List<OutputDetail>.from(
              json['output_details'].map(
                (x) => OutputDetail.fromJson(x as Map<String, dynamic>),
              ),
            )
          : [],
      rawTxHex: json['raw_tx_hex']?.toString(),
      label: json['label']?.toString(),
      previousOutpoints: json['previous_outpoints'] != null
          ? List<PreviousOutpoint>.from(
              json['previous_outpoints'].map(
                (x) => PreviousOutpoint.fromJson(x as Map<String, dynamic>),
              ),
            )
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tx_hash': txHash ?? '',
      'amount': amount ?? '',
      'num_confirmations': numConfirmations ?? '',
      'block_hash': blockHash,
      'block_height': blockHeight ?? '',
      'time_stamp': timeStamp ?? 0,
      'total_fees': totalFees ?? '',
      'dest_addresses': destAddresses,
      'output_details': outputDetails.map((x) => x.toJson()),
      'raw_tx_hex': rawTxHex ?? '',
      'label': label ?? '',
      'previous_outpoints': previousOutpoints.map((x) => x.toJson()),
    };
  }
}

class OutputDetail {
  String outputType;
  String address;
  String pkScript;
  int outputIndex;
  String amount;
  bool isOurAddress;

  OutputDetail({
    required this.outputType,
    required this.address,
    required this.pkScript,
    required this.outputIndex,
    required this.amount,
    required this.isOurAddress,
  });

  factory OutputDetail.fromJson(Map<String, dynamic> json) {
    return OutputDetail(
      outputType: json['output_type']!,
      address: json['address']!,
      pkScript: json['pk_script']!,
      outputIndex: json['output_index'] is int
          ? json['output_index']
          : int.parse(json['output_index']),
      amount: json['amount']!,
      isOurAddress: json['is_our_address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'output_type': outputType,
      'address': address,
      'pk_script': pkScript,
      'output_index': outputIndex,
      'amount': amount,
      'is_our_address': isOurAddress,
    };
  }
}

class PreviousOutpoint {
  String outpoint;
  bool isOurOutput;

  PreviousOutpoint({required this.outpoint, required this.isOurOutput});

  factory PreviousOutpoint.fromJson(Map<String, dynamic> json) {
    return PreviousOutpoint(
      outpoint: json['outpoint']!,
      isOurOutput: json['is_our_output'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'outpoint': outpoint, 'is_our_output': isOurOutput};
  }
}

class BitcoinTransactionsList {
  List<BitcoinTransaction> transactions;

  BitcoinTransactionsList({required this.transactions});

  factory BitcoinTransactionsList.fromJson(Map<String, dynamic> json) {
    return BitcoinTransactionsList(
      transactions: List<BitcoinTransaction>.from(
        json['transactions'].map(
          (x) => BitcoinTransaction.fromJson(x as Map<String, dynamic>),
        ),
      ),
    );
  }
  factory BitcoinTransactionsList.fromList(List<Map<String, dynamic>> json) {
    return BitcoinTransactionsList(
      transactions: List<BitcoinTransaction>.from(
        json.map((x) => BitcoinTransaction.fromJson(x)),
      ),
    );
  }
}
