part of 'package:blockchain_utils/crypto/crypto/hash/hash.dart';

/// The `SHA512256` class extends the SHA-512 hash function, specifically
/// truncating its output to 256 bits (32 bytes). It inherits the implementation
/// of the SHA-512 hash algorithm
///
/// Example usage:
/// ```dart
/// final data = List<int>.from([0, 1, 2, 3, 4, 5]);
/// final sha512256Hash = SHA512256().update(data).digest();
/// ```
///
/// This class allows you to compute a SHA-512/256 hash, which is a widely-used
/// cryptographic hash function known for its security and is often used in
/// various security and data integrity applications
class SHA512256 extends SHA512 {
  /// digest length
  static const int digestLength = 32;

  /// block size
  static const int blockSize = 128;

  @override
  int get getDigestLength => SHA512256.digestLength;
  @override
  int get getBlockSize => SHA512256.blockSize;

  @override
  void _initState() {
    _stateHi[0] = 0x22312194;
    _stateHi[1] = 0x9f555fa3;
    _stateHi[2] = 0x2393b86b;

    _stateHi[3] = 0x96387719;

    _stateHi[4] = 0x96283ee2;
    _stateHi[5] = 0xbe5e1e25;
    _stateHi[6] = 0x2b0199fc;
    _stateHi[7] = 0x0eb72ddc;

    _stateLo[0] = 0xfc2bf72c;
    _stateLo[1] = 0xc84c64c2;
    _stateLo[2] = 0x6f53b151;
    _stateLo[3] = 0x5940eabd;
    _stateLo[4] = 0xa88effe3;
    _stateLo[5] = 0x53863992;
    _stateLo[6] = 0x2c85b8aa;
    _stateLo[7] = 0x81c52ca2;
  }

  /// Computes the SHA-512/256 hash of the provided data.
  static List<int> hash(List<int> data) {
    final h = SHA512256();
    h.update(data);
    final digest = h.digest();
    h.clean();
    return digest;
  }
}
