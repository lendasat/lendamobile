class FearGearChartModel {
  LastUpdated? lastUpdated;
  Fgi? fgi;

  FearGearChartModel({this.lastUpdated, this.fgi});

  FearGearChartModel.fromJson(Map<String, dynamic> json) {
    lastUpdated = json['lastUpdated'] != null
        ? new LastUpdated.fromJson(json['lastUpdated'])
        : null;
    fgi = json['fgi'] != null ? new Fgi.fromJson(json['fgi']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.lastUpdated != null) {
      data['lastUpdated'] = this.lastUpdated!.toJson();
    }
    if (this.fgi != null) {
      data['fgi'] = this.fgi!.toJson();
    }
    return data;
  }
}

class LastUpdated {
  int? epochUnixSeconds;
  String? humanDate;

  LastUpdated({this.epochUnixSeconds, this.humanDate});

  LastUpdated.fromJson(Map<String, dynamic> json) {
    epochUnixSeconds = json['epochUnixSeconds'];
    humanDate = json['humanDate'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['epochUnixSeconds'] = this.epochUnixSeconds;
    data['humanDate'] = this.humanDate;
    return data;
  }
}

class Fgi {
  Now? now;
  Now? previousClose;
  Now? oneWeekAgo;
  Now? oneMonthAgo;
  Now? oneYearAgo;

  Fgi({
    this.now,
    this.previousClose,
    this.oneWeekAgo,
    this.oneMonthAgo,
    this.oneYearAgo,
  });

  Fgi.fromJson(Map<String, dynamic> json) {
    now = json['now'] != null ? new Now.fromJson(json['now']) : null;
    previousClose = json['previousClose'] != null
        ? new Now.fromJson(json['previousClose'])
        : null;
    oneWeekAgo = json['oneWeekAgo'] != null
        ? new Now.fromJson(json['oneWeekAgo'])
        : null;
    oneMonthAgo = json['oneMonthAgo'] != null
        ? new Now.fromJson(json['oneMonthAgo'])
        : null;
    oneYearAgo = json['oneYearAgo'] != null
        ? new Now.fromJson(json['oneYearAgo'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.now != null) {
      data['now'] = this.now!.toJson();
    }
    if (this.previousClose != null) {
      data['previousClose'] = this.previousClose!.toJson();
    }
    if (this.oneWeekAgo != null) {
      data['oneWeekAgo'] = this.oneWeekAgo!.toJson();
    }
    if (this.oneMonthAgo != null) {
      data['oneMonthAgo'] = this.oneMonthAgo!.toJson();
    }
    if (this.oneYearAgo != null) {
      data['oneYearAgo'] = this.oneYearAgo!.toJson();
    }
    return data;
  }
}

class Now {
  int? value;
  String? valueText;

  Now({this.value, this.valueText});

  Now.fromJson(Map<String, dynamic> json) {
    value = json['value'];
    valueText = json['valueText'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['value'] = this.value;
    data['valueText'] = this.valueText;
    return data;
  }
}
