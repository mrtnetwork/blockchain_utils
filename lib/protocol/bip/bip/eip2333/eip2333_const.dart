/// Constants for EIP-2333 BLS12-381 key generation.
class Eip2333Const {
  /// Order `r` of the BLS12-381 scalar field (private key subgroup).
  static final BigInt orderR = BigInt.parse(
    '52435875175126190479447740508185965837690552500527637822603658699938581184513',
  );

  /// `L` for `HKDF_mod_r`: `ceil((3 * ceil(log2(r))) / 16)` = 48.
  static const int hkdfModROutputLen = 48;

  /// Digest size `K` of SHA-256 in octets.
  static const int sha256DigestLen = 32;

  /// Lamport secret count (255 × 32 bytes, HKDF stretch limit).
  static const int lamportCount = 255;

  /// `L = K * 255` output size for `IKM_to_lamport_SK` (8160 octets).
  static const int lamportHkdfLen = sha256DigestLen * lamportCount;

  /// ASCII salt for `HKDF_mod_r`: `"BLS-SIG-KEYGEN-SALT-"` (20 octets).
  static const String blsKeygenSalt = 'BLS-SIG-KEYGEN-SALT-';

  /// Minimum seed length in bytes (>= 256 bits).
  static const int seedMinByteLen = 32;

  /// Private key length in bytes (IETF big-endian scalar).
  static const int privKeyByteLen = 32;

  /// Max child index: `2^32 - 1` (all indices valid, no hardened concept).
  static const int maxIndex = 4294967295;
}
