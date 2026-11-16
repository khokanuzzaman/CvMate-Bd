import 'dart:async';

import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/shared/services/analytics/analytics_events.dart';
import 'package:careermatebd/shared/services/analytics/analytics_service.dart';
import 'package:careermatebd/shared/services/crash/crash_reporter.dart';
import 'package:careermatebd/shared/services/entitlement/entitlement_service.dart';
import 'package:careermatebd/shared/services/review/review_prompter.dart';
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
/// moves only after [export] succeeds.
///
/// Analytics: `export_start`, then `export_result` with the gate that let it
/// through. A success may ask for a rating; a failure is a setback and a
/// non-fatal (code only).
Future<void> runGatedExport({
  required WidgetRef ref,
  required BuildContext context,
  required ExportSource source,
  required ExportFormat format,
  required String? cvId,
  required Future<void> Function() export,
}) async {
  final entitlements = ref.read(entitlementServiceProvider);
  final analytics = ref.read(analyticsServiceProvider);
  final review = ref.read(reviewPrompterProvider);
  void logResult(ExportResult result, {ExportGate? gate}) => unawaited(
    analytics.log(
      AnalyticsEvent.exportResult(source, format, result, gate: gate),
    ),
  );

  unawaited(analytics.log(AnalyticsEvent.exportStart(source, format)));
  var access = await entitlements.checkExport(cvId: cvId);
  var purchased = false;
  if (access == ExportAccess.blocked) {
    if (!context.mounted) {
      return;
    }
    purchased =
        await context.push<bool>(
          '${RouteNames.paywallPath}?source=${source.wire}',
        ) ==
        true;
    if (!purchased || !context.mounted) {
      logResult(ExportResult.paywallClosed);
      return;
    }
    access = await entitlements.checkExport(cvId: cvId);
    if (access == ExportAccess.blocked || !context.mounted) {
      logResult(ExportResult.paywallClosed);
      return;
    }
  }

  try {
    await export();
  } catch (error) {
    logResult(ExportResult.failed);
    review.recordSetback();
    unawaited(
      ref
          .read(crashReporterProvider)
          .recordNonFatal(CrashArea.export, 'pdf_export_failed'),
    );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('PDF export failed. $error')));
    return;
  }

  await entitlements.recordSuccessfulExport(access);
  logResult(
    ExportResult.ok,
    gate: purchased
        ? ExportGate.purchased
        : switch (access) {
            ExportAccess.pro => ExportGate.pro,
            ExportAccess.unlockedCv => ExportGate.unlock,
            ExportAccess.freeExport || ExportAccess.blocked => ExportGate.free,
          },
  );
  unawaited(review.onExportSucceeded());
}
