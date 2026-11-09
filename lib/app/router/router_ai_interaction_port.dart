import 'package:careermatebd/app/router/app_router.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/features/settings/presentation/widgets/ai_consent_sheet.dart';
import 'package:careermatebd/shared/services/ai/ai_consent_guard.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final aiInteractionPortProvider = Provider<AiInteractionPort>((ref) {
  return NavigatorAiInteractionPort(
    // Read lazily: the router is rebuilt on sign-in/out.
    context: () =>
        ref.read(appRouterProvider).routerDelegate.navigatorKey.currentContext,
    push: (location) => ref.read(appRouterProvider).push<void>(location),
  );
});

/// Shows the consent sheet on the app's root navigator and opens the paywall
/// through the router.
class NavigatorAiInteractionPort implements AiInteractionPort {
  const NavigatorAiInteractionPort({required this.context, required this.push});

  final BuildContext? Function() context;
  final void Function(String location) push;

  @override
  Future<bool> requestAiConsent() async {
    final current = context();
    if (current == null || !current.mounted) {
      return false;
    }
    return showAiConsentSheet(current);
  }

  @override
  void openPaywall(String source) {
    push('${RouteNames.paywallPath}?source=$source');
  }
}
