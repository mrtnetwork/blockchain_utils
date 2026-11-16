import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/utils/binary/src/binary_operation.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// PBKDF2 (RFC 8018) key derivation, parameterized by an HMAC [mac].
class PBKDF2 {
  /// Derives a [length]-byte key from [mac] (a keyed HMAC constructor)
  /// using [salt] over [iterations] rounds.
  ///
  /// Throws [BuError] if [length] is negative or [iterations]
  /// is less than 1.
  static BuBytes deriveKey({
    required CbHashFunc mac,
    required List<int> salt,
    required int iterations,
    required int length,
  }) {
    if (length < 0) {
      throw CoreErrors.invalidOperationArguments(
        "deriveKey",
        name: "length",
        reason: "Invalid length. Must be non-negative.",
      );
    }
    if (iterations < 1) {
      throw CoreErrors.invalidOperationArguments(
        "deriveKey",
        name: "iterations",
        reason: "Invalid iterations. Must be at least 1.",
      );
    }
    final prf = mac();
    final dlen = prf.getDigestLength;
    final ctr = List<int>.filled(4, 0);
    final t = List<int>.filled(dlen, 0);
    final u = List<int>.filled(dlen, 0);
    final dk = BuBytes.fill(length, 0);

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
