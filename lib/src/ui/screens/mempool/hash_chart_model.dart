/// Model for hashrate chart data
class HashChartModel {
  List<Hashrate>? hashrates;
  String? currentHashrate;
  String? currentDifficulty;

  HashChartModel({
    this.hashrates,
    this.currentHashrate,
    this.currentDifficulty,
  });

  HashChartModel.fromJson(Map<String, dynamic> json) {
    if (json['hashrates'] != null) {
      hashrates = <Hashrate>[];
      json['hashrates'].forEach((v) {
        hashrates!.add(Hashrate.fromJson(v));
      });
    }
    currentHashrate = json['currentHashrate']?.toString();
    currentDifficulty = json['currentDifficulty']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (hashrates != null) {
      data['hashrates'] = hashrates!.map((v) => v.toJson()).toList();
    }
    data['currentHashrate'] = currentHashrate;
    data['currentDifficulty'] = currentDifficulty;
    return data;
  }
}

/// Individual hashrate data point
class Hashrate {
  num? timestamp;
  double? avgHashrate;

  Hashrate({this.timestamp, this.avgHashrate});

  Hashrate.fromJson(Map<String, dynamic> json) {
    timestamp = json['timestamp'];
    avgHashrate = json['avgHashrate']?.toDouble();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['timestamp'] = timestamp;
    data['avgHashrate'] = avgHashrate;
    return data;
  }
}

/// Difficulty data point for chart
class Difficulty {
  num? time;
  double? difficulty;
  num? height;

  Difficulty({this.time, this.difficulty, this.height});

  Difficulty.fromJson(Map<String, dynamic> json) {
    time = json['time'];
    difficulty = json['difficulty']?.toDouble();
    height = json['height'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['time'] = time;
    data['difficulty'] = difficulty;
    data['height'] = height;
    return data;
  }
}
