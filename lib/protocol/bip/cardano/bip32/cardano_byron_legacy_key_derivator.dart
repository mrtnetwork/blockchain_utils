import 'package:blockchain_utils/api/api.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/bip32_keys.dart';
import 'package:blockchain_utils/protocol/bip/bip/bip32/khalow/bip32_kholaw_key_derivator_base.dart';
import 'package:blockchain_utils/crypto/crypto/group/edwards_limb/points.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/utils/binary/src/binary_operation.dart';

/// A class responsible for deriving key pairs using the Cardano Byron legacy key derivation process
class CardanoByronLegacyKeyDerivator
    extends Bip32KholawEd25519KeyDerivatorBase {
  /// Derives the left part of a new private key based on input bytes and curve type.
  @override
  BuBytes newPrivateKeyLeftPart(
    List<int> zlBytes,
    List<int> klBytes,
    CryptoKeyType type,
  ) {
    final List<int> multiPly = blockchainUtils.api.ed25519.scReduce(
      zlBytes.map((e) => (e * 8) & BinaryOps.mask8).toList(),
    );
    klBytes = blockchainUtils.api.ed25519.scReduce(klBytes);
    return blockchainUtils.api.ed25519.scAdd(multiPly, klBytes);
  }

  /// Derives the right part of a new private key based on input bytes.
  @override
  BuBytes newPrivateKeyRightPart(List<int> zrBytes, List<int> krBytes) {
    return BuBytes.unsafeMutable(
      List<int>.generate(
        zrBytes.length,
        (index) => (zrBytes[index] + krBytes[index]) & BinaryOps.mask8,
      ),
    );
  }

  /// Derives a new public key point based on the provided public key and input bytes.
  @override
  EdwardsLimbPoint newPublicKeyPoint(Bip32PublicKey pubKey, List<int> zlBytes) {
    if (!pubKey.type.isED25519()) {
      throw CoreErrors.cryptoFailed(
        "newPublicKeyPoint",
        reason: "Invalid public key type.",
      );
    }
    final multiply = blockchainUtils.api.ed25519.scReduce(
      zlBytes.map((e) => (e * 8) & BinaryOps.mask8).toList(),
    );
    final multBase = blockchainUtils.api.ed25519.multBase(multiply);
    final newPubKey = blockchainUtils.api.ed25519.add(
      pubKey.key.toBytes(),
      multBase,
    );
    return EdwardsLimbPoint.fromBytes(newPubKey);
  }

  /// Serializes a Bip32KeyIndex object to bytes.
  @override
  BuBytes serializeIndex(Bip32KeyIndex index) {
    return index.toBytes();
  }
}
