import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a web page outside the app; returns false when it could not.
typedef UrlOpener = Future<bool> Function(Uri uri);

/// Overridable in tests, which cannot open a browser.
final urlOpenerProvider = Provider<UrlOpener>((ref) {
  return (uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  };
});
