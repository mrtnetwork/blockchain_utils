import 'dart:math' show Random;

import 'package:blockchain_utils/crypto/crypto/cipher/blockcipher/aes/aes.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/cipher/blockcipher/ctr/ctr.dart';
import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:blockchain_utils/crypto/crypto/prng/src/rng.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/utils/binary/src/binary_operation.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Generates [length] bytes of random data.
typedef CbGenerateRandom = BuBytes Function(int length);

/// The Fortuna CSPRNG (AES-CTR based, with automatic re-keying after every
/// block generation to resist state compromise).
///
/// NOTE: [nextInt]/[nextUint64] bound their output by dividing/multiplying
/// doubles rather than rejection sampling, which (like the same pattern in
/// [Rng]) has a theoretical rounding edge case very close to the top of
/// the requested range rather than being perfectly uniform.
class FortunaPRNG with Rng {
  late final List<int> _key = List<int>.filled(32, 0);
  late final List<int> _counter = List<int>.filled(16, 0);
  final List<int> _zeroBlock = List<int>.filled(16, 0);
  final List<int> _out = List<int>.filled(16, 0);
  int _c = 0;

  static List<int> _generateSeed([int digestLen = 32]) {
    final rand = Random.secure();
    final seed = List<int>.filled(digestLen, 0);
    for (int i = 0; i < seed.length; i++) {
      seed[i] = rand.nextInt(256);
    }
    return seed;
  }

  /// Creates a [FortunaPRNG], seeded with [seed] plus secure system entropy.
  FortunaPRNG([List<int>? seed]) {
    _initKey(seed);
  }

  /// Creates a [FortunaPRNG] seeded solely from [entropy] (no extra system randomness mixed in).
  FortunaPRNG.fromEntropy(List<int> entropy) {
    // NOTE: uses SHAKE256 directly (not QuickCrypto.shake256Instance()) to avoid a
    // boot cycle: QuickCrypto statics need blockchainUtils.api, which is only
    // set after PRNG-dependent Dart APIs finish constructing.
    final k = SHAKE256();
    k.update(entropy);
    _key.setAll(0, k.digest());
    k.clean();
    _generateBlocks(_out, 1);
  }

  void _initKey([List<int>? seed]) {
    final k = SHAKE256();
    k.update(seed ?? <int>[]);
    k.update(_generateSeed(32));
    _key.setAll(0, k.digest());
    k.clean();
    _generateBlocks(_out, 1);
  }

  void _generateBlocks(List<int> out, int n) {
    if (n == 0) {
      return;
    }
    final tempBlock = List<int>.filled(32, 0);

    for (int i = 0; i < n; i++) {
      _encryptBlock(_counter, 16, _zeroBlock, _key, tempBlock);
      out.setRange(i * 16, i * 16 + 16, tempBlock);
      _count();
    }

    final newKey = List<int>.filled(32, 0);

    _encryptBlock(_counter, 16, _zeroBlock, _key, tempBlock);
    newKey.setRange(0, 16, tempBlock);
    _count();

    _encryptBlock(_counter, 16, _zeroBlock, _key, tempBlock);
    newKey.setRange(16, 32, tempBlock);
    _count();

    _key.setAll(0, newKey);
  }

  void _count() {
    for (int i = 0; i < _counter.length; i++) {
      _counter[i] += 1;
    }
  }

  void _encryptBlock(
    List<int> input,
    int inputLength,
    List<int> iv,
    List<int> key,
    List<int> output,
  ) {
    final ctr = CTR(AES(key), iv);
    ctr.process(input, output);
  }

  /// The next byte of pseudorandom data.
  int get nextUint8 {
    if (_c == _out.length) {
      final out = List<int>.filled(16, 0);
      _generateBlocks(out, 1);
      _out.setAll(0, out);
      _c = 0;
    }
    return _out[_c++];
  }

  @override
  BuBytes nextBytes(int length) {
    final out = BuBytes.fill(length, 0);
    for (int i = 0; i < length; i++) {
      out[i] = nextUint8;
    }
    return out;
  }

  /// The next 32 bits of pseudorandom data, big-endian.
  int get nextUint32 {
    if (_c + 4 > _out.length) {
      _generateBlocks(_out, 1);
      _c = 0;
    }
    final int result =
        (_out[_c] << 24) |
        (_out[_c + 1] << 16) |
        (_out[_c + 2] << 8) |
        (_out[_c + 3]);
    _c += 4;
    return result;
  }

  @override
  double nextDouble() {
    // Get a 32-bit integer and scale it to the range [0, 1)
    return nextUint32 / 4294967296.0;
  }

  @override
  int nextInt(int max) {
    if (max <= 0) {
      throw CoreErrors.invalidOperationArguments(
        "nextInt",
        name: "max",
        reason: "Max must be greater than 0",
      );
    }

    final double fraction = nextUint32 / 4294967296.0;
    return (fraction * max).floor();
  }

  /// The next 64 bits of pseudorandom data, as two 32-bit halves.
  BigInt nextUint64() {
    final hi = nextInt(1 << 32);
    final lo = nextInt(1 << 32);

    return (BigInt.from(hi) << 32) | BigInt.from(lo);
  }

  /// Zeroes the key, counter and output buffer. The instance must be
  /// re-seeded (via a fresh [FortunaPRNG]) before further use.
  void clean() {
    BinaryOps.zero(_key);
    BinaryOps.zero(_counter);
    BinaryOps.zero(_out);
    _c = 0;
  }
}
