import 'package:blockchain_utils/api/api.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

/// Parameters for a plain ECDSA sign/verify over secp256r1.
class Secp256r1SigningParams implements ISigningParams {
  final BuBytes digest;
  final BuBytes? extraEntropy;
  Secp256r1SigningParams({required List<int> digest, List<int>? extraEntropy})
    : digest =
          digest
              .exc(
                length: 32,
                operation: "Secp256r1SigningParams",
                reason: "Invalid digest bytes length.",
              )
              .asImmutableBytes,
      extraEntropy = extraEntropy?.asImmutableBytes;
}

/// Parameters for verifying a plain ECDSA signature over secp256r1.
class Secp256r1VerifyingParams implements IVerifiyingParams {
  final Secp256r1SigningParams signingParams;
  final IECDSASignature signature;
  Secp256r1VerifyingParams(this.signingParams, this.signature);
}

/// Common interface every secp256r1 public key implements.
abstract class ISecp256r1VerificationKey
    implements IVerifiyingKey<Secp256r1VerifyingParams> {
  BuBytes get keyBytes;
  const ISecp256r1VerificationKey();

  @override
  bool verify(Secp256r1VerifyingParams verifyParams) {
    return blockchainUtils.api.signing.secp256r1.verify(
      digest: verifyParams.signingParams.digest,
      signature: verifyParams.signature,
      publicKey: keyBytes,
    );
  }
}

/// Common interface every secp256r1 private key implements.
abstract class ISecp256r1SigningKey<P extends ISecp256r1VerificationKey>
    implements ISigningKey<IECDSASignature, Secp256r1SigningParams, P> {
  const ISecp256r1SigningKey();

  /// digest must be 32 bytes and we never hash the digest
  @override
  IECDSASignature sign(Secp256r1SigningParams params) {
    return takeSecretKey().useValue(
      (k) => blockchainUtils.api.signing.secp256r1.sign(
        sk: k,
        publicKey: verificationKey().keyBytes,
        digest: params.digest,
        extraEntropy: params.extraEntropy,
      ),
    );
  }
}
