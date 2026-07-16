import 'package:blockchain_utils/blockchain_utils.dart';

abstract class SaplingVerifyingKey<V extends SaplingVerifyingKey<V>>
    extends VerificationKey<JubJubNativeFr, JubJubNativePoint, V> {
  const SaplingVerifyingKey();

  @override
  bool verifySignature(
    ReddsaSignature signature,
    List<int> message, {
    bool hashMessage = true,
  }) {
    if (hashMessage) {
      message = QuickCrypto.blake2b512Hash(
        signature.rBytes,
        personalization: "Zcash_RedJubjubH".codeUnits,
        extraBlocks: [toBytes(), message],
      );
    }
    try {
      final c = JubJubNativeFr.fromBytes64(message);
      final r = JubJubNativePoint.fromBytes(signature.rBytes);
      final s = JubJubNativeFr.fromBytes(signature.sBytes);
      final sb = generator() * s;
      final ca = toPoint() * c;
      final n = (sb - ca - r);
      return n.isSmallOrder();
    } catch (_) {}
    return false;
  }
}

abstract class SaplingSigningKey<
  V extends SaplingVerifyingKey<V>,
  K extends SaplingSigningKey<V, K>
>
    extends
        ReddsaSigningKey<
          JubJubFr,
          JubJubPoint,
          JubJubNativeFr,
          JubJubNativePoint,
          V,
          K
        > {
  const SaplingSigningKey();
  List<int> signBytes(List<int> message) {
    final pkBytes = toVerificationKey().toBytes();
    final randBytes = QuickCrypto.generateRandom(80);
    final nonceBytes = QuickCrypto.blake2b512Hash(
      randBytes,
      personalization: "Zcash_RedJubjubH".codeUnits,
      extraBlocks: [pkBytes, message],
    );
    // PallasPoint
    final nonce = JubJubFr.fromBytes64(nonceBytes);
    final r = generator() * nonce;
    final rBytes = r.toBytes();
    final cBytes = QuickCrypto.blake2b512Hash(
      rBytes,
      personalization: "Zcash_RedJubjubH".codeUnits,
      extraBlocks: [pkBytes, message],
    );
    final c = JubJubFr.fromBytes64(cBytes);
    final sk = JubJubFr.fromBytes(toBytes());
    final s = nonce + (c * sk);
    final sBytes = s.toBytes();
    return [...rBytes, ...sBytes];
  }
}

class SaplingSpendAuthorizingKey
    extends
        SaplingSigningKey<
          SaplingSpendVerificationKey,
          SaplingSpendAuthorizingKey
        > {
  final JubJubFr inner;
  SaplingSpendVerificationKey? _vk;
  SaplingSpendAuthorizingKey._(this.inner);
  factory SaplingSpendAuthorizingKey(JubJubFr sk) {
    if (sk.isZero()) {
      throw ArgumentException.invalidOperationArguments(
        "SaplingSpendAuthorizingKey",
        reason: "Invalid spend authorizing key.",
      );
    }
    return SaplingSpendAuthorizingKey._(sk);
  }

  factory SaplingSpendAuthorizingKey.fromBytes(List<int> sk) {
    return SaplingSpendAuthorizingKey(JubJubFr.fromBytes(sk));
  }

  factory SaplingSpendAuthorizingKey.fromSpendingKey(List<int> sk) {
    return SaplingSpendAuthorizingKey(
      JubJubFr.fromBytes64(PrfExpand.saplingAsk.apply(sk)),
    );
  }

  @override
  SaplingSpendVerificationKey toVerificationKey() {
    return _vk ??= () {
      final mul = generator() * inner;
      return SaplingSpendVerificationKey(
        JubJubNativePoint.fromBytes(mul.toBytes()),
      );
    }();
  }

  @override
  JubJubPoint generator() {
    return SaplingKeyUtils.spendAuthGenerator;
  }

  @override
  ReddsaSignature sign(List<int> message) {
    return ReddsaSignature.fromBytes(signBytes(message));
  }

  @override
  List<int> toBytes() {
    return inner.toBytes();
  }

  @override
  SaplingSpendAuthorizingKey randomize(JubJubFr randomizer) {
    return SaplingSpendAuthorizingKey(inner + randomizer);
  }

  @override
  List<dynamic> get variables => [inner];
}

