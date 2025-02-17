import 'dart:io';

class AdHelper {

  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return const String.fromEnvironment('unitId');
    } else {
      throw UnsupportedError("Unsupported platform");
    }
  }
}