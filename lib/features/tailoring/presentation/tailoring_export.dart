import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/features/subscription/presentation/export_gate.dart';
import 'package:careermatebd/features/tailoring/presentation/controllers/tailoring_controller.dart';
import 'package:careermatebd/shared/services/pdf/cv_pdf_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

const String _exportSource = 'tailoring';

/// "Save & export": saves the tailored CV as a new copy (unless this exact
/// result was already saved), then shares the PDF through the single export
/// gate (Pro, an unlocked CV or the one free export; otherwise the paywall).
Future<void> saveAndExportTailored(WidgetRef ref, BuildContext context) async {
  final notifier = ref.read(tailoringControllerProvider.notifier);

  if (ref.read(tailoringControllerProvider).savedCvId == null) {
    final saved = await notifier.saveAsTailoredCopy();
    if (saved == null) {
      return; // the controller reports the failure
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(AppStrings.tailorSavedSnack(saved.displayTitle)),
          ),
        );
    }
  }

  if (!context.mounted) {
    return;
  }
  final profile = notifier.buildTailoredCv();
  if (profile == null) {
    return;
  }
  final pdfService = ref.read(cvPdfServiceProvider);
  final fileName = pdfService.buildFileName(profile);

  await runGatedExport(
    ref: ref,
    context: context,
    source: _exportSource,
    exportType: 'share',
    cvId: _exportedCvId(ref, profile.id),
    export: () async {
      final bytes = await pdfService.generateCvPdf(profile: profile);
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    },
  );
}

/// Prints the tailored CV through the same export gate.
Future<void> printTailored(WidgetRef ref, BuildContext context) async {
  final profile = ref
      .read(tailoringControllerProvider.notifier)
      .buildTailoredCv();
  if (profile == null) {
    return;
  }
  final pdfService = ref.read(cvPdfServiceProvider);
  final fileName = pdfService.buildFileName(profile);

  await runGatedExport(
    ref: ref,
    context: context,
    source: _exportSource,
    exportType: 'print',
    cvId: _exportedCvId(ref, profile.id),
    export: () => Printing.layoutPdf(
      name: fileName,
      onLayout: (format) =>
          pdfService.generateCvPdf(profile: profile, pageFormat: format),
    ),
  );
}

/// The tailored copy once it is saved (its own CV, its own unlock), else the
/// CV being tailored.
String _exportedCvId(WidgetRef ref, String fallback) =>
    ref.read(tailoringControllerProvider).savedCvId ?? fallback;
