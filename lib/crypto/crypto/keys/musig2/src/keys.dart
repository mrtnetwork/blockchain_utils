import 'package:blockchain_utils/api/api.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/utils/ecdsa.dart';
import 'package:blockchain_utils/crypto/crypto/protocol/musig2/constants/const.dart';
import 'package:blockchain_utils/crypto/crypto/protocol/musig2/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/group/weierstrass/weierstrass.dart';
import 'package:blockchain_utils/crypto/crypto/keys/constants/ecdsa.dart';
import 'package:blockchain_utils/crypto/crypto/keys/core/i_keys.dart';
import 'package:blockchain_utils/crypto/crypto/keys/musig2/src/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/secp256k1/src/secp256k1.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/encoding/layout/layout.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:blockchain_utils/utils/json/extension/json.dart';
import 'package:blockchain_utils/crypto/crypto/keys/musig2/src/verify_signing.dart';

class Musig2PrivateKey extends IMuSig2SigningKey<MuSig2AggregatePublicKey>
    with Equality
    implements
        IPrivateKey<
          MuSig2Signature,
          MuSig2GenerateSessionParams,
          MuSig2AggregatePublicKey
        > {
  @override
  final MuSig2AggregatePublicKey publicKey;
  @override
  final List<Secp256k1PrivateKey> secretKeys;
  Musig2PrivateKey._(List<Secp256k1PrivateKey> secretKeys, this.publicKey)
    : secretKeys = secretKeys.immutable;

  factory Musig2PrivateKey.generate(
    List<Secp256k1PrivateKey> secretKeys, {
    bool sortPubKeys = false,
  }) {
    final pk = MuSig2AggregatePublicKey.aggPublicKeys(
      secretKeys.map((e) => e.publicKey).toList(),
      sortPubKeys: sortPubKeys,
    );
    return Musig2PrivateKey._(secretKeys, pk);
  }

  factory Musig2PrivateKey.partial({
    required MuSig2AggregatePublicKey publicKey,
    List<Secp256k1PrivateKey> secretKeys = const [],
  }) {
    return Musig2PrivateKey._(secretKeys, publicKey);
  }

  factory Musig2PrivateKey.fromBytes(List<int> keysBytes) {
    return layout().deserialize(keysBytes).value;
  }

  @override
  CryptoKeyType get type => CryptoKeyType.muSig2;

  static bool isValidBytes(List<int> keysBytes) {
    try {
      Musig2PrivateKey.fromBytes(keysBytes);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Layout<Musig2PrivateKey> layout() => ObjSeqLayout<Musig2PrivateKey>(
    [
      MuSig2AggregatePublicKey.layout(),
      LayoutConst.vec(LayoutConst.fixedBlobN(EcdsaKeysConst.privKeyByteLen)),
    ],
    build: (values) {
      final MuSig2AggregatePublicKey pubkey = JsonParser.valueAs(
        values.elementAtOrNull(0),
      );
      final List<Secp256k1PrivateKey> secretKeys =
          JsonParser.valueEnsureAsList<List<int>>(
            values.elementAtOrNull(1),
          ).map((e) => Secp256k1PrivateKey.fromBytes(e)).toList();
      return Musig2PrivateKey.partial(
        publicKey: pubkey,
        secretKeys: secretKeys,
      );
    },
    unbuild:
        (value) => [
          value.publicKey,
          value.secretKeys.map((e) => e.takeSecretKey()).toList(),
        ],
  );

  @override
  SecretBytes takeSecretKey({SecretTransform? transform}) {
    return SecretBytes.take(layout().serialize(this), transform: transform);
  }

  @override
  SecretBytes toBytes({SecretTransform? transform}) {
    return takeSecretKey(transform: transform);
  }

  @override
  List<dynamic> get variables => [publicKey];

  Secp256k1Point tweakedPoint(List<MuSig2Tweak> tweaks) =>
      publicKey.tweakedPoint(tweaks);

  @override
  MuSig2AggregatePublicKey verificationKey() {
    return publicKey;
  }

  @override
  void dispose() {
    for (final i in secretKeys) {
      i.dispose();
    }
  }
}

/// A MuSig2 aggregate public key (the x-only key a verifier checks a
/// final aggregated signature against).
class MuSig2AggregatePublicKey extends IMuSig2VerificationKey
    with Equality
    implements IPublicKey<MuSig2PartialVerifiyingParams> {
  @override
  final List<Secp256k1PublicKey>? publicKeys;
  final Secp256k1Point point;
  MuSig2AggregatePublicKey._(this.point, List<Secp256k1PublicKey>? publicKeys)
    : publicKeys = publicKeys?.emptyAsNull?.immutable;
  factory MuSig2AggregatePublicKey.fromBytes(List<int> bytes) {
    return layout().deserialize(bytes).value;
  }
  factory MuSig2AggregatePublicKey.aggPublicKey(
    Secp256k1Point aggPublicPoint,
  ) {
    return MuSig2AggregatePublicKey._from(aggPublicPoint, null);
  }
  factory MuSig2AggregatePublicKey._from(
    Secp256k1Point aggPublicPoint,
    List<Secp256k1PublicKey>? keys,
  ) {
    if (keys != null && keys.length < MuSig2Constants.minimumRequiredKey) {
      throw CoreErrors.cryptoFailed(
        "MuSig2AggregatePublicKey",
        reason:
            "at least ${MuSig2Constants.minimumRequiredKey} public key required.",
      );
    }
    if (aggPublicPoint.isZero()) {
      throw CoreErrors.cryptoFailed(
        "MuSig2AggregatePublicKey",
        reason: "identity point.",
      );
    }
    return MuSig2AggregatePublicKey._(aggPublicPoint, keys);
  }

  factory MuSig2AggregatePublicKey.aggPublicKeys(
    List<Secp256k1PublicKey> keys, {
    bool sortPubKeys = false,
  }) {
    List<Secp256k1PublicKey> orderedKeys = keys;
    if (sortPubKeys) {
      orderedKeys = List<Secp256k1PublicKey>.from(keys)
        ..sort((a, b) => BytesUtils.compareBytes(a.toBytes(), b.toBytes()));
    }
    final agg = blockchainUtils.api.muSig2.aggPublicKeys(
      orderedKeys.map((e) => e.toBytes()).toList(),
    );
    return MuSig2AggregatePublicKey._from(
      agg,
      orderedKeys,
    ); // store the SAME order used to build `agg`
  }

  @override
  BuBytes toBytes({CryptoKeyEncoding mode = CryptoKeyEncoding.base}) {
    return CryptoKeysUtils.ensureSupportPubKeyMode(
      mode: mode,
      type: type,
      onModeBytes:
          (mode) => switch (mode) {
            CryptoKeyEncoding.base => layout().serialize(this),
            CryptoKeyEncoding.uncompressed => null,
          },
    );
  }

  /// 32-byte x-only aggregate key — this is the key a verifier checks the
  /// *final* signature against, the same way a single BIP-340 pubkey would.
  @override
  BuBytes xOnly() => point.toXOnly();

  @override
  Secp256k1Point tweakedPoint(List<MuSig2Tweak> tweaks) {
    if (tweaks.isEmpty) {
      return point;
    }
    final publicKeys = this.publicKeys;
    if (publicKeys == null) {
      throw CoreErrors.cryptoFailed(
        "MuSig2AggregatePublicKey.tweakedPoint",
        reason: "Missing public keys.",
      );
    }
    return blockchainUtils.api.muSig2.keyAggAndTweak(
      publicKeys: publicKeys.map((e) => e.toBytes()).toList(),
      tweaks: tweaks,
    );
  }

  @override
  CryptoKeyType get type => CryptoKeyType.muSig2;

  static bool isValidBytes(List<int> bytes) {
    try {
      MuSig2AggregatePublicKey.fromBytes(bytes);
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
    switch (encoding) {
      case CryptoKeyEncoding.base:
        final layout = LayoutConst.struct([
          LayoutConst.fixedBlobN(
            EcdsaKeysConst.pubKeyCompressedByteLen,
            property: "agg",
          ),
          LayoutConst.optional(
            LayoutConst.vec(
              LayoutConst.fixedBlobN(
                EcdsaKeysConst.pubKeyCompressedByteLen,
                property: "keys",
              ),
            ),
          ),
        ]);
        try {
          final decode = layout.deserialize(keyBytes);
          final keys = decode.value.valueAsList<List?>("keys");
          return decode.consumed == keyBytes.length &&
              (keys == null ||
                  keys.length >= MuSig2Constants.minimumRequiredKey);
        } catch (_) {
          return false;
        }

      case CryptoKeyEncoding.uncompressed:
        return false;
    }
  }

  @override
  List<dynamic> get variables => [point];

  static Layout<MuSig2AggregatePublicKey> layout() =>
      ObjSeqLayout<MuSig2AggregatePublicKey>(
        [
          LayoutConst.fixedBlobN(EcdsaKeysConst.pubKeyCompressedByteLen),
          LayoutConst.optional(
            LayoutConst.vec(
              LayoutConst.fixedBlobN(EcdsaKeysConst.pubKeyCompressedByteLen),
            ),
          ),
        ],
        build: (values) {
          final agg = Secp256k1Point.fromBytes(
            JsonParser.valueAsBytes(values.elementAtOrNull(0)),
          );
          final List<Secp256k1PublicKey>? pubKeys =
              JsonParser.valueAsList<List<List<int>>?>(
                values.elementAtOrNull(1),
              )?.map((e) => Secp256k1PublicKey.fromBytes(e)).toList();
          return MuSig2AggregatePublicKey._from(agg, pubKeys);
        },
        unbuild:
            (value) => [
              value.point.toBytes(),
              value.publicKeys?.map((e) => e.toBytes()).toList(),
            ],
      );
}
