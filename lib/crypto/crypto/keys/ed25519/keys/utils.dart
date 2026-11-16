import 'package:blockchain_utils/api/api/api.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/group/edwards_limb/points.dart';
import 'package:blockchain_utils/crypto/crypto/keys/ed25519/keys/core.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';

/// Ed25519 key derivation helpers (RFC 8032 clamping, etc).
class ED25519KeyUtils {
  /// RFC 8032 clamping: clears the low 3 bits of the first byte and sets
  /// bit 254 while clearing bit 255 of the last byte.
  ///
  static void keyPrune(List<int> key) {
    const hLog = 3;
    const l = 255;
    key[0] &= ~((1 << hLog) - 1);

    key[key.length - 1] =
        key[key.length - 1] & ((1 << (l % 8)) - 1) | (1 << ((l % 8) - 1));
  }

  /// Derives the public key point for a given secret key + curve variant.
  static EdwardsLimbPoint derivePublicKey({
    required List<int> secretKey,
    required CryptoKeyType type,
  }) {
    switch (type) {
      case CryptoKeyType.ed25519:
      case CryptoKeyType.ed25519Blake2b:
        if (secretKey.length != Ed25519KeysConst.privKeyByteLen) {
          throw CoreErrors.invalidOperationArguments(
            "ED25519KeyUtils.derivePublicKey",
            name: "secretKey",
            reason: "Invalid secret key bytes length.",
          );
        }
        final extendedKey = switch (type) {
          CryptoKeyType.ed25519Blake2b => QuickCrypto.blake2b512Hash(secretKey),
          _ => QuickCrypto.sha512Hash(secretKey),
        };
        final keyBytes = extendedKey.sublist(
          0,
          Ed25519KeysConst.privKeyByteLen,
        );
        keyPrune(keyBytes);
        return EdwardsLimbPoint.fromBytes(
          blockchainUtils.api.ed25519.reduceMultBase(keyBytes).toList(),
        );
      case CryptoKeyType.ed25519Kholaw:
      case CryptoKeyType.ed25519Monero:
        final List<int> privateKeyPart = secretKey.sublist(
          0,
          Ed25519KeysConst.privKeyByteLen,
        );
        return EdwardsLimbPoint.fromBytes(
          blockchainUtils.api.ed25519.reduceMultBase(privateKeyPart).toList(),
        );
      default:
        throw CoreErrors.invalidOperationArguments(
          "EDDSAPrivateKey",
          reason: "Unsupported secret key algorithm.",
        );
    }
  }
}
