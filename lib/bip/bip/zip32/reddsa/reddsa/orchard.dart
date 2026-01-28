import 'package:blockchain_utils/blockchain_utils.dart';

abstract class OrchardVerifyingKey<V extends OrchardVerifyingKey<V>>
    extends VerificationKey<VestaNativeFq, PallasNativePoint, V> {
  const OrchardVerifyingKey();

  @override
  bool verifySignature(
    ReddsaSignature signature,
    List<int> message, {
    bool hashMessage = true,
  }) {
    if (hashMessage) {
      message = QuickCrypto.blake2b512Hash(
        signature.rBytes,
        personalization: "Zcash_RedPallasH".codeUnits,
        extraBlocks: [toBytes(), message],
      );
    }
    try {
      final c = VestaNativeFq.fromBytes64(message);
      final r = PallasNativePoint.fromBytes(signature.rBytes);
      final s = VestaNativeFq.fromBytes(signature.sBytes);
      final sb = generator() * s;
      final ca = toPoint() * c;
      final n = sb - ca - r;
      return n.isSmallOrder();
    } catch (_) {}
    return false;
  }
}

abstract class OrchardSigningKey<
  V extends OrchardVerifyingKey<V>,
  K extends OrchardSigningKey<V, K>
>
    extends
        ReddsaSigningKey<
          VestaFq,
          PallasPoint,
          VestaNativeFq,
          PallasNativePoint,
          V,
          K
        > {
  const OrchardSigningKey();
  List<int> signBytes(List<int> message) {
    final pkBytes = toVerificationKey().toBytes();
    final randBytes = QuickCrypto.generateRandom(80);
    final nonceBytes = QuickCrypto.blake2b512Hash(
      randBytes,
      personalization: "Zcash_RedPallasH".codeUnits,
      extraBlocks: [pkBytes, message],
    );
    // PallasPoint
    final nonce = VestaFq.fromBytes64(nonceBytes);
    final r = generator() * nonce;
    final rBytes = r.toBytes();
    final cBytes = QuickCrypto.blake2b512Hash(
      rBytes,
      personalization: "Zcash_RedPallasH".codeUnits,
      extraBlocks: [pkBytes, message],
    );
    final c = VestaFq.fromBytes64(cBytes);
    final sk = VestaFq.fromBytes(toBytes());
    final s = nonce + (c * sk);
    final sBytes = s.toBytes();
    return [...rBytes, ...sBytes];
  }
}

