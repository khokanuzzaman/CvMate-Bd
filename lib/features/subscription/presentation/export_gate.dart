import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/shared/services/analytics/analytics_events.dart';
import 'package:careermatebd/shared/services/analytics/analytics_service.dart';
import 'package:careermatebd/shared/services/entitlement/entitlement_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Runs a PDF export through the single entitlement gate.
///
/// Every export point (CV preview, PDF preview, tailoring) calls this, so the
/// rule lives in one place ([EntitlementService.checkExport]): Pro, or this
/// CV unlocked, or the one free export; otherwise the paywall opens. When the
/// paywall reports a purchase (it pops `true`), the gate is checked once more
/// and the export continues without another tap. The free-export counter
/// moves only after [export] succeeds, and `cv_exported` is logged then.
Future<void> runGatedExport({
  required WidgetRef ref,
  required BuildContext context,
  required String source,
  required String exportType,
  required String? cvId,
  required Future<void> Function() export,
}) async {
  final entitlements = ref.read(entitlementServiceProvider);

  var access = await entitlements.checkExport(cvId: cvId);
  if (access == ExportAccess.blocked) {
    if (!context.mounted) {
      return;
    }
    final purchased = await context.push<bool>(
      '${RouteNames.paywallPath}?source=$source',
    );
    if (purchased != true || !context.mounted) {
      return;
    }
    access = await entitlements.checkExport(cvId: cvId);
    if (access == ExportAccess.blocked || !context.mounted) {
      return;
    }
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

  await entitlements.recordSuccessfulExport(access);
  await ref
      .read(analyticsServiceProvider)
      .logEvent(
        AnalyticsEvents.cvExported,
        params: {
          AnalyticsEvents.paramSource: source,
          AnalyticsEvents.paramType: exportType,
        },
      );
}
