import 'package:blockchain_utils/api/api.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/bls12_381/aggregate_minimal_pubkey_size/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/bls12_381/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/core/i_keys.dart';
import 'package:blockchain_utils/crypto/crypto/keys/bls12_381/aggregate_minimal_pubkey_size/verify_signing.dart';
import 'package:blockchain_utils/crypto/crypto/keys/bls12_381/minimal_pubkey_size/keys.dart';
import 'package:blockchain_utils/crypto/crypto/keys/utils/ecdsa.dart';
import 'package:blockchain_utils/encoding/layout/layout.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/json/extension/json.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';

/// An aggregate of multiple min-pubkey-size BLS public keys.
class Bls12G1AggregatePublicKey extends IBlsAggregateVerificationKey
    with Equality
    implements IPublicKey<Bls12G1AggregateVerifiyingParams> {
  @override
  final List<Bls12G1PublicKey>? publicKeys;
  @override
  final Bls12G1PublicKey aggregateKey;
  Bls12G1AggregatePublicKey._(this.aggregateKey, this.publicKeys);

  factory Bls12G1AggregatePublicKey.fromBytes(List<int> keyBytes) {
    return layout().deserialize(keyBytes).value;
  }
  factory Bls12G1AggregatePublicKey._from(
    Bls12G1PublicKey aggPublicPoint,
    List<Bls12G1PublicKey>? keys,
  ) {
    if (keys != null && keys.isEmpty) {
      throw CoreErrors.cryptoFailed(
        "Bls12G1AggregatePublicKey",
        reason: "at least one public key required.",
      );
    }
    return Bls12G1AggregatePublicKey._(aggPublicPoint, keys);
  }

  factory Bls12G1AggregatePublicKey.fromPubKeys(List<Bls12G1PublicKey> keys) {
    final agg = blockchainUtils.api.signing.bls.aggregatePublicKeysG1(
      keys.map((e) => e.keyBytes).toList(),
    );
    final aggregateKey = Bls12G1PublicKey.fromBytes(agg);
    return Bls12G1AggregatePublicKey._(aggregateKey, keys);
  }

  @override
  CryptoKeyType get type => CryptoKeyType.bls12G1Aggregate;

  static bool isValidBytes(List<int> keyBytes) {
    try {
      Bls12G1AggregatePublicKey.fromBytes(keyBytes);
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
            Bls12KeyConst.compressedPubKeyLength,
            property: "agg",
          ),
          LayoutConst.optional(
            LayoutConst.vec(
              LayoutConst.fixedBlobN(
                Bls12KeyConst.compressedPubKeyLength,
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
  List<dynamic> get variables => [aggregateKey];

  // G1Projective get point => aggregateKey.point;

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

  static Layout<Bls12G1AggregatePublicKey> layout() =>
      ObjSeqLayout<Bls12G1AggregatePublicKey>(
        [
          LayoutConst.fixedBlobN(Bls12KeyConst.compressedPubKeyLength),
          LayoutConst.optional(
            LayoutConst.vec(
              LayoutConst.fixedBlobN(Bls12KeyConst.compressedPubKeyLength),
            ),
          ),
        ],
        build: (values) {
          final agg = Bls12G1PublicKey.fromBytes(
            JsonParser.valueAsBytes(values.elementAtOrNull(0)),
          );
          final List<Bls12G1PublicKey>? pubKeys =
              JsonParser.valueAsList<List<List<int>>?>(
                values.elementAtOrNull(1),
              )?.map((e) => Bls12G1PublicKey.fromBytes(e)).toList();
          return Bls12G1AggregatePublicKey._from(agg, pubKeys);
        },
        unbuild:
            (value) => [
              value.aggregateKey.toBytes(),
              value.publicKeys?.map((e) => e.toBytes()).toList(),
            ],
      );
}

/// A collection of min-pubkey-size BLS private keys used to co-sign
/// (aggregate-sign) as a group.
class Bls12G1AggregatePrivateKey
    extends IBlsAggregateSigningKey<Bls12G1AggregatePublicKey>
    with Equality
    implements
        IPrivateKey<
          Bls12G1BatchSignature,
          Bls12AggregateSigningParams,
          Bls12G1AggregatePublicKey
        > {
  @override
  final List<Bls12G1PrivateKey> secretKeys;
  @override
  final Bls12G1AggregatePublicKey publicKey;
  Bls12G1AggregatePrivateKey._(
    List<Bls12G1PrivateKey> secretKeys,
    this.publicKey,
  ) : secretKeys = secretKeys.min(
        length: 1,
        operation: "Bls12G1AggregatePrivateKey",
      );
  factory Bls12G1AggregatePrivateKey.fromSecretKeys(
    List<Bls12G1PrivateKey> keys,
  ) {
    if (keys.isEmpty) {
      throw CoreErrors.invalidOperationArguments(
        "Bls12G1AggregatePrivateKey",
        name: "keys",
        reason: "Cannot aggregate an empty secret key list",
      );
    }
    return Bls12G1AggregatePrivateKey._(
      keys,
      Bls12G1AggregatePublicKey.fromPubKeys(
        keys.map((e) => e.publicKey).toList(),
      ),
    );
  }
  factory Bls12G1AggregatePrivateKey.fromBytes(List<int> keysBytes) {
    final decoded = layout().deserialize(keysBytes);
    if (decoded.consumed != keysBytes.length) {
      throw CoreErrors.invalidOperationArguments(
        "Bls12G1AggregatePrivateKey",
        name: "keysBytes",
        reason: "Invalid encoded key bytes length",
      );
    }
    return decoded.value;
  }

  @override
  CryptoKeyType get type => CryptoKeyType.bls12G1Aggregate;

  static bool isValidBytes(List<int> keysBytes) {
    try {
      Bls12G1AggregatePrivateKey.fromBytes(keysBytes);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  List<dynamic> get variables => [secretKeys];

  @override
  Bls12G1AggregatePublicKey verificationKey() => publicKey;

  @override
  SecretBytes toBytes({SecretTransform? transform}) {
    return SecretBytes.take(layout().serialize(this), transform: transform);
  }

  /// u32 LE count followed by that many 32-byte scalars — the same wire
  /// shape the hand-rolled codec below produced, expressed as a layout.
  static Layout<Bls12G1AggregatePrivateKey> layout() {
    final length = LayoutConst.padding(
      LayoutConst.u32(property: 'length'),
      property: 'length',
    );
    return ObjSeqLayout<Bls12G1AggregatePrivateKey>(
      [
        length,
        SequenceLayout(
          elementLayout: LayoutConst.fixedBlobN(Bls12KeyConst.privKeyByteLen),
          count: LayoutConst.offset(length, -length.span),
          property: 'keys',
        ),
      ],
      build: (values) {
        final keys =
            (values[1] as List)
                .map((e) => Bls12G1PrivateKey.fromBytes(e as List<int>))
                .toList();
        return Bls12G1AggregatePrivateKey._(
          keys,
          Bls12G1AggregatePublicKey.fromPubKeys(
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
      "Bls12G1AggregatePrivateKey.takeSecretKey",
      reason: "Feature not supported.",
    );
  }
}
