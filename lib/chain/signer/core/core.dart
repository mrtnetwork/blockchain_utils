import 'package:blockchain_utils/crypto/crypto/crypto.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

abstract class ISignatureSigner<
  VK extends IVerifiyingKey,
  SK extends ISigningKey
>
    implements SecretState {
  const ISignatureSigner(this.signingKey);
  final SK signingKey;

  @override
  void dispose() {
    signingKey.dispose();
  }

  ISignatureVerifier<VK> toVerifier();
}

abstract class ISignatureVerifier<VK extends IVerifiyingKey> {
  const ISignatureVerifier(this.verificationKey);
  final VK verificationKey;
}
