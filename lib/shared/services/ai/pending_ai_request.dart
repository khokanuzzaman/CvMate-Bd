import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// The last AI request sent to the server, kept on the device until it is
/// answered, so its `Idempotency-Key` survives the app being killed.
///
/// A retry of the same request (same [bodyHash]) within [ttl] reuses [key],
/// and the server answers it from its cache instead of charging again. When
/// the app restarts with an unanswered entry it fetches the answer with the
/// same key and keeps it in [response] until the user has seen it.
class PendingAiRequest {
  const PendingAiRequest({
    required this.key,
    required this.uid,
    required this.action,
    required this.bodyHash,
    required this.body,
    required this.createdAt,
    this.response,
  });

  /// Shorter than the server's 10-minute replay window, so a key is never
  /// reused after the server has forgotten it.
  static const Duration ttl = Duration(minutes: 9);

  final String key;

  /// The signed-in user who sent it: another user never reuses the entry.
  final String uid;
  final String action;
  final String bodyHash;
  final Map<String, dynamic> body;
  final DateTime createdAt;

  /// The server's answer, once fetched after a restart; null while pending.
  final Map<String, dynamic>? response;

  bool isExpired(DateTime now) => now.difference(createdAt) >= ttl;

  bool matches({required String uid, required String bodyHash}) =>
      this.uid == uid && this.bodyHash == bodyHash;

  PendingAiRequest withResponse(Map<String, dynamic> response) {
    return PendingAiRequest(
      key: key,
      uid: uid,
      action: action,
      bodyHash: bodyHash,
      body: body,
      createdAt: createdAt,
      response: response,
    );
  }

  Map<String, dynamic> toMap() => {
    'key': key,
    'uid': uid,
    'action': action,
    'bodyHash': bodyHash,
    'body': body,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'response': ?response,
  };

  /// Null when [map] is not a complete entry (old or corrupt data).
  static PendingAiRequest? fromMap(Map<String, dynamic> map) {
    final createdAt = DateTime.tryParse('${map['createdAt']}');
    final body = map['body'];
    final response = map['response'];
    final fields = [map['key'], map['uid'], map['action'], map['bodyHash']];
    if (createdAt == null || body is! Map || fields.any((f) => f is! String)) {
      return null;
    }
    return PendingAiRequest(
      key: fields[0]! as String,
      uid: fields[1]! as String,
      action: fields[2]! as String,
      bodyHash: fields[3]! as String,
      body: Map<String, dynamic>.from(body),
      createdAt: createdAt,
      response: response is Map ? Map<String, dynamic>.from(response) : null,
    );
  }

  /// A stable fingerprint of a request body (SHA-256 of its JSON).
  static String hashBody(Map<String, dynamic> body) {
    return sha256.convert(utf8.encode(jsonEncode(body))).toString();
  }
}

/// Where the one [PendingAiRequest] lives. An interface so tests can use
/// [InMemoryPendingAiRequestStore].
abstract class PendingAiRequestStore {
  Future<PendingAiRequest?> load();
  Future<void> save(PendingAiRequest request);
  Future<void> clear();
}

final pendingAiRequestStoreProvider = Provider<PendingAiRequestStore>((ref) {
  return const HivePendingAiRequestStore();
});

class HivePendingAiRequestStore implements PendingAiRequestStore {
  const HivePendingAiRequestStore();

  static const String _boxName = 'ai_pending_request_box';
  static const String _entryKey = 'pending';

  @override
  Future<PendingAiRequest?> load() async {
    final raw = (await _openBox()).get(_entryKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      return PendingAiRequest.fromMap(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(PendingAiRequest request) async {
    await (await _openBox()).put(_entryKey, jsonEncode(request.toMap()));
  }

  @override
  Future<void> clear() async {
    await (await _openBox()).delete(_entryKey);
  }

  Future<Box<String>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<String>(_boxName);
    }
    return Hive.openBox<String>(_boxName);
  }
}

class InMemoryPendingAiRequestStore implements PendingAiRequestStore {
  PendingAiRequest? entry;

  @override
  Future<PendingAiRequest?> load() async => entry;

  @override
  Future<void> save(PendingAiRequest request) async => entry = request;

  @override
  Future<void> clear() async => entry = null;
}
