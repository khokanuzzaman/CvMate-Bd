import 'dart:io';

import 'package:careermatebd/shared/services/analytics/analytics_service.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// The optional "attach diagnostics" block of a feedback message: versions,
/// device model and recent analytics event *names*. No content, no ids.
class FeedbackDiagnostics {
  const FeedbackDiagnostics({
    required this.appVersion,
    required this.buildNumber,
    required this.platform,
    required this.osVersion,
    required this.deviceModel,
    required this.recentEvents,
  });

  final String appVersion;
  final String buildNumber;

  /// `ios` or `android`.
  final String platform;
  final String osVersion;

  /// The hardware model, e.g. `iPhone17,3`.
  final String deviceModel;

  /// Oldest first, at most 20.
  final List<String> recentEvents;

  Map<String, Object> toJson() => {
    'appVersion': appVersion,
    'buildNumber': buildNumber,
    'platform': platform,
    'osVersion': osVersion,
    'deviceModel': deviceModel,
    'recentEvents': recentEvents,
  };
}

typedef DiagnosticsReader = Future<FeedbackDiagnostics> Function();

final feedbackDiagnosticsReaderProvider = Provider<DiagnosticsReader>((ref) {
  return () async {
    final package = await PackageInfo.fromPlatform();
    final device = DeviceInfoPlugin();
    var platform = Platform.operatingSystem;
    var osVersion = '';
    var model = '';
    if (Platform.isIOS) {
      final ios = await device.iosInfo;
      platform = 'ios';
      osVersion = ios.systemVersion;
      model = ios.utsname.machine;
    } else if (Platform.isAndroid) {
      final android = await device.androidInfo;
      platform = 'android';
      osVersion = android.version.release;
      model = android.model;
    }
    return FeedbackDiagnostics(
      appVersion: package.version,
      buildNumber: package.buildNumber,
      platform: platform,
      osVersion: osVersion,
      deviceModel: model,
      recentEvents: ref.read(analyticsServiceProvider).recentEventNames,
    );
  };
});
