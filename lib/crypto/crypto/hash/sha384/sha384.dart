part of 'package:blockchain_utils/crypto/crypto/hash/hash.dart';

/// The `SHA384` class extends the SHA-512 hash algorithm to produce 384-bit digests.
///
/// SHA-384 is a cryptographic hash function that produces a 384-bit (48-byte) hash
/// value from an input message. It's a part of the SHA-2 family of hash functions.
/// This class inherits from the `SHA512` class, and it sets the digest length and
/// block size accordingly.
class SHA384 extends SHA512 {
  static const int digestLength = 48;
  static const int blockSize = 128;

  /// digest length
  @override
  int get getDigestLength => SHA384.digestLength;

  /// block size
  @override
  int get getBlockSize => SHA384.blockSize;

  @override
  void _initState() {
    _stateHi[0] = 0xcbbb9d5d;
    _stateHi[1] = 0x629a292a;
    _stateHi[2] = 0x9159015a;
    _stateHi[3] = 0x152fecd8;
    _stateHi[4] = 0x67332667;
    _stateHi[5] = 0x8eb44a87;
    _stateHi[6] = 0xdb0c2e0d;
    _stateHi[7] = 0x47b5481d;

    _stateLo[0] = 0xc1059ed8;
    _stateLo[1] = 0x367cd507;
    _stateLo[2] = 0x3070dd17;
    _stateLo[3] = 0xf70e5939;
    _stateLo[4] = 0xffc00b31;
    _stateLo[5] = 0x68581511;
    _stateLo[6] = 0x64f98fa7;
    _stateLo[7] = 0xbefa4fa4;
  }

  /// Computes the SHA-384 hash of the provided data.
  static List<int> hash(List<int> data) {
    final h = SHA384();
    h.update(data);
    final digest = h.digest();
    h.clean();
    return digest;
  }
}
