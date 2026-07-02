import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ngenius_flutter_sdk/ngenius_response_model.dart';
import 'ngenius_flutter_sdk_platform_interface.dart';

/// An implementation of [NgeniusFlutterSdkPlatform] that uses method channels.
class MethodChannelNgeniusFlutterSdk extends NgeniusFlutterSdkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('ngenius_flutter_sdk');

  @override
  Future<NGeniusResponseModel> launchCardPayment({required Map<String, dynamic> orderJsonObject}) async {
    try {
      dynamic response = await methodChannel.invokeMethod("launchCardPayment", {"orderJsonObject": orderJsonObject});
      return NGeniusResponseModel.fromJson(json: jsonDecode(response));
    } catch (err) {
      return NGeniusResponseModel(message: err.toString());
    }
  }

  @override
  Future<NGeniusResponseModel> launchSavedCardPayment({
    required Map<String, dynamic> orderJsonObject,
    String? cvv,
  }) async {
    try {
      final Map<String, dynamic> args = {
        "orderJsonObject": orderJsonObject,
      };
      if (cvv != null) {
        args["cvv"] = cvv;
      }
      dynamic response = await methodChannel.invokeMethod(
        "launchSavedCardPayment",
        args,
      );
      return NGeniusResponseModel.fromJson(json: jsonDecode(response));
    } catch (err) {
      return NGeniusResponseModel(message: err.toString());
    }
  }
}
