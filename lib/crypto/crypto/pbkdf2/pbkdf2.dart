import 'package:blockchain_utils/crypto/crypto/hmac/hmac.dart';
import 'package:blockchain_utils/utils/utils.dart';

/// The `PBKDF2` class is an implementation of the Password-Based Key Derivation Function 2 (PBKDF2) algorithm.
///
/// PBKDF2 is a widely-used cryptographic key derivation function that is used to securely derive a cryptographic key
/// from a given password or passphrase. It adds computational expense to make brute-force attacks more difficult
/// by repeatedly applying a pseudorandom function (such as HMAC) to the password along with a salt.
///
/// This class provides methods for generating cryptographic keys based on a user-provided password, salt,
/// and the desired number of iterations, producing a derived key that can be used for encryption or other security purposes
class PBKDF2 {
  /// Derives a cryptographic key using the PBKDF2 algorithm with the provided parameters.
  ///
  /// This method takes several essential parameters to derive a secure key:
  ///
  /// Parameters:
  /// - `mac`: A function that returns an HMAC (Hash-based Message Authentication Code) instance. HMAC is used
  ///   as the pseudorandom function in the PBKDF2 algorithm.
  /// - `salt`: A unique random value (the salt) that adds randomness and security to the key derivation process.
  /// - `iterations`: The number of iterations or rounds of HMAC to apply, which increases the computational
  ///   expense and security.
  /// - `length`: The desired length of the derived cryptographic key in bytes.
  ///
  /// Returns:
  /// A `List<int>` containing the derived cryptographic key based on the provided parameters.
  ///
  /// This method applies the PBKDF2 algorithm to derive a secure key suitable for encryption and other security purposes.
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
      writeUint32BE(i + 1, ctr);
      prf.restoreState(saltedState)
        ..update(ctr)
        ..finish(u);
      for (var j = 0; j < dlen; j++) {
        t[j] = u[j];
      }
      for (var j = 2; j <= iterations; j++) {
        prf
          ..reset()
          ..update(u)
          ..finish(u);
        for (var k = 0; k < dlen; k++) {
          t[k] ^= u[k];
        }
      }

      for (var j = 0; j < dlen && i * dlen + j < length; j++) {
        dk[i * dlen + j] = t[j];
      }
    }
    zero(t);
    zero(u);
    zero(ctr);
    prf.cleanSavedState(saltedState);
    prf.clean();
    return dk;
  }
}
