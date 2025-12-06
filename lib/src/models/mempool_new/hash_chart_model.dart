//lib/pages/transactions/model/hash_chart_model.dart

// To parse this JSON data, do
//
//     final hashChartModel = hashChartModelFromJson(jsonString);

import 'dart:convert';

HashChartModel hashChartModelFromJson(String str) =>
    HashChartModel.fromJson(json.decode(str));

String hashChartModelToJson(HashChartModel data) => json.encode(data.toJson());

class HashChartModel {
  List<Hashrate>? hashrates;
  List<Difficulty>? difficulty;
  double? currentHashrate;
  double? currentDifficulty;

  HashChartModel({
    this.hashrates,
    this.difficulty,
    this.currentHashrate,
    this.currentDifficulty,
  });

  factory HashChartModel.fromJson(Map<String, dynamic> json) => HashChartModel(
    hashrates: json["hashrates"] == null
        ? []
        : List<Hashrate>.from(
            json["hashrates"]!.map((x) => Hashrate.fromJson(x)),
          ),
    difficulty: json["difficulty"] == null
        ? []
        : List<Difficulty>.from(
            json["difficulty"]!.map((x) => Difficulty.fromJson(x)),
          ),
    currentHashrate: json["currentHashrate"]?.toDouble(),
    currentDifficulty: json["currentDifficulty"]?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    "hashrates": hashrates == null
        ? []
        : List<dynamic>.from(hashrates!.map((x) => x.toJson())),
    "difficulty": difficulty == null
        ? []
        : List<dynamic>.from(difficulty!.map((x) => x.toJson())),
    "currentHashrate": currentHashrate,
    "currentDifficulty": currentDifficulty,
  };
}

class Difficulty {
  int? time;
  int? height;
  double? difficulty;
  double? adjustment;

  Difficulty({this.time, this.height, this.difficulty, this.adjustment});

  factory Difficulty.fromJson(Map<String, dynamic> json) => Difficulty(
    time: json["time"],
    height: json["height"],
    difficulty: json["difficulty"]?.toDouble(),
    adjustment: json["adjustment"]?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    "time": time,
    "height": height,
    "difficulty": difficulty,
    "adjustment": adjustment,
  };
}

class Hashrate {
  int? timestamp;
  double? avgHashrate;

  Hashrate({this.timestamp, this.avgHashrate});

  factory Hashrate.fromJson(Map<String, dynamic> json) => Hashrate(
    timestamp: json["timestamp"],
    avgHashrate: json["avgHashrate"]?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    "timestamp": timestamp,
    "avgHashrate": avgHashrate,
  };
}
