part of 'package:blockchain_utils/crypto/crypto/hash/hash.dart';

/// The `SHA224` class represents the SHA-224 hash algorithm, which is a variant of SHA-256.
///
class SHA224 extends SHA256 {
  /// digest length
  @override
  int get getDigestLength => 28;

  /// block size
  @override
  int get getBlockSize => 64;

  @override
  void _initState() {
    _state[0] = 0xc1059ed8;
    _state[1] = 0x367cd507;
    _state[2] = 0x3070dd17;
    _state[3] = 0xf70e5939;
    _state[4] = 0xffc00b31;
    _state[5] = 0x68581511;
    _state[6] = 0x64f98fa7;
    _state[7] = 0xbefa4fa4;
  }

  /// Computes the SHA224 hash of the provided data.
  static List<int> hash(List<int> data) {
    final h = SHA224();
    h.update(data);
    final digest = h.digest();
    h.clean();
    return digest;
  }
}
