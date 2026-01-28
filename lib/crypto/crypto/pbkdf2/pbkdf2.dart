import 'package:blockchain_utils/crypto/crypto/hmac/hmac.dart';
import 'package:blockchain_utils/utils/binary/binary_operation.dart';

/// The `PBKDF2` class is an implementation of the Password-Based Key Derivation Function 2 (PBKDF2) algorithm.
///
class PBKDF2 {
  /// Derives a cryptographic key using the PBKDF2 algorithm with the provided parameters.
  ///
  /// This method takes several essential parameters to derive a secure key:
  ///
  /// Parameters:
  /// - [mac]: A function that returns an HMAC (Hash-based Message Authentication Code) instance. HMAC is used
  ///   as the pseudorandom function in the PBKDF2 algorithm.
  /// - [salt]: A unique random value (the salt) that adds randomness and security to the key derivation process.
  /// - [iterations]: The number of iterations or rounds of HMAC to apply, which increases the computational
  ///   expense and security.
  /// - [length]: The desired length of the derived cryptographic key in bytes.
  ///
  static List<int> deriveKey({
    required HMAC Function() mac,
    required List<int> salt,
    required int iterations,
    required int length,
  }) {
    final prf = mac();
    final dlen = prf.getDigestLength;
    final ctr = List<int>.filled(4, 0);
    final t = List<int>.filled(dlen, 0);
    final u = List<int>.filled(dlen, 0);
    final dk = List<int>.filled(length, 0);

    prf.update(salt);
    final saltedState = prf.saveState();

    for (var i = 0; i * dlen < length; i++) {
      BinaryOps.writeUint32BE(i + 1, ctr);
      prf.restoreState(saltedState)
        ..update(ctr)
        ..finish(u);
      for (int j = 0; j < dlen; j++) {
        t[j] = u[j];
      }
      for (int j = 2; j <= iterations; j++) {
        prf
          ..reset()
          ..update(u)
          ..finish(u);
        for (var k = 0; k < dlen; k++) {
          t[k] ^= u[k];
        }
      }

      for (int j = 0; j < dlen && i * dlen + j < length; j++) {
        dk[i * dlen + j] = t[j];
      }
    }
    BinaryOps.zero(t);
    BinaryOps.zero(u);
    BinaryOps.zero(ctr);
    prf.cleanSavedState(saltedState);
    prf.clean();
    return dk;
  }
}
