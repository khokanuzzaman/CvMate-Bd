import 'package:careermatebd/shared/services/entitlement/ai_entitlement.dart';
import 'package:careermatebd/shared/services/entitlement/ai_entitlement_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

const AiEntitlement freeEntitlement = AiEntitlement(
  isPro: false,
  actionsLeft: 3,
);

const AiEntitlement proEntitlement = AiEntitlement(
  isPro: true,
  actionsLeft: 100,
);

/// Stands in for the AI server's entitlement: starts at [initial]; each
/// refresh moves to the next of [afterRefresh] (the last one repeats), like
/// the server picking up a purchase a few refreshes later.
class FakeAiEntitlementController extends AiEntitlementController {
  FakeAiEntitlementController(
    this.initial, {
    this.afterRefresh = const [],
    this.claimable = false,
  });

  final AiEntitlement? initial;
  final List<AiEntitlement?> afterRefresh;

  /// Whether [claimExportUnlock] succeeds.
  bool claimable;
  int refreshCount = 0;
  final List<String> claims = [];

  @override
  Future<AiEntitlement?> build() async => initial;

  @override
  Future<void> refresh() async {
    refreshCount++;
    if (afterRefresh.isNotEmpty) {
      final index = (refreshCount - 1).clamp(0, afterRefresh.length - 1);
      state = AsyncData(afterRefresh[index]);
    }
  }

  @override
  Future<bool> claimExportUnlock(String cvId) async {
    claims.add(cvId);
    return claimable;
  }
}

/// Overrides for a fixed or scripted server entitlement, with no waiting
/// between refreshes.
List<Override> fakeEntitlementOverrides(FakeAiEntitlementController fake) => [
  aiEntitlementProvider.overrideWith(() => fake),
  entitlementPollDelaysProvider.overrideWithValue(const [
    Duration.zero,
    Duration.zero,
    Duration.zero,
  ]),
];
