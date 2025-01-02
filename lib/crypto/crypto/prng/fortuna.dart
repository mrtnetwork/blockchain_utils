import 'dart:math';
import 'package:blockchain_utils/crypto/crypto/aes/aes.dart';
import 'package:blockchain_utils/crypto/crypto/ctr/ctr.dart';
import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:blockchain_utils/exception/exceptions.dart';

/// The `GenerateRandom` typedef defines a function signature for generating random data with a specified length.
typedef GenerateRandom = List<int> Function(int length);

/// The `FortunaPRNG` class represents an implementation of the Fortuna pseudorandom number generator (PRNG) algorithm.
///
/// Fortuna is a cryptographic PRNG designed to provide a strong source of randomness, suitable for various
/// security and cryptographic applications.
///
/// The class includes methods for initializing and generating random data.
class FortunaPRNG {
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

  /// Constructor for the `FortunaPRNG` class, initializing the pseudorandom number generator (PRNG).
  ///
  /// This constructor sets up the `FortunaPRNG` instance with an optional initial seed for randomness.
  ///
  /// Parameters:
  /// - `seed`: An optional `List<int>` seed used to initialize the PRNG. If not provided, the PRNG will be
  ///   initialized with a secure random seed.
  ///
  /// Example Usage:
  /// ```dart
  /// // Initialize a FortunaPRNG instance with a custom seed.
  /// List<int> customSeed = // Provide your custom seed here.
  /// FortunaPRNG prng = FortunaPRNG(customSeed);
  ///
  /// // Initialize a FortunaPRNG instance with a secure random seed.
  /// FortunaPRNG prng = FortunaPRNG();
  /// ```
  ///
  /// This constructor allows you to create a `FortunaPRNG` instance with a specified initial seed for randomness.
  /// If no seed is provided, the PRNG is initialized with a secure random seed.
  FortunaPRNG([List<int>? seed]) {
    _initKey(seed);
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

    if (n > 65536) {
      throw const MessageException('Size is too large!');
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

  void _encryptBlock(List<int> input, int inputLength, List<int> iv,
      List<int> key, List<int> output) {
    final ctr = CTR(AES(key), iv);
    ctr.streamXOR(input, output);
  }

  /// Generates and returns the next 8 bits (1 byte) of pseudorandom data from the Fortuna PRNG.
  ///
  /// If the internal buffer is exhausted, this method generates new blocks of random data to replenish it.
  ///
  /// Returns:
  /// An integer representing the next 8 bits (1 byte) of pseudorandom data.
  ///
  /// This method is used to obtain a single byte of pseudorandom data from the Fortuna PRNG.
  int get nextUint8 {
    if (_c == _out.length) {
      final out = List<int>.filled(16, 0);
      _generateBlocks(out, 1);
      _out.setAll(0, out);
      _c = 0;
    }
    return _out[_c++];
  }

  /// Generates and returns a `List<int>` containing pseudorandom data of the specified length from the Fortuna PRNG.
  ///
  /// Parameters:
  /// - `length`: An integer specifying the desired length of the pseudorandom data in bytes.
  ///
  /// Returns:
  /// A `List<int>` containing the requested pseudorandom data.
  ///
  /// This method is used to generate and return a sequence of pseudorandom bytes of the specified length.
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
    final int result = (_out[_c] << 24) |
        (_out[_c + 1] << 16) |
        (_out[_c + 2] << 8) |
        (_out[_c + 3]);
    _c += 4;
    return result;
  }

  double get nextDouble {
    // Get a 32-bit integer and scale it to the range [0, 1)
    return nextUint32 / 4294967296.0;
  }

  int nextInt(int max) {
    if (max <= 0) throw ArgumentError("max must be greater than 0");

    // Generate a random double in the range [0.0, 1.0)
    final double fraction =
        nextUint32 / 4294967296.0; // Divide by 2^32 to get a fraction
    return (fraction * max).floor();
  }
}
