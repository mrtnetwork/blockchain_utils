import 'package:blockchain_utils/api/api/api.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/core/i_keys.dart';
import 'package:blockchain_utils/crypto/crypto/keys/reddsa/redpallas/keys/verify_signing.dart';
import 'package:blockchain_utils/crypto/crypto/keys/reddsa/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/utils/ecdsa.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/crypto/crypto/group/pasta/fields/vesta_fq.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';

/// Base class for a RedPallas (Zcash Orchard) private key.
abstract class BaseRedPallasPrivateKey<P extends BaseRedPallasPublicKey>
    extends IRedPallasSigningKey<P>
    with Equality
    implements IPrivateKey<ReddsaSignature, RedPallasSigningParams, P> {
  final SecretBytes sk;
  @override
  final P publicKey;
  BaseRedPallasPrivateKey({required List<int> sk, required this.publicKey})
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
  List<dynamic> get variables => [publicKey];

  @override
  VestaFq scalar() {
    _ensureAlive("BaseRedPallasPrivateKey.scalar");
    return VestaFq.fromBytes(sk);
  }

  @override
  P verificationKey() {
    return publicKey;
  }

  @override
  SecretBytes toBytes({SecretTransform? transform}) {
    _ensureAlive("BaseRedPallasPrivateKey.toBytes");
    return sk.cloneBytes(transform: transform);
  }

  @override
  void dispose() {
    sk.zero();
  }

  @override
  SecretBytes takeSecretKey() {
    _ensureAlive("BaseRedPallasPrivateKey.takeSecretKey");
    return sk;
  }
}

/// Base class for a RedPallas (Zcash Orchard) public key.
///
/// The key is stored as immutable canonical base-encoding bytes; the live
/// point is parsed once on first use (compute paths), while carry, compare
/// and serialize paths use [keyBytes] directly with no conversions.
abstract class BaseRedPallasPublicKey extends IRedPallasVerificationKey
    with Equality
    implements IPublicKey<RedPallasVerifyingParams> {
  final BuBytes keyBytes;
  BaseRedPallasPublicKey(this.keyBytes);

  @override
  List<dynamic> get variables => [keyBytes];

  /// Validates [bytes] through the backend signing API and returns its
  /// canonical 32-byte base encoding, or null when invalid (bad length,
  /// range, curve membership, or identity). Single source of truth for key
  /// parsing.
  static BuBytes? normalizePublicKey(List<int> bytes) {
    return blockchainUtils.api.signing.pallas.normalizePublicKey(bytes);
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
