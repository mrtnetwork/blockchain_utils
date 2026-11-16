import 'package:blockchain_utils/api/api/api.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/protocol/zip32/orchard/utils.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/crypto/crypto/keys/reddsa/redpallas/keys/core.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';
import 'package:blockchain_utils/crypto/crypto/group/pasta/point/pallas.dart';
import 'package:blockchain_utils/exception/exceptions.dart';

/// A Zcash Orchard value-balance binding (RedPallas) private key.
class RedPallasBindingPrivateKey
    extends BaseRedPallasPrivateKey<RedPallasBindingPublicKey> {
  RedPallasBindingPrivateKey._({required super.sk, required super.publicKey});
  factory RedPallasBindingPrivateKey.fromBytes(List<int> bytes) {
    try {
      return RedPallasBindingPrivateKey.fromScalar(bytes);
    } on BuError {
      throw CoreErrors.invalidOperationArguments(
        "RedPallasBindingPrivateKey.fromBytes",
        reason: "Invalid secret key bytes.",
      );
    }
  }

  factory RedPallasBindingPrivateKey.fromScalar(List<int> scalar) {
    if (!blockchainUtils.api.pallas.scCheck(scalar)) {
      throw CoreErrors.invalidOperationArguments(
        "RedPallasBindingPrivateKey.fromScalar",
        reason: "Invalid secret key bytes.",
      );
    }
    final point = PallasPoint.fromBytes(
      blockchainUtils.api.pallas.mult(
        scalar,
        OrchardKeyUtils.orchardBindingSigBasepointBytes,
      ),
    );
    return RedPallasBindingPrivateKey._(
      sk: scalar,
      publicKey: RedPallasBindingPublicKey._(
        BuBytes.immutable(point.toBytes()),
      ),
    );
  }

  @override
  CryptoKeyType get type => CryptoKeyType.redPallasBinding;

  static bool isValidBytes(List<int> bytes) {
    try {
      RedPallasBindingPrivateKey.fromBytes(bytes);
      return true;
    } catch (_) {
      return false;
    }
  }

  RedPallasBindingPrivateKey randomize(List<int> randomizer) {
    final sum = blockchainUtils.api.pallas.scAdd(sk, randomizer);
    return RedPallasBindingPrivateKey.fromBytes(sum);
  }
}

/// A Zcash Orchard value-balance binding (RedPallas) public key.
class RedPallasBindingPublicKey extends BaseRedPallasPublicKey {
  RedPallasBindingPublicKey._(super.keyBytes);
  factory RedPallasBindingPublicKey.fromBytes(List<int> bytes) {
    final normalized = BaseRedPallasPublicKey.normalizePublicKey(bytes);
    if (normalized != null) {
      return RedPallasBindingPublicKey._(normalized);
    }
    // Binding keys may be the identity (zero value balance): accept the
    // canonical identity encoding from the backend, reject everything else.
    if (BytesUtils.bytesEqualConst(
      bytes,
      blockchainUtils.api.pallas.identity(),
    )) {
      return RedPallasBindingPublicKey._(BuBytes.immutable(bytes));
    }
    throw CoreErrors.invalidOperationArguments(
      "RedPallasBindingPublicKey",
      reason: "Invalid public key bytes.",
    );
  }

  @override
  CryptoKeyType get type => CryptoKeyType.redPallasBinding;

  static bool isValidBytes(List<int> bytes) {
    try {
      RedPallasBindingPublicKey.fromBytes(bytes);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Checks whether [keyBytes] has a valid length for the given [encoding].
  ///
  /// This check validates only the key length and does not verify whether
  /// [keyBytes] represents a valid public key.
  static bool isValidKeyEncoding(
    List<int> keyBytes,
    CryptoKeyEncoding encoding,
  ) {
    return switch (encoding) {
      CryptoKeyEncoding.base when keyBytes.length == 32 => true,
      _ => false,
    };
  }

  RedPallasBindingPublicKey randomize(List<int> randomizer) {
    final api = blockchainUtils.api.pallas;
    final rG = api.mult(
      randomizer,
      OrchardKeyUtils.orchardBindingSigBasepointBytes,
    );
    return RedPallasBindingPublicKey.fromBytes(api.add(keyBytes, rG));
  }
}
