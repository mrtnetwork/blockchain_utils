import 'package:blockchain_utils/api/api/api.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/protocol/zip32/zip32.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/crypto/crypto/keys/reddsa/redjubjub/keys/core.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';
import 'package:blockchain_utils/crypto/crypto/group/jubjub/jubjub.dart';
import 'package:blockchain_utils/exception/exceptions.dart';

/// A Zcash Sapling value-balance binding (RedJubjub) private key.
class RedJubJubBindingPrivateKey
    extends BaseRedJubJubPrivateKey<RedJubJubBindingPublicKey> {
  RedJubJubBindingPrivateKey._({required super.sk, required super.publicKey});
  factory RedJubJubBindingPrivateKey.fromBytes(List<int> bytes) {
    try {
      return RedJubJubBindingPrivateKey.fromScalar(bytes);
    } on BuError {
      throw CoreErrors.invalidOperationArguments(
        "RedJubJubBindingPrivateKey.fromBytes",
        reason: "Invalid secret key bytes.",
      );
    }
  }
  factory RedJubJubBindingPrivateKey.fromScalar(List<int> scalar) {
    if (!blockchainUtils.api.jubjub.scCheck(scalar)) {
      throw CoreErrors.invalidOperationArguments(
        "RedJubJubBindingPrivateKey.fromScalar",
        reason: "Invalid secret key bytes.",
      );
    }
    final point = JubJubPoint.fromBytes(
      blockchainUtils.api.jubjub.mult(
        scalar,
        SaplingKeyUtils.bindingGeneratorBytes,
      ),
    );
    return RedJubJubBindingPrivateKey._(
      sk: scalar,
      publicKey: RedJubJubBindingPublicKey._(
        BuBytes.immutable(point.toBytes()),
      ),
    );
  }

  @override
  CryptoKeyType get type => CryptoKeyType.redJubJubBinding;

  static bool isValidBytes(List<int> bytes) {
    try {
      RedJubJubBindingPrivateKey.fromBytes(bytes);
      return true;
    } catch (_) {
      return false;
    }
  }

  RedJubJubBindingPrivateKey randomize(List<int> randomizer) {
    final sum = blockchainUtils.api.jubjub.scAdd(sk, randomizer);
    return RedJubJubBindingPrivateKey.fromBytes(sum);
  }
}

/// A Zcash Sapling value-balance binding (RedJubjub) public key.
class RedJubJubBindingPublicKey extends BaseRedJubJubPublicKey {
  RedJubJubBindingPublicKey._(super.keyBytes);
  factory RedJubJubBindingPublicKey.fromBytes(List<int> bytes) {
    final normalized = BaseRedJubJubPublicKey.normalizePublicKey(bytes);
    if (normalized != null) {
      return RedJubJubBindingPublicKey._(normalized);
    }
    // Binding keys may be the identity (zero value balance): accept the
    // canonical identity encoding from the backend, reject everything else.
    if (BytesUtils.bytesEqualConst(
      bytes,
      blockchainUtils.api.jubjub.identity(),
    )) {
      return RedJubJubBindingPublicKey._(BuBytes.immutable(bytes));
    }
    throw CoreErrors.invalidOperationArguments(
      "RedJubJubBindingPublicKey",
      reason: "Invalid public key bytes.",
    );
  }

  @override
  CryptoKeyType get type => CryptoKeyType.redJubJubBinding;

  static bool isValidBytes(List<int> bytes) {
    try {
      RedJubJubBindingPublicKey.fromBytes(bytes);
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

  RedJubJubBindingPublicKey randomize(List<int> randomizer) {
    final api = blockchainUtils.api.jubjub;
    final rG = api.mult(randomizer, SaplingKeyUtils.bindingGeneratorBytes);
    return RedJubJubBindingPublicKey.fromBytes(api.add(keyBytes, rG));
  }
}
