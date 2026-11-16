import 'package:blockchain_utils/api/api.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/bls12_381/aggregate_minimal_signature_size/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/bls12_381/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/core/i_keys.dart';
import 'package:blockchain_utils/crypto/crypto/keys/bls12_381/aggregate_minimal_signature_size/verify_signing.dart';
import 'package:blockchain_utils/crypto/crypto/keys/bls12_381/minimal_signature_size/keys.dart';
import 'package:blockchain_utils/crypto/crypto/keys/utils/ecdsa.dart';
import 'package:blockchain_utils/encoding/layout/layout.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:blockchain_utils/utils/json/json.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// An aggregate of multiple min-signature-size BLS public keys.
class Bls12G2AggregatePublicKey extends IBlsAggregateMinSigVerificationKey
    with Equality
    implements IPublicKey<Bls12G2AggregateVerifiyingParams> {
  @override
  final List<Bls12G2PublicKey>? publicKeys;
  @override
  final Bls12G2PublicKey aggregateKey;
  Bls12G2AggregatePublicKey._(this.aggregateKey, this.publicKeys);

  factory Bls12G2AggregatePublicKey.fromBytes(List<int> keyBytes) {
    return layout().deserialize(keyBytes).value;
  }

  factory Bls12G2AggregatePublicKey._from(
    Bls12G2PublicKey aggPublicPoint,
    List<Bls12G2PublicKey>? keys,
  ) {
    if (keys != null && keys.isEmpty) {
      throw CoreErrors.cryptoFailed(
        "Bls12G2AggregatePublicKey",
        reason: "at least one public key required.",
      );
    }
    return Bls12G2AggregatePublicKey._(aggPublicPoint, keys);
  }
  factory Bls12G2AggregatePublicKey.fromPubKeys(List<Bls12G2PublicKey> keys) {
    final agg = blockchainUtils.api.signing.bls.aggregatePublicKeysG2(
      keys.map((e) => e.keyBytes).toList(),
    );
    final aggregateKey = Bls12G2PublicKey.fromBytes(agg);
    return Bls12G2AggregatePublicKey._(aggregateKey, keys);
  }

  @override
  CryptoKeyType get type => CryptoKeyType.bls12G2Aggregate;

  static bool isValidBytes(List<int> keyBytes) {
    try {
      Bls12G2AggregatePublicKey.fromBytes(keyBytes);
      return true;
    } catch (_) {}
    return false;
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
            Bls12G2KeyConst.compressedPubKeyLength,
            property: "agg",
          ),
          LayoutConst.optional(
            LayoutConst.vec(
              LayoutConst.fixedBlobN(
                Bls12G2KeyConst.compressedPubKeyLength,
                property: "keys",
              ),
            ),
          ),
        ]);
        try {
          final decode = layout.deserialize(keyBytes);
          final keys = decode.value.valueAsList<List?>("keys");
          return decode.consumed == keyBytes.length &&
              (keys == null || keys.isNotEmpty);
        } catch (_) {
          return false;
        }

      case CryptoKeyEncoding.uncompressed:
        return false;
    }
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

  @override
  List<dynamic> get variables => [aggregateKey];

  // G2Projective get point => aggregateKey.point;

  static Layout<Bls12G2AggregatePublicKey> layout() =>
      ObjSeqLayout<Bls12G2AggregatePublicKey>(
        [
          LayoutConst.fixedBlobN(Bls12G2KeyConst.compressedPubKeyLength),
          LayoutConst.optional(
            LayoutConst.vec(
              LayoutConst.fixedBlobN(Bls12G2KeyConst.compressedPubKeyLength),
            ),
          ),
        ],
        build: (values) {
          final agg = Bls12G2PublicKey.fromBytes(
            JsonParser.valueAsBytes(values.elementAtOrNull(0)),
          );
          final List<Bls12G2PublicKey>? pubKeys =
              JsonParser.valueAsList<List<List<int>>?>(
                values.elementAtOrNull(1),
              )?.map((e) => Bls12G2PublicKey.fromBytes(e)).toList();
          return Bls12G2AggregatePublicKey._from(agg, pubKeys);
        },
        unbuild:
            (value) => [
              value.aggregateKey.toBytes(),
              value.publicKeys?.map((e) => e.toBytes()).toList(),
            ],
      );
}

