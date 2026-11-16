import 'package:blockchain_utils/api/api.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

/// An ML-DSA signature.
class MLDSASignature extends ISignature {
  final BuBytes bytes;
  MLDSASignature(List<int> bytes) : bytes = bytes.asImmutableBytes;

  @override
  BuBytes toBytes() => bytes.cloneBytes();

  @override
  List<dynamic> get variables => [bytes];
}

/// Parameters for an ML-DSA sign operation.
class MLDSASigningParams implements ISigningParams {
  final BuBytes message;
  final BuBytes? nonce;
  final BuBytes? context;
  MLDSASigningParams(List<int> message, {List<int>? nonce, List<int>? context})
    : message = message.asImmutableBytes,
      nonce = nonce?.asImmutableBytes,
      context = context?.asImmutableBytes;
}

/// Parameters for an ML-DSA verify operation.
class MLDSAVerifyingParams implements IVerifiyingParams {
  final BuBytes message;
  final BuBytes? context;
  final MLDSASignature signature;
  MLDSAVerifyingParams(List<int> message, this.signature, {List<int>? context})
    : message = message.asImmutableBytes,
      context = context?.asImmutableBytes;
}

/// Common interface every ML-DSA public key implements.
abstract class IMLDSAVerificationKey
    implements IVerifiyingKey<MLDSAVerifyingParams> {
  const IMLDSAVerificationKey();

  BuBytes get bytes;

  @override
  bool verify(MLDSAVerifyingParams verifyParams) {
    return blockchainUtils.api.signing.mldsa.verify(
      pk: bytes,
      message: verifyParams.message,
      signature: verifyParams.signature.toBytes(),
      context: verifyParams.context,
    );
  }
}

/// Common interface every ML-DSA private key implements.
abstract class IMLDSASigningKey<P extends IMLDSAVerificationKey>
    implements ISigningKey<MLDSASignature, MLDSASigningParams, P> {
  const IMLDSASigningKey();

  @override
  MLDSASignature sign(MLDSASigningParams signingParams) {
    return takeSecretKey().useValue((bytes) {
      final signature = blockchainUtils.api.signing.mldsa.sign(
        message: signingParams.message,
        sk: bytes,
        rnd: signingParams.nonce,
        context: signingParams.context,
      );
      return MLDSASignature(signature);
    });
  }
}
