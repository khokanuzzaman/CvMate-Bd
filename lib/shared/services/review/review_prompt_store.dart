import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// What the rating rules remember between launches. No content.
class ReviewPromptRecord {
  const ReviewPromptRecord({
    this.launches = 0,
    this.successfulTailorings = 0,
    this.lastRequestedAt,
  });

  factory ReviewPromptRecord.fromMap(Map<String, dynamic> map) {
    final last = map['lastRequestedAt'];
    return ReviewPromptRecord(
      launches: map['launches'] is int ? map['launches'] as int : 0,
      successfulTailorings: map['successfulTailorings'] is int
          ? map['successfulTailorings'] as int
          : 0,
      lastRequestedAt: last is int
          ? DateTime.fromMillisecondsSinceEpoch(last)
          : null,
    );
  }

  /// App launches so far, this one included.
  final int launches;
  final int successfulTailorings;
  final DateTime? lastRequestedAt;

  ReviewPromptRecord copyWith({
    int? launches,
    int? successfulTailorings,
    DateTime? lastRequestedAt,
  }) {
    return ReviewPromptRecord(
      launches: launches ?? this.launches,
      successfulTailorings: successfulTailorings ?? this.successfulTailorings,
      lastRequestedAt: lastRequestedAt ?? this.lastRequestedAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'launches': launches,
    'successfulTailorings': successfulTailorings,
    'lastRequestedAt': ?lastRequestedAt?.millisecondsSinceEpoch,
  };
}

abstract class ReviewPromptStore {
  Future<ReviewPromptRecord> load();
  Future<void> save(ReviewPromptRecord record);
}

final reviewPromptStoreProvider = Provider<ReviewPromptStore>((ref) {
  return const HiveReviewPromptStore();
});

/// Hive, opened in `main()` ([openBox]); where it is not open (widget tests)
/// nothing is stored and no rating is ever requested.
class HiveReviewPromptStore implements ReviewPromptStore {
  const HiveReviewPromptStore();

  static const String boxName = 'review_prompt_box';
  static const String _key = 'review_prompt';

  static Future<void> openBox() => Hive.openBox<String>(boxName);

  Box<String>? get _box =>
      Hive.isBoxOpen(boxName) ? Hive.box<String>(boxName) : null;

  @override
  Future<ReviewPromptRecord> load() async {
    final raw = _box?.get(_key);
    if (raw == null || raw.isEmpty) {
      return const ReviewPromptRecord();
    }
    try {
      return ReviewPromptRecord.fromMap(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return const ReviewPromptRecord();
    }
  }

  @override
  Future<void> save(ReviewPromptRecord record) async {
    await _box?.put(_key, jsonEncode(record.toMap()));
  }
}

/// In-memory store for tests.
class MemoryReviewPromptStore implements ReviewPromptStore {
  MemoryReviewPromptStore([this.record = const ReviewPromptRecord()]);

  ReviewPromptRecord record;

  @override
  Future<ReviewPromptRecord> load() async => record;

  @override
  Future<void> save(ReviewPromptRecord record) async => this.record = record;
}