class SaplingBindingAuthorizingKey
    extends
        SaplingSigningKey<
          SaplingBindingVerificationKey,
          SaplingBindingAuthorizingKey
        > {
  final JubJubFr inner;
  SaplingBindingVerificationKey? _vk;
  SaplingBindingAuthorizingKey(this.inner);

  factory SaplingBindingAuthorizingKey.fromBytes(List<int> sk) {
    final fr = JubJubFr.fromBytes(sk);
    return SaplingBindingAuthorizingKey(fr);
  }

  @override
  SaplingBindingVerificationKey toVerificationKey() {
    return _vk ??= () {
      final mul = generator() * inner;
      return SaplingBindingVerificationKey(
        JubJubNativePoint.fromBytes(mul.toBytes()),
      );
    }();
  }

  @override
  JubJubPoint generator() {
    return SaplingKeyUtils.bindingGenerator;
  }

  @override
  ReddsaSignature sign(List<int> message) {
    return ReddsaSignature.fromBytes(signBytes(message));
  }

  @override
  List<int> toBytes() {
    return inner.toBytes();
  }

  @override
  SaplingBindingAuthorizingKey randomize(JubJubFr randomizer) {
    return SaplingBindingAuthorizingKey(inner + randomizer);
  }

  @override
  List<dynamic> get variables => [inner];
}

class SaplingSpendVerificationKey
    extends SaplingVerifyingKey<SaplingSpendVerificationKey>
    with LayoutSerializable {
  final JubJubNativePoint point;
  const SaplingSpendVerificationKey._(this.point);
  factory SaplingSpendVerificationKey(JubJubNativePoint point) {
    if (point.isIdentity()) {
      throw ArgumentException.invalidOperationArguments(
        "SaplingSpendVerificationKey",
        reason: "Identity point.",
      );
    }
    return SaplingSpendVerificationKey._(point);
  }
  factory SaplingSpendVerificationKey.fromBytes(List<int> pk) {
    return SaplingSpendVerificationKey(RedJubJubPublicKey.fromBytes(pk).point);
  }
  factory SaplingSpendVerificationKey.deserializeJson(
    Map<String, dynamic> json,
  ) {
    return SaplingSpendVerificationKey.fromBytes(
      json.valueAsBytes("public_key"),
    );
  }

  factory SaplingSpendVerificationKey.fromAutorizationKey(List<int> sk) {
    final generator = SaplingKeyUtils.spendAuthGenerator;
    return SaplingSpendVerificationKey(
      RedJubJubPrivateKey.fromBytes(sk, generator).publicKey.point,
    );
  }

  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      LayoutConst.fixedBlob32(property: "public_key"),
    ], property: property);
  }

  @override
  Map<String, dynamic> toSerializeJson() {
    return {"public_key": point.toBytes()};
  }

  @override
  Layout<Map<String, dynamic>> toLayout({String? property}) {
    return layout(property: property);
  }

  @override
  List<int> toBytes() => point.toBytes();

  @override
  JubJubNativePoint generator() {
    return SaplingKeyUtils.spendAuthGeneratorNative.toExtended();
  }

  @override
  JubJubNativePoint toPoint() {
    return point;
  }

  @override
  List<dynamic> get variables => [point];

  @override
  SaplingSpendVerificationKey randomize(JubJubNativeFr randomizer) {
    final point = toPoint() + (generator() * randomizer);
    return SaplingSpendVerificationKey.fromBytes(point.toBytes());
  }
}

class SaplingBindingVerificationKey
    extends SaplingVerifyingKey<SaplingBindingVerificationKey> {
  final JubJubNativePoint point;
  const SaplingBindingVerificationKey(this.point);

  factory SaplingBindingVerificationKey.fromBytes(List<int> pk) {
    return SaplingBindingVerificationKey(
      RedJubJubPublicKey.fromBytes(pk).point,
    );
  }
  factory SaplingBindingVerificationKey.fromAutorizationKey(List<int> sk) {
    final generator = SaplingKeyUtils.bindingGenerator;
    return SaplingBindingVerificationKey(
      RedJubJubPrivateKey.fromBytes(sk, generator).publicKey.point,
    );
  }

  @override
  List<int> toBytes() {
    return point.toBytes();
  }

  @override
  JubJubNativePoint generator() {
    return SaplingKeyUtils.bindingGeneratorNative.toExtended();
  }

  @override
  JubJubNativePoint toPoint() {
    return point;
  }

  @override
  List<dynamic> get variables => [point];

  @override
  SaplingBindingVerificationKey randomize(JubJubNativeFr randomizer) {
    final point = toPoint() + (generator() * randomizer);
    return SaplingBindingVerificationKey.fromBytes(point.toBytes());
  }
}
