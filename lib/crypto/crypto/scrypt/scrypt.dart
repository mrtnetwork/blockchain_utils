import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:blockchain_utils/crypto/crypto/hmac/hmac.dart';
import 'package:blockchain_utils/crypto/crypto/pbkdf2/pbkdf2.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/exception/exception.dart';

/// A class for performing scrypt key derivation.
///
/// Scrypt is a key derivation function designed to be secure against both hardware and software attacks.
/// It is commonly used for securely deriving encryption keys from user-provided passwords.
///
/// Fields:
/// - `_xy`: A list of 32-bit unsigned integers representing intermediate data during scrypt key derivation.
/// - `_v`: A list of 32-bit unsigned integers representing additional intermediate data during scrypt key derivation.
/// - `n`: An integer representing the CPU/memory cost parameter. It defines the general work factor for scrypt.
/// - `r`: An integer representing the block size parameter, which specifies the number of iterations and memory size used.
/// - `p`: An integer representing the parallelization parameter, which controls the amount of parallel processing.
class Scrypt {
  late final List<int> _xy;
  late final List<int> _v;

  late final int n;
  late final int r;
  late final int p;

  /// Creates a new `Scrypt` instance for key derivation.
  ///
  /// The `Scrypt` constructor initializes the parameters for scrypt key derivation, which includes the CPU/memory cost parameter (`n`), block size parameter (`r`), and parallelization parameter (`p`).
  ///
  /// Parameters:
  /// - `n`: The CPU/memory cost parameter. It defines the general work factor for scrypt.
  /// - `r`: The block size parameter. It specifies the number of iterations and memory size used.
  /// - `p`: The parallelization parameter. It controls the amount of parallel processing.
  ///
  /// Throws an [ArgumentException] if the parameters are out of the valid range or not a power of 2.
  Scrypt(this.n, this.r, this.p) {
    if (p <= 0) {
      throw const ArgumentException("scrypt: incorrect p");
    }

    if (r <= 0) {
      throw const ArgumentException("scrypt: incorrect r");
    }

    if (n < 1 || n > 1 << 31) {
      throw const ArgumentException('scrypt: N must be between 2 and 2^31');
    }

    if (!_isPowerOfTwo(n)) {
      throw const ArgumentException("scrypt: N must be a power of 2");
    }

    const maxInt = (1 << 31) & mask32;

    if (r * p >= 1 << 30 ||
        r > maxInt ~/ 128 ~/ p ||
        r > maxInt ~/ 256 ||
        n > maxInt ~/ 128 ~/ r) {
      throw const ArgumentException("scrypt: parameters are too large");
    }

    _v = List<int>.filled(32 * (n + 2) * r, 0);
    _xy = List<int>.filled(_v.length - (32 * n * r), 0);
  }
  static List<int> deriveKey(
    List<int> password,
    List<int> salt, {
    int dkLen = 32,
    int r = 8,
    int n = 8192,
    int p = 1,
  }) {
    final s = Scrypt(n, r, p);
    return s.derive(password, salt, dkLen);
  }

  /// Derives a key from the given `password` and `salt` using scrypt key derivation.
  ///
  /// This method takes a `password`, a `salt`,
  /// and the desired derived key length (`dkLen`) as input and computes the derived key using the
  /// scrypt key derivation function. The derived key is returned as a [List<int>].
  ///
  /// Parameters:
  /// - `password`: The password to use as input for key derivation.
  /// - `salt`: A random salt value used to enhance security.
  /// - `dkLen`: The desired length (in bytes) of the derived key.
  ///
  /// Returns:
  /// A derived key as a [List<int>].
  List<int> derive(List<int> password, List<int> salt, int dkLen) {
    final B = PBKDF2.deriveKey(
        mac: () => HMAC(() => SHA256(), password),
        salt: salt,
        iterations: 1,
        length: p * 128 * r);

    for (int i = 0; i < p; i++) {
      final index = i * 128 * r;
      final copy = B.sublist(index);
      _smix(copy, r, n, _v, _xy);
      B.setAll(index, copy);
    }

    final result = PBKDF2.deriveKey(
        mac: () => HMAC(() => SHA256(), password),
        salt: B,
        iterations: 1,
        length: dkLen);
    zero(B);

    return result;
  }

  static bool _isPowerOfTwo(int x) {
    return (x & (x - 1)) == 0;
  }

  static void _blockCopy(
      List<int> dst, int di, List<int> src, int si, int len) {
    while (len-- > 0) {
      dst[di++] = src[si++] & mask32;
    }
  }

  static void _blockXOR(List<int> dst, int di, List<int> src, int si, int len) {
    while (len-- > 0) {
      dst[di++] ^= src[si++] & mask32;
    }
  }

  static void _blockMix(List<int> tmp, List<int> B, int bin, int bout, int r) {
    _blockCopy(tmp, 0, B, bin + (2 * r - 1) * 16, 16);
    for (int i = 0; i < 2 * r; i += 2) {
      _salsaXOR(tmp, B, bin + i * 16, bout + i * 8);
      _salsaXOR(tmp, B, bin + i * 16 + 16, bout + i * 8 + r * 16);
    }
  }

  static int _integerify(List<int> b, int bi, int r) {
    return b[bi + (2 * r - 1) * 16];
  }

  static int _or(int sum, int n) =>
      ((sum << n) & mask32) | (sum & mask32) >> (32 - n);

