// To parse this JSON data, do
//
//     final validateAddressComponentModel = validateAddressComponentModelFromJson(jsonString);

import 'dart:convert';

ValidateAddressComponentModel validateAddressComponentModelFromJson(
  String str,
) =>
    ValidateAddressComponentModel.fromJson(json.decode(str));

String validateAddressComponentModelToJson(
  ValidateAddressComponentModel data,
) =>
    json.encode(data.toJson());

class ValidateAddressComponentModel {
  bool isvalid;
  String address;
  String scriptPubKey;
  bool isscript;
  bool iswitness;

  ValidateAddressComponentModel({
    required this.isvalid,
    required this.address,
    required this.scriptPubKey,
    required this.isscript,
    required this.iswitness,
  });

  factory ValidateAddressComponentModel.fromJson(Map<String, dynamic> json) =>
      ValidateAddressComponentModel(
        isvalid: json["isvalid"],
        address: json["address"],
        scriptPubKey: json["scriptPubKey"],
        isscript: json["isscript"],
        iswitness: json["iswitness"],
      );

  Map<String, dynamic> toJson() => {
        "isvalid": isvalid,
        "address": address,
        "scriptPubKey": scriptPubKey,
        "isscript": isscript,
        "iswitness": iswitness,
      };
}
