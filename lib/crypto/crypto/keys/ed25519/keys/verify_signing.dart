import 'package:blockchain_utils/api/api/api.dart';

import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// An ed25519 signature (32-byte R + 32-byte S).
class ED25519Signature extends ISignature {
  final BuBytes r;
  final BuBytes s;
  ED25519Signature({required List<int> r, required List<int> s})
    : r =
          r
              .exc(
                length: 32,
                operation: "ED25519Signature",
                reason: "Invalid signature.",
              )
              .asImmutableBytes,
      s =
          s
              .exc(
                length: 32,
                operation: "ED25519Signature",
                reason: "Invalid signature.",
              )
              .asImmutableBytes;
  factory ED25519Signature.fromBytes(List<int> bytes) {
    final signature = bytes.exc(
      length: 64,
      operation: "ED25519Signature.fromBytes",
      reason: "Invalid signature bytes length.",
    );
    return ED25519Signature(
      r: signature.sublist(0, 32),
      s: signature.sublist(32),
    );
  }

  @override
  BuBytes toBytes() => BuBytes.unsafeMutable([...r, ...s]);

  @override
  List<dynamic> get variables => [r, s];
}

/// Parameters for an ed25519 sign operation: the message bytes.
class Ed25519SigningParams implements ISigningParams {
  final BuBytes message;
  Ed25519SigningParams({required List<int> message})
    : message = message.asImmutableBytes;
}

/// Parameters for an ed25519 verify operation: message + signature.
class Ed25519VerifyingParams implements IVerifiyingParams {
  final Ed25519SigningParams signingParams;
  final ED25519Signature signature;
  Ed25519VerifyingParams(this.signingParams, this.signature);
}

/// Common interface every ed25519-family public key implements.
abstract class IEd25519VerificationKey
    implements IVerifiyingKey<Ed25519VerifyingParams> {
  BuBytes get keyBytes;
  const IEd25519VerificationKey();

  @override
  bool verify(Ed25519VerifyingParams verifyParams) {
    return blockchainUtils.api.signing.ed25519.verify(
      message: verifyParams.signingParams.message,
      signature: verifyParams.signature.toBytes(),
      publicKey: keyBytes,
      type: type,
    );
  }
}

/// Common interface every ed25519-family private key implements.
abstract class IEd25519SigningKey<P extends IEd25519VerificationKey>
    implements ISigningKey<ED25519Signature, Ed25519SigningParams, P> {
  @override
  CryptoKeyType get type;
  const IEd25519SigningKey();

  @override
  ED25519Signature sign(Ed25519SigningParams params) {
    final signature = takeSecretKey().useValue(
      (k) => blockchainUtils.api.signing.ed25519.sign(
        message: params.message,
        publicKey: verificationKey().keyBytes,
        sk: k,
        type: type,
      ),
    );
    return ED25519Signature.fromBytes(signature);
  }

  @override
  P verificationKey();
}