/// A collection of min-signature-size BLS private keys used to co-sign
/// (aggregate-sign) as a group.
class Bls12G2AggregatePrivateKey
    extends IBlsAggregateMinSigSigningKey<Bls12G2AggregatePublicKey>
    with Equality
    implements
        IPrivateKey<
          Bls12G2BatchSignature,
          Bls12AggregateSigningParams,
          Bls12G2AggregatePublicKey
        > {
  @override
  final List<Bls12G2PrivateKey> secretKeys;
  @override
  final Bls12G2AggregatePublicKey publicKey;
  Bls12G2AggregatePrivateKey._(
    List<Bls12G2PrivateKey> secretKeys,
    this.publicKey,
  ) : secretKeys = secretKeys.min(
        length: 1,
        operation: "Bls12G2AggregatePrivateKey",
      );
  factory Bls12G2AggregatePrivateKey.fromSecretKeys(
    List<Bls12G2PrivateKey> keys,
  ) {
    if (keys.isEmpty) {
      throw CoreErrors.invalidOperationArguments(
        "Bls12G2AggregatePrivateKey",
        name: "keys",
        reason: "Cannot aggregate an empty secret key list",
      );
    }
    return Bls12G2AggregatePrivateKey._(
      keys,
      Bls12G2AggregatePublicKey.fromPubKeys(
        keys.map((e) => e.publicKey).toList(),
      ),
    );
  }
  factory Bls12G2AggregatePrivateKey.fromBytes(List<int> keysBytes) {
    final decoded = layout().deserialize(keysBytes);
    if (decoded.consumed != keysBytes.length) {
      throw CoreErrors.invalidOperationArguments(
        "Bls12G2AggregatePrivateKey",
        name: "keysBytes",
        reason: "Invalid encoded key bytes length",
      );
    }
    return decoded.value;
  }

  @override
  CryptoKeyType get type => CryptoKeyType.bls12G2Aggregate;

  static bool isValidBytes(List<int> keysBytes) {
    try {
      Bls12G2AggregatePrivateKey.fromBytes(keysBytes);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  List<dynamic> get variables => [secretKeys];

  @override
  Bls12G2AggregatePublicKey verificationKey() => publicKey;

  @override
  SecretBytes toBytes({SecretTransform? transform}) {
    return SecretBytes.take(layout().serialize(this), transform: transform);
  }

  /// u32 LE count followed by that many 32-byte scalars — the same wire
  /// shape the hand-rolled codec below produced, expressed as a layout.
  static Layout<Bls12G2AggregatePrivateKey> layout() {
    final length = LayoutConst.padding(
      LayoutConst.u32(property: 'length'),
      property: 'length',
    );
    return ObjSeqLayout<Bls12G2AggregatePrivateKey>(
      [
        length,
        SequenceLayout(
          elementLayout: LayoutConst.fixedBlobN(Bls12G2KeyConst.privKeyByteLen),
          count: LayoutConst.offset(length, -length.span),
          property: 'keys',
        ),
      ],
      build: (values) {
        final keys =
            (values[1] as List)
                .map((e) => Bls12G2PrivateKey.fromBytes(e as List<int>))
                .toList();
        return Bls12G2AggregatePrivateKey._(
          keys,
          Bls12G2AggregatePublicKey.fromPubKeys(
            keys.map((e) => e.publicKey).toList(),
          ),
        );
      },
      unbuild:
          (value) => [
            value.secretKeys.length,
            value.secretKeys.map((e) => e.toBytes()).toList(),
          ],
    );
  }

  @override
  void dispose() {
    for (final i in secretKeys) {
      i.dispose();
    }
  }

  @override
  SecretBytes takeSecretKey() {
    throw CoreErrors.cryptoFailed(
      "Bls12G2AggregatePrivateKey.takeSecretKey",
      reason: "Feature not supported.",
    );
  }
}
