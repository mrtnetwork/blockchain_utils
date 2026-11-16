import 'package:blockchain_utils/api/api/api.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/core/i_keys.dart';
import 'package:blockchain_utils/crypto/crypto/keys/reddsa/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/utils/ecdsa.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/crypto/crypto/group/jubjub/jubjub.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:blockchain_utils/crypto/crypto/keys/reddsa/redjubjub/keys/verify_signing.dart';

/// Base class for a RedJubjub (Zcash Sapling) private key.
abstract class BaseRedJubJubPrivateKey<P extends BaseRedJubJubPublicKey>
    extends IRedJubJubSigningKey<P>
    with Equality
    implements IPrivateKey<ReddsaSignature, RedJubJubSigningParams, P> {
  final SecretBytes sk;
  @override
  final P publicKey;
  BaseRedJubJubPrivateKey({required List<int> sk, required this.publicKey})
    : sk = SecretBytes(sk);

  void _ensureAlive(String operation) {
    if (sk.isZeroed) {
      throw CoreErrors.badState(
        operation,
        reason: "Private key has been disposed.",
      );
    }
  }

  @override
  void dispose() {
    sk.zero();
  }


  @override
  List<dynamic> get variables => [publicKey];

  @override
  JubJubFr scalar() {
    _ensureAlive("BaseRedJubJubPrivateKey.scalar");
    return JubJubFr.fromBytes(sk);
  }

  @override
  P verificationKey() {
    return publicKey;
  }

  @override
  SecretBytes toBytes({SecretTransform? transform}) {
    _ensureAlive("BaseRedJubJubPrivateKey.toBytes");
    return sk.cloneBytes(transform: transform);
  }

  @override
  SecretBytes takeSecretKey() {
    _ensureAlive("BaseRedJubJubPrivateKey.takeSecretKey");
    return sk;
  }
}

/// Base class for a RedJubjub (Zcash Sapling) public key.
///
/// The key is stored as immutable canonical base-encoding bytes; the live
/// point is parsed once on first use (compute paths), while carry, compare
/// and serialize paths use [keyBytes] directly with no conversions.
abstract class BaseRedJubJubPublicKey extends IRedJubJubVerificationKey
    with Equality
    implements IPublicKey<RedJubJubVerifyingParams> {
  @override
  final BuBytes keyBytes;
  BaseRedJubJubPublicKey(this.keyBytes);

  // Live point, parsed on demand from [keyBytes].
  // NOTE: every access re-parses (full validation); compute-heavy
  // call sites will be converted to bytes-APIs next phase.
  // JubJubPoint get point => JubJubPoint.fromBytes(keyBytes);

  @override
  List<dynamic> get variables => [keyBytes];

  /// Validates [bytes] through the backend signing API and returns its
  /// canonical 32-byte base encoding, or null when invalid (bad length,
  /// range, curve membership, or identity). Single source of truth for key
  /// parsing.
  static BuBytes? normalizePublicKey(List<int> bytes) {
    return blockchainUtils.api.signing.jubjub.normalizePublicKey(bytes);
  }

  @override
  BuBytes toBytes({CryptoKeyEncoding mode = CryptoKeyEncoding.base}) {
    if (mode == CryptoKeyEncoding.base) return keyBytes;
    return CryptoKeysUtils.ensureSupportPubKeyMode(
      mode: mode,
      type: type,
      onModeBytes:
          (mode) => switch (mode) {
            CryptoKeyEncoding.base => keyBytes,
            CryptoKeyEncoding.uncompressed => null,
          },
    );
  }
}