  static void _salsaXOR(List<int> tmp, List<int> B, int bin, int bout) {
    int j0 = tmp[0] ^ B[bin++],
        j1 = tmp[1] ^ B[bin++],
        j2 = tmp[2] ^ B[bin++],
        j3 = tmp[3] ^ B[bin++],
        j4 = tmp[4] ^ B[bin++],
        j5 = tmp[5] ^ B[bin++],
        j6 = tmp[6] ^ B[bin++],
        j7 = tmp[7] ^ B[bin++],
        j8 = tmp[8] ^ B[bin++],
        j9 = tmp[9] ^ B[bin++],
        j10 = tmp[10] ^ B[bin++],
        j11 = tmp[11] ^ B[bin++],
        j12 = tmp[12] ^ B[bin++],
        j13 = tmp[13] ^ B[bin++],
        j14 = tmp[14] ^ B[bin++],
        j15 = tmp[15] ^ B[bin++];
    int x0 = j0,
        x1 = j1,
        x2 = j2,
        x3 = j3,
        x4 = j4,
        x5 = j5,
        x6 = j6,
        x7 = j7,
        x8 = j8,
        x9 = j9,
        x10 = j10,
        x11 = j11,
        x12 = j12,
        x13 = j13,
        x14 = j14,
        x15 = j15;
    int u;
    for (var i = 0; i < 8; i += 2) {
      u = x0 + x12;
      x4 ^= _or(u, 7);
      u = x4 + x0;
      x8 ^= _or(u, 9);
      u = x8 + x4;
      x12 ^= _or(u, 13);
      u = x12 + x8;
      x0 ^= _or(u, 18);
      u = x5 + x1;
      x9 ^= _or(u, 7);
      u = x9 + x5;
      x13 ^= _or(u, 9);
      u = x13 + x9;
      x1 ^= _or(u, 13);
      u = x1 + x13;
      x5 ^= _or(u, 18);
      u = x10 + x6;
      x14 ^= _or(u, 7);
      u = x14 + x10;
      x2 ^= _or(u, 9);
      u = x2 + x14;
      x6 ^= _or(u, 13);
      u = x6 + x2;
      x10 ^= _or(u, 18);
      u = x15 + x11;
      x3 ^= _or(u, 7);
      u = x3 + x15;
      x7 ^= _or(u, 9);
      u = x7 + x3;
      x11 ^= _or(u, 13);
      u = x11 + x7;
      x15 ^= _or(u, 18);
      u = x0 + x3;
      x1 ^= _or(u, 7);
      u = x1 + x0;
      x2 ^= _or(u, 9);
      u = x2 + x1;
      x3 ^= _or(u, 13);
      u = x3 + x2;
      x0 ^= _or(u, 18);
      u = x5 + x4;
      x6 ^= _or(u, 7);
      u = x6 + x5;
      x7 ^= _or(u, 9);
      u = x7 + x6;
      x4 ^= _or(u, 13);
      u = x4 + x7;
      x5 ^= _or(u, 18);
      u = x10 + x9;
      x11 ^= _or(u, 7);
      u = x11 + x10;
      x8 ^= _or(u, 9);
      u = x8 + x11;
      x9 ^= _or(u, 13);
      u = x9 + x8;
      x10 ^= _or(u, 18);
      u = x15 + x14;
      x12 ^= _or(u, 7);
      u = x12 + x15;
      x13 ^= _or(u, 9);
      u = x13 + x12;
      x14 ^= _or(u, 13);
      u = x14 + x13;
      x15 ^= _or(u, 18);
    }
    B[bout++] = tmp[0] = (x0 + j0) & mask32;
    B[bout++] = tmp[1] = (x1 + j1) & mask32;
    B[bout++] = tmp[2] = (x2 + j2) & mask32;
    B[bout++] = tmp[3] = (x3 + j3) & mask32;
    B[bout++] = tmp[4] = (x4 + j4) & mask32;
    B[bout++] = tmp[5] = (x5 + j5) & mask32;
    B[bout++] = tmp[6] = (x6 + j6) & mask32;
    B[bout++] = tmp[7] = (x7 + j7) & mask32;
    B[bout++] = tmp[8] = (x8 + j8) & mask32;
    B[bout++] = tmp[9] = (x9 + j9) & mask32;
    B[bout++] = tmp[10] = (x10 + j10) & mask32;
    B[bout++] = tmp[11] = (x11 + j11) & mask32;
    B[bout++] = tmp[12] = (x12 + j12) & mask32;
    B[bout++] = tmp[13] = (x13 + j13) & mask32;
    B[bout++] = tmp[14] = (x14 + j14) & mask32;
    B[bout++] = tmp[15] = (x15 + j15) & mask32;
  }

  static void _smix(List<int> B, int r, int N, List<int> V, List<int> xy) {
    var xi = 0;
    var yi = 32 * r;
    var tmp = List<int>.filled(16, 0);

    for (var i = 0; i < 32 * r; i++) {
      V[i] = readUint32LE(B, i * 4);
    }

    for (var i = 0; i < N; i++) {
      _blockMix(tmp, V, i * (32 * r), (i + 1) * (32 * r), r);
    }
    xy.setRange(0, xy.length, V.sublist(32 * N * r));

    for (int i = 0; i < N; i += 2) {
      int j = _integerify(xy, xi, r) & (N - 1);
      _blockXOR(xy, xi, V, j * (32 * r), 32 * r);
      _blockMix(tmp, xy, xi, yi, r);
      j = _integerify(xy, yi, r) & (N - 1);
      _blockXOR(xy, yi, V, j * (32 * r), 32 * r);
      _blockMix(tmp, xy, yi, xi, r);
    }
    for (int i = 0; i < 32 * r; i++) {
      writeUint32LE(xy[xi + i], B, i * 4);
    }

    zero(tmp);
  }
}
