import 'dart:math';

/// A fresh `Idempotency-Key` for one logical AI request: 32 hex characters
/// from a secure random source. Every retry of that request reuses it, so the
/// AI server answers a retry from its cache instead of charging again.
String newIdempotencyKey([Random? random]) {
  final source = random ?? Random.secure();
  final buffer = StringBuffer();
  for (var i = 0; i < 16; i++) {
    buffer.write(source.nextInt(256).toRadixString(16).padLeft(2, '0'));
  }
  return buffer.toString();
}
