import 'package:careermatebd/shared/services/ai/ai_server_client.dart';
import 'package:careermatebd/shared/services/entitlement/ai_entitlement.dart';
import 'package:careermatebd/shared/services/entitlement/ai_entitlement_controller.dart';
import 'package:careermatebd/shared/services/entitlement/ai_entitlement_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_ai_entitlement.dart';
import '../../../helpers/fake_ai_server.dart';

class _MemoryCache implements AiEntitlementCache {
  final Map<String, AiEntitlement> values = {};

  @override
  Future<AiEntitlement?> read(String uid) async => values[uid];

  @override
  Future<void> write(String uid, AiEntitlement entitlement) async =>
      values[uid] = entitlement;

  @override
  Future<void> clear() async => values.clear();
}

void main() {
  test('purchase sync posts only the token to the sync endpoint and caches '
      'the Pro the server returns', () async {
    final server = FakeAiServer([
      const FakeAiReply(200, {
        'plan': 'pro',
        'proExpiresAt': 1795000000000,
        'actionsLeft': 100,
        'resetsAt': null,
        'cvExportUnlocks': 0,
        'unlockedCvIds': <String>[],
        'synced': true,
      }),
    ]);
    final cache = _MemoryCache();
    final repository = AiEntitlementRepository(
      client: AiServerClient(
        dio: server.dio(),
        readIdToken: ({bool forceRefresh = false}) async => 'token',
      ),
      cache: cache,
    );

    final value = await repository.sync('u1');

    expect(server.requests.single.method, 'POST');
    expect(server.requests.single.path, AiEntitlementRepository.syncPath);
    expect(server.sentBodies.single, isEmpty);
    expect(value.isPro, isTrue);
    expect(cache.values['u1']?.isPro, isTrue);
  });

  test('after a purchase the first check is a purchase sync; when it shows '
      'Pro there is no polling', () async {
    final fake = FakeAiEntitlementController(
      freeEntitlement,
      afterRefresh: const [proEntitlement],
    );
    final container = ProviderContainer(
      overrides: fakeEntitlementOverrides(fake),
    );
    addTearDown(container.dispose);
    await container.read(aiEntitlementProvider.future);

    final active = await container
        .read(aiEntitlementProvider.notifier)
        .refreshUntil((value) => value.isPro);

    expect(active, isTrue);
    expect(fake.syncCount, 1);
    expect(fake.refreshCount, 1, reason: 'the sync itself, no extra poll');
  });
}
