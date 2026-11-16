import 'package:blockchain_utils/api/api/api.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/protocol/zip32/sapling/utils.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/reddsa/redjubjub/keys/core.dart';
import 'package:blockchain_utils/crypto/crypto/group/jubjub/jubjub.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';
import 'package:blockchain_utils/encoding/layout/layout.dart';
import 'package:blockchain_utils/utils/json/extension/json.dart';
import 'package:blockchain_utils/protocol/zip32/utils/prf_expand.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// A Zcash Sapling spend-authorizing (RedJubjub) private key.
class RedJubJubSpendPrivateKey
    extends BaseRedJubJubPrivateKey<RedJubJubSpendPublicKey> {
  RedJubJubSpendPrivateKey._({required super.sk, required super.publicKey});
  factory RedJubJubSpendPrivateKey.fromBytes(List<int> bytes) {
    try {
      return RedJubJubSpendPrivateKey.fromScalar(bytes);
    } on BuError {
      throw CoreErrors.invalidOperationArguments(
        "RedJubJubSpendPrivateKey.fromBytes",
        reason: "Invalid secret key bytes.",
      );
    }
  }
  factory RedJubJubSpendPrivateKey.fromScalar(List<int> scalar) {
    if (!blockchainUtils.api.jubjub.scCheck(scalar) ||
        BytesUtils.isZeroConst(scalar)) {
      throw CoreErrors.invalidOperationArguments(
        "RedJubJubSpendPrivateKey.fromScalar",
        reason: "Invalid secret key bytes.",
      );
    }
    final point = JubJubPoint.fromBytes(
      blockchainUtils.api.jubjub.mult(
        scalar,
        SaplingKeyUtils.spendAuthGeneratorBytes,
      ),
    );
    return RedJubJubSpendPrivateKey._(
      sk: scalar,
      publicKey: RedJubJubSpendPublicKey.fromBytes(point.toBytes()),
    );
  }

  factory RedJubJubSpendPrivateKey.fromSpendingKey(List<int> sk) {
    final ask = PrfExpand.saplingAsk.apply(sk);
    final scalar = blockchainUtils.api.jubjub.scReduce64(ask);
    return RedJubJubSpendPrivateKey.fromScalar(scalar);
  }

  RedJubJubSpendPrivateKey randomize(List<int> randomizer) {
    final sum = blockchainUtils.api.jubjub.scAdd(sk, randomizer);
    return RedJubJubSpendPrivateKey.fromBytes(sum);
  }

  @override
  CryptoKeyType get type => CryptoKeyType.redJubJubSpend;

  static bool isValidBytes(List<int> bytes) {
    try {
      RedJubJubSpendPrivateKey.fromBytes(bytes);
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// A Zcash Sapling spend-authorizing (RedJubjub) public key.
class RedJubJubSpendPublicKey extends BaseRedJubJubPublicKey
    with LayoutSerializable {
  RedJubJubSpendPublicKey._(super.keyBytes);
  factory RedJubJubSpendPublicKey.fromBytes(List<int> bytes) {
    final normalized = BaseRedJubJubPublicKey.normalizePublicKey(bytes);
    if (normalized == null) {
      throw CoreErrors.invalidOperationArguments(
        "RedJubJubSpendPublicKey",
        reason: "Invalid public key bytes.",
      );
    }
    return RedJubJubSpendPublicKey._(normalized);
  }

  factory RedJubJubSpendPublicKey.deserializeJson(Map<String, dynamic> json) {
    return RedJubJubSpendPublicKey.fromBytes(json.valueAsBytes("public_key"));
  }

  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      LayoutConst.fixedBlob32(property: "public_key"),
    ], property: property);
  }

  @override
  Map<String, dynamic> toSerializeJson() {
    return {"public_key": keyBytes};
  }

  @override
  CryptoKeyType get type => CryptoKeyType.redJubJubSpend;

  static bool isValidBytes(List<int> bytes) {
    try {
      RedJubJubSpendPublicKey.fromBytes(bytes);
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

  @override
  Layout<Map<String, dynamic>> toLayout({String? property}) {
    return layout(property: property);
  }

  RedJubJubSpendPublicKey randomize(List<int> randomizer) {
    final api = blockchainUtils.api.jubjub;
    final rG = api.mult(randomizer, SaplingKeyUtils.spendAuthGeneratorBytes);
    return RedJubJubSpendPublicKey.fromBytes(api.add(keyBytes, rG));
  }
}
