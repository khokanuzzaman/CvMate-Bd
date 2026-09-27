import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/shared/services/analytics/analytics_events.dart';
import 'package:careermatebd/shared/services/analytics/analytics_service.dart';
import 'package:careermatebd/shared/services/entitlement/entitlement_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Runs a PDF export through the single entitlement gate.
///
/// Both export points (CV PDF preview and tailoring) call this so the
/// fair-export rule lives in exactly one place: the first clean export is free,
/// after which a non-Pro user is sent to the paywall placeholder. The usage
/// counter is incremented only after [export] succeeds, and `cv_exported` is
/// logged on success.
Future<void> runGatedExport({
  required WidgetRef ref,
  required BuildContext context,
  required String source,
  required String exportType,
  required Future<void> Function() export,
}) async {
  final entitlements = ref.read(entitlementServiceProvider);

  if (!await entitlements.canExport()) {
    if (!context.mounted) {
      return;
    }
    context.push('${RouteNames.paywallPath}?source=$source');
    return;
  }

  try {
    await export();
  } catch (error) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('PDF export failed. $error')));
    return;
  }

  await entitlements.recordSuccessfulExport();
  await ref.read(analyticsServiceProvider).logEvent(
    AnalyticsEvents.cvExported,
    params: {
      AnalyticsEvents.paramSource: source,
      AnalyticsEvents.paramType: exportType,
    },
  );
}
