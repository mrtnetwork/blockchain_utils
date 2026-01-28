import 'package:blockchain_utils/blockchain_utils.dart';

class RedJubJubPrivateKey
    with ConstantEquality<RedJubJubPrivateKey>
    implements IPrivateKey {
  final List<int> sk;
  @override
  final RedJubJubPublicKey publicKey;
  RedJubJubPrivateKey({required List<int> sk, required this.publicKey})
    : sk =
          sk
              .exc(
                length: 32,
                operation: "RedJubJubPrivateKey",
                reason: "Invalid redjubjub pivate key bytes length.",
              )
              .asImmutableBytes;
  factory RedJubJubPrivateKey.fromBytes(
    List<int> bytes,
    JubJubPoint generator,
  ) {
    final point = JubJubFr.fromBytes(bytes);
    final mul = generator * point;
    final pkBytes = mul.toBytes();
    return RedJubJubPrivateKey(
      sk: bytes,
      publicKey: RedJubJubPublicKey(
        publicKey: pkBytes,
        point: JubJubNativePoint.fromBytes(pkBytes),
      ),
    );
  }

  JubJubFr toScalar() => JubJubFr.fromBytes(sk);

  @override
  List<List<int>> get secretFields => [sk];

  @override
  List<Object?> get publicFields => [publicKey];

  @override
  EllipticCurveTypes get curve => EllipticCurveTypes.redJubJub;

  @override
  int get length => Ed25519KeysConst.privKeyByteLen;

  @override
  List<int> get raw => sk.clone();

  @override
  String toHex({bool lowerCase = true, String? prefix = ""}) {
    return BytesUtils.toHexString(sk, lowerCase: lowerCase, prefix: prefix);
  }

  @override
  List<dynamic> get variables => [];
}

class RedJubJubPublicKey with Equality implements IPublicKey {
  final List<int> publicKey;
  @override
  final JubJubNativePoint point;
  RedJubJubPublicKey({required List<int> publicKey, required this.point})
    : publicKey =
          publicKey
              .exc(
                length: 32,
                operation: "RedJubJubPublicKey",
                reason: "Invalid redjubjub public key bytes length.",
              )
              .asImmutableBytes;
  factory RedJubJubPublicKey.fromBytes(List<int> bytes) {
    final point = JubJubNativePoint.fromBytes(bytes);
    // if (point.isIdentity()) {
    //   throw ArgumentException.invalidOperationArguments(
    //     "RedJubJubPublicKey",
    //     reason: "Identity point.",
    //   );
    // }

    return RedJubJubPublicKey(publicKey: bytes, point: point);
  }

  factory RedJubJubPublicKey.fromPint(JubJubNativePoint point) {
    if (point.isIdentity()) {
      throw ArgumentException.invalidOperationArguments(
        "RedJubJubPublicKey",
        reason: "Identity point.",
      );
    }
    return RedJubJubPublicKey(publicKey: point.toBytes(), point: point);
  }

  @override
  List<dynamic> get variables => [point];

  @override
  List<int> get compressed => publicKey.clone();

  @override
  EllipticCurveTypes get curve => EllipticCurveTypes.redJubJub;

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
