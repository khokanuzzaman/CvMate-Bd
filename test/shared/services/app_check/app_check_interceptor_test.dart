import 'package:careermatebd/shared/services/ai/ai_server_client.dart';
import 'package:careermatebd/shared/services/app_check/app_check_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_ai_server.dart';

void main() {
  AiServerClient clientFor(FakeAiServer server, AppCheckTokenReader reader) {
    final dio = server.dio()..interceptors.add(AppCheckInterceptor(reader));
    return AiServerClient(
      dio: dio,
      readIdToken: ({bool forceRefresh = false}) async => 'id-token',
    );
  }

  test('every request to our server carries the App Check token', () async {
    final server = FakeAiServer([const FakeAiReply(200, {'ok': true})]);
    final client = clientFor(server, () async => 'app-check-token');

    await client.getJson('/v1/me/entitlement');
    await client.postJson('/v1/feedback', {'category': 'bug'});
    await client.deleteJson('/v1/me');

    expect(server.requests, hasLength(3));
    for (final request in server.requests) {
      expect(request.headers[appCheckHeader], 'app-check-token');
      expect(request.headers['Authorization'], 'Bearer id-token');
    }
  });

  test('no token, or a failing App Check, never blocks the request', () async {
    final server = FakeAiServer([const FakeAiReply(200, {'ok': true})]);

    await clientFor(server, () async => null).getJson('/v1/me/entitlement');
    await clientFor(
      server,
      () async => throw StateError('attestation failed'),
    ).getJson('/v1/me/entitlement');

    expect(server.requests, hasLength(2));
    for (final request in server.requests) {
      expect(request.headers.containsKey(appCheckHeader), isFalse);
    }
  });
}
