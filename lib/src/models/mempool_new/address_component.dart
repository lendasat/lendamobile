// To parse this JSON data, do
//
//     final addressComponentModel = addressComponentModelFromJson(jsonString);

import 'dart:convert';

AddressComponentModel addressComponentModelFromJson(String str) =>
    AddressComponentModel.fromJson(json.decode(str));

String addressComponentModelToJson(AddressComponentModel data) =>
    json.encode(data.toJson());

class AddressComponentModel {
  String address;
  Stats chainStats;
  Stats mempoolStats;

  AddressComponentModel({
    required this.address,
    required this.chainStats,
    required this.mempoolStats,
  });

  factory AddressComponentModel.fromJson(Map<String, dynamic> json) =>
      AddressComponentModel(
        address: json["address"],
        chainStats: Stats.fromJson(json["chain_stats"]),
        mempoolStats: Stats.fromJson(json["mempool_stats"]),
      );

  Map<String, dynamic> toJson() => {
        "address": address,
        "chain_stats": chainStats.toJson(),
        "mempool_stats": mempoolStats.toJson(),
      };
}

class Stats {
  int fundedTxoCount;
  int fundedTxoSum;
  int spentTxoCount;
  int spentTxoSum;
  int txCount;

  Stats({
    required this.fundedTxoCount,
    required this.fundedTxoSum,
    required this.spentTxoCount,
    required this.spentTxoSum,
    required this.txCount,
  });

  factory Stats.fromJson(Map<String, dynamic> json) => Stats(
        fundedTxoCount: json["funded_txo_count"],
        fundedTxoSum: json["funded_txo_sum"],
        spentTxoCount: json["spent_txo_count"],
        spentTxoSum: json["spent_txo_sum"],
        txCount: json["tx_count"],
      );

  Map<String, dynamic> toJson() => {
        "funded_txo_count": fundedTxoCount,
        "funded_txo_sum": fundedTxoSum,
        "spent_txo_count": spentTxoCount,
        "spent_txo_sum": spentTxoSum,
        "tx_count": txCount,
      };
}
