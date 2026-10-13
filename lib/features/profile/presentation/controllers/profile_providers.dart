import 'package:careermatebd/features/settings/presentation/controllers/settings_overview_controller.dart';
import 'package:careermatebd/shared/services/entitlement/entitlement_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the user is on the Pro plan, from [EntitlementService] — the single
/// source of truth for plan status.
final profileIsProProvider = FutureProvider.autoDispose<bool>((ref) {
  return ref.watch(entitlementServiceProvider).isPro;
});

/// "1.0.0 (12)" for the footer, from the same package-info loader Settings
/// uses (without loading Settings' local-data counts). Null when the version
/// cannot be read — the footer is then simply left out.
final appVersionLabelProvider = FutureProvider.autoDispose<String?>((
  ref,
) async {
  try {
    final info = await ref.watch(packageInfoLoaderProvider)();
    return info.buildNumber.trim().isEmpty
        ? info.version
        : '${info.version} (${info.buildNumber})';
  } catch (_) {
    return null;
  }
});
