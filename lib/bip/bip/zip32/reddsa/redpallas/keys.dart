import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/bip/ecc/keys/ed25519_keys.dart';
import 'package:blockchain_utils/bip/ecc/keys/i_keys.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/fields/vesta_fq.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/point/pallas.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/point/pallas_native.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';

class RedPallasPrivateKey
    with ConstantEquality<RedPallasPrivateKey>
    implements IPrivateKey {
  final List<int> sk;
  @override
  final RedPallasPublicKey publicKey;
  RedPallasPrivateKey({required List<int> sk, required this.publicKey})
    : sk =
          sk
              .exc(
                length: 32,
                operation: "RedPallasPrivateKey",
                reason: "Invalid redpallas private key bytes length.",
              )
              .asImmutableBytes;
  factory RedPallasPrivateKey.fromBytes(
    List<int> bytes,
    PallasPoint generator,
  ) {
    final point = VestaFq.fromBytes(bytes);
    final mul = generator * point;
    final pointBytes = mul.toBytes();
    return RedPallasPrivateKey(
      sk: bytes,
      publicKey: RedPallasPublicKey(
        publicKey: pointBytes,
        point: PallasNativePoint.fromBytes(pointBytes),
      ),
    );
  }
  VestaFq toScalar() => VestaFq.fromBytes(sk);

  @override
  List<List<int>> get secretFields => [sk];

  @override
  List<Object?> get publicFields => [publicKey];

  @override
  EllipticCurveTypes get curve => EllipticCurveTypes.redPallas;

  @override
  int get length => Ed25519KeysConst.privKeyByteLen;

  @override
  List<int> get raw => sk.clone();

  @override
  String toHex({bool lowerCase = true, String? prefix = ""}) {
    return BytesUtils.toHexString(sk, prefix: prefix, lowerCase: lowerCase);
  }

  @override
  List<dynamic> get variables => [];
}

class RedPallasPublicKey with Equality implements IPublicKey {
  final List<int> publicKey;
  @override
  final PallasNativePoint point;
  RedPallasPublicKey({required List<int> publicKey, required this.point})
    : publicKey =
          publicKey
              .exc(
                length: 32,
                operation: "RedPallasPublicKey",
                reason: "Invalid redpallas public key bytes length.",
              )
              .asImmutableBytes;
  factory RedPallasPublicKey.fromBytes(List<int> bytes) {
    final point = PallasNativePoint.fromBytes(bytes);
    if (point.isIdentity()) {
      throw ArgumentException.invalidOperationArguments(
        "RedJubJubPublicKey",
        reason: "Identity point.",
      );
    }
    return RedPallasPublicKey(publicKey: bytes, point: point);
  }
  factory RedPallasPublicKey.fromPoint(PallasNativePoint point) {
    if (point.isIdentity()) {
      throw ArgumentException.invalidOperationArguments(
        "RedJubJubPublicKey",
        reason: "Identity point.",
      );
    }
    return RedPallasPublicKey(publicKey: point.toBytes(), point: point);
  }

  @override
  List<dynamic> get variables => [point];

  @override
  List<int> get compressed => publicKey.clone();

  @override
  EllipticCurveTypes get curve => EllipticCurveTypes.redPallas;

  @override
  int get length => Ed25519KeysConst.pubKeyByteLen;

  @override
  String toHex({
    bool withPrefix = true,
    bool lowerCase = true,
    String? prefix = "",
  }) {
    return BytesUtils.toHexString(
      publicKey,
      lowerCase: lowerCase,
      prefix: prefix,
    );
  }

  @override
  List<int> get uncompressed => publicKey.clone();

  @override
  int get uncompressedLength => Ed25519KeysConst.pubKeyByteLen;
}