class OrchardSpendAuthorizingKey
    extends
        OrchardSigningKey<
          OrchardSpendVerificationKey,
          OrchardSpendAuthorizingKey
        > {
  final VestaFq inner;
  OrchardSpendVerificationKey? _vk;
  OrchardSpendAuthorizingKey._(this.inner);
  factory OrchardSpendAuthorizingKey(VestaFq sk) {
    if (sk.isZero()) {
      throw ArgumentException.invalidOperationArguments(
        "OrchardSpendAuthorizingKey",
        reason: "Invalid spend authorizing key.",
      );
    }
    return OrchardSpendAuthorizingKey._(sk);
  }
  factory OrchardSpendAuthorizingKey.fromSpendingKey(OrchardSpendingKey sk) {
    final f = VestaFq.fromBytes64(PrfExpand.orchardAsk.apply(sk.sk));
    final ask = OrchardSpendAuthorizingKey(f);
    final pk = ask.toVerificationKey();
    if ((pk.toBytes()[31] >> 7).toU8 == 1) {
      return OrchardSpendAuthorizingKey(-ask.inner);
    }
    return ask.._vk = pk;
  }

  factory OrchardSpendAuthorizingKey.fromBytes(List<int> sk) {
    return OrchardSpendAuthorizingKey(VestaFq.fromBytes(sk));
  }

  @override
  OrchardSpendVerificationKey toVerificationKey() {
    return _vk ??= () {
      final k = generator() * inner;
      return OrchardSpendVerificationKey(
        PallasNativePoint.fromBytes(k.toBytes()),
      );
    }();
  }

  @override
  PallasPoint generator() {
    return OrchardKeyUtils.orchardSpendAuthSigBasepoint;
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
  OrchardSpendAuthorizingKey randomize(VestaFq randomizer) {
    return OrchardSpendAuthorizingKey((inner + randomizer));
  }

  @override
  List<dynamic> get variables => [inner];
}

class OrchardBindingAuthorizingKey
    extends
        OrchardSigningKey<
          OrchardBindingVerificationKey,
          OrchardBindingAuthorizingKey
        > {
  final VestaFq inner;
  OrchardBindingAuthorizingKey(this.inner);
  OrchardBindingVerificationKey? _vk;
  factory OrchardBindingAuthorizingKey.fromBytes(List<int> sk) {
    return OrchardBindingAuthorizingKey(VestaFq.fromBytes(sk));
  }

  @override
  OrchardBindingVerificationKey toVerificationKey() {
    return _vk ??= () {
      final k = generator() * inner;
      return OrchardBindingVerificationKey.fromBytes(k.toBytes());
    }();
  }

  @override
  PallasPoint generator() {
    return OrchardKeyUtils.orchardBindingSigBasepoint;
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
  OrchardBindingAuthorizingKey randomize(VestaFq randomizer) {
    return OrchardBindingAuthorizingKey((inner + randomizer));
  }

  @override
  List<dynamic> get variables => [inner];
}

class OrchardSpendVerificationKey
    extends OrchardVerifyingKey<OrchardSpendVerificationKey>
    with LayoutSerializable {
  final PallasNativePoint point;
  const OrchardSpendVerificationKey._(this.point);
  factory OrchardSpendVerificationKey(PallasNativePoint point) {
    if (point.isIdentity()) {
      throw ArgumentException.invalidOperationArguments(
        "OrchardSpendVerificationKey",
        reason: "Identity point.",
      );
    }
    return OrchardSpendVerificationKey._(point);
  }

  factory OrchardSpendVerificationKey.fromBytes(List<int> pk) {
    return OrchardSpendVerificationKey(PallasNativePoint.fromBytes(pk));
  }
  factory OrchardSpendVerificationKey.deserializeJson(
    Map<String, dynamic> json,
  ) {
    return OrchardSpendVerificationKey.fromBytes(
      json.valueAsBytes("public_key"),
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
  PallasNativePoint generator() {
    return OrchardKeyUtils.orchardSpendAuthSigBasepointNative;
  }

  @override
  PallasNativePoint toPoint() {
    return point;
  }

  @override
  List<dynamic> get variables => [point];

  @override
  OrchardSpendVerificationKey randomize(VestaNativeFq randomizer) {
    final point = toPoint() + (generator() * randomizer);
    return OrchardSpendVerificationKey.fromBytes(point.toBytes());
  }
}

class OrchardBindingVerificationKey
    extends OrchardVerifyingKey<OrchardBindingVerificationKey> {
  final PallasNativePoint point;
  const OrchardBindingVerificationKey(this.point);

  factory OrchardBindingVerificationKey.fromBytes(List<int> pk) {
    return OrchardBindingVerificationKey(PallasNativePoint.fromBytes(pk));
  }

  @override
  List<int> toBytes() {
    return point.toBytes();
  }

  @override
  PallasNativePoint generator() {
    return OrchardKeyUtils.orchardBindingSigBasepointNative;
  }

  @override
  PallasNativePoint toPoint() {
    return point;
  }

  @override
  List<dynamic> get variables => [point];

  @override
  OrchardBindingVerificationKey randomize(VestaNativeFq randomizer) {
    final point = toPoint() + (generator() * randomizer);
    return OrchardBindingVerificationKey.fromBytes(point.toBytes());
  }
}
