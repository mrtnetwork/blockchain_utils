import 'package:blockchain_utils/blockchain_utils.dart';

/// Abstract base for a RedDSA signing key.
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

  /// Converts to the corresponding verification key.
  V toVerificationKey();

  /// Returns the group generator.
  P generator();

  /// Serializes the key to bytes.
  List<int> toBytes();

  /// Signs a message and returns a RedDSA signature.
  ReddsaSignature sign(List<int> message);

  /// Returns a randomized version of this signing key.
  SK randomize(SCALAR randomizer);
}

/// Abstract base for a RedDSA verification key.
abstract class VerificationKey<
  SCALAR extends CryptoField<SCALAR>,
  P extends CryptoGroupElement<P, SCALAR>,
  V extends VerificationKey<SCALAR, P, V>
>
    with Equality {
  const VerificationKey();

  /// Returns the group generator.
  P generator();

  /// Serializes the verification key to bytes.
  List<int> toBytes();

  /// Verifies a RedDSA signature for a message.
  bool verifySignature(
    ReddsaSignature signature,
    List<int> message, {
    bool hashMessage = true,
  });

  /// Verifies a signature given as bytes.
  bool verifySignatureBytes(
    List<int> signatureBytes,
    List<int> message, {
    bool hashMessage = true,
  }) => verifySignature(
    ReddsaSignature.fromBytes(signatureBytes),
    message,
    hashMessage: hashMessage,
  );

  /// Converts to the corresponding group element.
  P toPoint();

  /// Returns a randomized version of this verification key.
  V randomize(SCALAR randomizer);
}

/// Represents a RedDSA signature consisting of r and s components.
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
