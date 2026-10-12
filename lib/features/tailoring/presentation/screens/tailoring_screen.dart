import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/widgets/custom_empty_state.dart';
import 'package:careermatebd/core/widgets/custom_loading_view.dart';
import 'package:careermatebd/features/tailoring/presentation/controllers/tailoring_controller.dart';
import 'package:careermatebd/features/tailoring/presentation/controllers/tailoring_flow_controller.dart';
import 'package:careermatebd/features/tailoring/presentation/controllers/tailoring_state.dart';
import 'package:careermatebd/features/tailoring/presentation/widgets/tailor_match_page.dart';
import 'package:careermatebd/features/tailoring/presentation/widgets/tailor_paste_page.dart';
import 'package:careermatebd/features/tailoring/presentation/widgets/tailor_result_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// "Tailor to a job": three pages (paste → match → result) driven by
/// [tailoringFlowProvider]; all the work happens in [TailoringController].
class TailoringScreen extends ConsumerStatefulWidget {
  const TailoringScreen({super.key});

  @override
  ConsumerState<TailoringScreen> createState() => _TailoringScreenState();
}

class _TailoringScreenState extends ConsumerState<TailoringScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tailoringControllerProvider.notifier).initialize();
    });
  }

  void _handleBack() {
    if (!ref.read(tailoringFlowProvider.notifier).back()) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<TailoringState>(tailoringControllerProvider, (previous, next) {
      final message = next.failure?.message;
      if (message != null && message != previous?.failure?.message) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      }
    });

    final state = ref.watch(tailoringControllerProvider);
    final page = ref.watch(tailoringFlowProvider);

    if (state.isLoading && !state.hasInitialized) {
      return const _Plain(
        child: CustomLoadingView(message: AppStrings.tailorLoadingCvs),
      );
    }

    if (state.hasInitialized && !state.hasSavedCvs) {
      return _Plain(
        child: const Padding(
          padding: EdgeInsets.all(AppSpacing.s22),
          child: CustomEmptyState(
            title: AppStrings.tailorNoCvTitle,
            message: AppStrings.tailorNoCvBody,
            icon: Icons.tips_and_updates_outlined,
          ),
        ),
      );
    }

    return PopScope(
      canPop: page == TailoringPage.paste,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: switch (page) {
        TailoringPage.paste => TailorPastePage(onBack: _handleBack),
        TailoringPage.match => TailorMatchPage(onBack: _handleBack),
        TailoringPage.result => TailorResultPage(onBack: _handleBack),
      },
    );
  }
}

/// Loading / empty states: the page ground with a back button and no steps.
class _Plain extends StatelessWidget {
  const _Plain({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text(AppStrings.tailorTitle),
      ),
      body: SafeArea(child: Center(child: child)),
    );
  }
}
