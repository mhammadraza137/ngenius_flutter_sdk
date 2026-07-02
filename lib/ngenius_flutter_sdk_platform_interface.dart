import 'package:ngenius_flutter_sdk/ngenius_response_model.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'ngenius_flutter_sdk_method_channel.dart';

abstract class NgeniusFlutterSdkPlatform extends PlatformInterface {
  /// Constructs a NgeniusFlutterSdkPlatform.
  NgeniusFlutterSdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static NgeniusFlutterSdkPlatform _instance = MethodChannelNgeniusFlutterSdk();

  /// The default instance of [NgeniusFlutterSdkPlatform] to use.
  ///
  /// Defaults to [MethodChannelNgeniusFlutterSdk].
  static NgeniusFlutterSdkPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [NgeniusFlutterSdkPlatform] when
  /// they register themselves.
  static set instance(NgeniusFlutterSdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<NGeniusResponseModel> launchCardPayment({required Map<String, dynamic> orderJsonObject}) async {
    throw UnimplementedError("launchCardPayment() has not been implemented.");
  }

  Future<NGeniusResponseModel> launchSavedCardPayment({
    required Map<String, dynamic> orderJsonObject,
    String? cvv,
  }) async {
    throw UnimplementedError("launchSavedCardPayment() has not been implemented.");
  }
}
