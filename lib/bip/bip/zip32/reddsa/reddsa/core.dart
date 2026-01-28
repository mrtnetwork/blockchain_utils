import 'package:blockchain_utils/blockchain_utils.dart';

abstract class ReddsaSigningKey<
  SCALAR extends CryptoField<SCALAR>,
  P extends CryptoGroupElement<P, SCALAR>,
  SCALARNATIVE extends CryptoField<SCALARNATIVE>,
  PNATIVE extends CryptoGroupElement<PNATIVE, SCALARNATIVE>,
  V extends VerificationKey<SCALARNATIVE, PNATIVE, V>,
  SK extends ReddsaSigningKey<SCALAR, P, SCALARNATIVE, PNATIVE, V, SK>
>
    with Equality {
  const ReddsaSigningKey();
  V toVerificationKey();
  P generator();
  List<int> toBytes();
  ReddsaSignature sign(List<int> message);
  SK randomize(SCALAR randomizer);
}

abstract class VerificationKey<
  SCALAR extends CryptoField<SCALAR>,
  P extends CryptoGroupElement<P, SCALAR>,
  V extends VerificationKey<SCALAR, P, V>
>
    with Equality {
  const VerificationKey();
  P generator();
  List<int> toBytes();
  bool verifySignature(
    ReddsaSignature signature,
    List<int> message, {
    bool hashMessage = true,
  });
  bool verifySignatureBytes(
    List<int> signatureBytes,
    List<int> message, {
    bool hashMessage = true,
  }) => verifySignature(
    ReddsaSignature.fromBytes(signatureBytes),
    message,
    hashMessage: hashMessage,
  );
  P toPoint();
  V randomize(SCALAR randomizer);
}

class ReddsaSignature with LayoutSerializable, Equality {
  final List<int> rBytes;
  final List<int> sBytes;
  ReddsaSignature.fromBytes(List<int> bytes)
    : rBytes =
          bytes
              .exc(
                length: 64,
                operation: "ReddsaSignature",
                reason: "Invalid signatre bytes length.",
              )
              .sublist(0, 32)
              .asImmutableBytes,
      sBytes = bytes.sublist(32).asImmutableBytes;
  ReddsaSignature({required this.rBytes, required this.sBytes});
  factory ReddsaSignature.deserializeJson(Map<String, dynamic> json) {
    return ReddsaSignature.fromBytes(json.valueAsBytes("signature"));
  }
  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      LayoutConst.fixedBlobN(64, property: "signature"),
    ], property: property);
  }

  @override
  Map<String, dynamic> toSerializeJson() {
    return {"signature": toBytes()};
  }

  @override
  Layout<Map<String, dynamic>> toLayout({String? property}) {
    return layout(property: property);
  }

  List<int> toBytes() {
    return [...rBytes, ...sBytes];
  }

  @override
  List<dynamic> get variables => [rBytes, sBytes];
}
