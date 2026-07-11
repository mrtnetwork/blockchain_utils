import 'dart:math' show Random;
import 'package:blockchain_utils/crypto/crypto/aes/aes.dart';
import 'package:blockchain_utils/crypto/crypto/ctr/ctr.dart';
import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:blockchain_utils/crypto/crypto/prng/rng.dart';
import 'package:blockchain_utils/exception/exceptions.dart';

/// The `CbGenerateRandom` typedef defines a function signature for generating random data with a specified length.
typedef CbGenerateRandom = List<int> Function(int length);

/// The [FortunaPRNG] class represents an implementation of the Fortuna pseudorandom number generator (PRNG) algorithm.
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

  /// Constructor for the [FortunaPRNG] class, initializing the pseudorandom number generator (PRNG).
  ///
  /// Parameters:
  /// - [seed]: An optional seed used to initialize the PRNG. If not provided, the PRNG will be
  ///   initialized with a secure random seed.
  ///
  FortunaPRNG([List<int>? seed]) {
    _initKey(seed);
  }

  FortunaPRNG.fromEntropy(List<int> entropy) {
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
    ctr.streamXOR(input, output);
  }

  /// Generates and returns the next 8 bits (1 byte) of pseudorandom data from the Fortuna PRNG.
  int get nextUint8 {
    if (_c == _out.length) {
      final out = List<int>.filled(16, 0);
      _generateBlocks(out, 1);
      _out.setAll(0, out);
      _c = 0;
    }
    return _out[_c++];
  }

  /// Generates and returns a bytes containing pseudorandom data of the specified length from the Fortuna PRNG.
  ///
  /// Parameters:
  /// - [length]: An integer specifying the desired length of the pseudorandom data in bytes.
  ///
  @override
  List<int> nextBytes(int length) {
    final out = List<int>.filled(length, 0);
    for (int i = 0; i < length; i++) {
      out[i] = nextUint8;
    }
    return out;
  }

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
      throw ArgumentException.invalidOperationArguments(
        "nextInt",
        name: "max",
        reason: "Max must be greater than 0",
      );
    }

    final double fraction = nextUint32 / 4294967296.0;
    return (fraction * max).floor();
  }

  BigInt nextUint64() {
    // Two 32-bit halves → full 64-bit
    final hi = nextInt(1 << 32);
    final lo = nextInt(1 << 32);

    return (BigInt.from(hi) << 32) | BigInt.from(lo);
  }
}
