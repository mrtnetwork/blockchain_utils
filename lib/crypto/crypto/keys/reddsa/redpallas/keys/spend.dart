import 'package:blockchain_utils/api/api/api.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/protocol/zip32/orchard/keys.dart';
import 'package:blockchain_utils/protocol/zip32/orchard/utils.dart';
import 'package:blockchain_utils/protocol/zip32/utils/prf_expand.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/reddsa/redpallas/keys/core.dart';
import 'package:blockchain_utils/crypto/crypto/group/pasta/point/pallas.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';
import 'package:blockchain_utils/encoding/layout/layout.dart';
import 'package:blockchain_utils/utils/json/extension/json.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// A Zcash Orchard spend-authorizing (RedPallas) private key.
class RedPallasSpendPrivateKey
    extends BaseRedPallasPrivateKey<RedPallasSpendPublicKey> {
  RedPallasSpendPrivateKey._({required super.sk, required super.publicKey});
  factory RedPallasSpendPrivateKey.fromBytes(List<int> bytes) {
    try {
      return RedPallasSpendPrivateKey.fromScalar(bytes);
    } on BuError {
      throw CoreErrors.invalidOperationArguments(
        "RedPallasSpendPrivateKey.fromBytes",
        reason: "Invalid secret key bytes.",
      );
    }
  }
  factory RedPallasSpendPrivateKey.fromScalar(List<int> scalar) {
    if (!blockchainUtils.api.pallas.scCheck(scalar) ||
        BytesUtils.isZeroConst(scalar)) {
      throw CoreErrors.invalidOperationArguments(
        "RedPallasSpendPrivateKey.fromScalar",
        reason: "Invalid secret key bytes.",
      );
    }
    final point = PallasPoint.fromBytes(
      blockchainUtils.api.pallas.mult(
        scalar,
        OrchardKeyUtils.orchardSpendAuthSigBasepointBytes,
      ),
    );
    return RedPallasSpendPrivateKey._(
      sk: scalar,
      publicKey: RedPallasSpendPublicKey.fromBytes(point.toBytes()),
    );
  }

  factory RedPallasSpendPrivateKey.fromSpendingKey(OrchardSpendingKey sk) {
    final api = blockchainUtils.api.pallas;
    final scalar = api.scReduce64(PrfExpand.orchardAsk.apply(sk.sk));
    final ask = RedPallasSpendPrivateKey.fromScalar(scalar);
    final pk = ask.publicKey.toBytes();
    if ((pk[31] >> 7) == 1) {
      return RedPallasSpendPrivateKey.fromScalar(api.scNeg(scalar));
    }
    return ask;
  }

  RedPallasSpendPrivateKey randomize(List<int> randomizer) {
    final sum = blockchainUtils.api.pallas.scAdd(sk, randomizer);
    return RedPallasSpendPrivateKey.fromBytes(sum);
  }

  @override
  CryptoKeyType get type => CryptoKeyType.redPallasSpend;

  static bool isValidBytes(List<int> bytes) {
    try {
      RedPallasSpendPrivateKey.fromBytes(bytes);
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// A Zcash Orchard spend-authorizing (RedPallas) public key.
class RedPallasSpendPublicKey extends BaseRedPallasPublicKey
    with LayoutSerializable {
  RedPallasSpendPublicKey._(super.keyBytes);
  factory RedPallasSpendPublicKey.fromBytes(List<int> bytes) {
    final normalized = BaseRedPallasPublicKey.normalizePublicKey(bytes);
    if (normalized == null) {
      throw CoreErrors.invalidOperationArguments(
        "RedPallasSpendPublicKey",
        reason: "Invalid public key bytes.",
      );
    }
    return RedPallasSpendPublicKey._(normalized);
  }

  factory RedPallasSpendPublicKey.deserializeJson(Map<String, dynamic> json) {
    return RedPallasSpendPublicKey.fromBytes(json.valueAsBytes("public_key"));
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
  CryptoKeyType get type => CryptoKeyType.redPallasSpend;

  static bool isValidBytes(List<int> bytes) {
    try {
      RedPallasSpendPublicKey.fromBytes(bytes);
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

  RedPallasSpendPublicKey randomize(List<int> randomizer) {
    final api = blockchainUtils.api.pallas;
    final rG = api.mult(
      randomizer,
      OrchardKeyUtils.orchardSpendAuthSigBasepointBytes,
    );
    return RedPallasSpendPublicKey.fromBytes(api.add(keyBytes, rG));
  }

  @override
  Layout<Map<String, dynamic>> toLayout({String? property}) {
    return layout(property: property);
  }
}
