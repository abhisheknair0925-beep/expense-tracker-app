import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceInfoUtil {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static Future<Map<String, String>> getDeviceInfo() async {
    String deviceId = 'unknown';
    String deviceName = 'unknown';
    String platform = Platform.isAndroid ? 'android' : 'ios';

    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
        deviceId = androidInfo.id; // Unique ID on Android
        deviceName = '${androidInfo.manufacturer} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'unknown_ios';
        deviceName = iosInfo.name;
      }
    } catch (e) {
      debugPrint('Error getting device info: $e');
    }

    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'platform': platform,
    };
  }
}
