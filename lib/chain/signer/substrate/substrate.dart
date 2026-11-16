import 'package:blockchain_utils/chain/signer/core/core.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/protocol/substrate/core/substrate_base.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/chain/signer/substrate/core/signer.dart';
import 'package:blockchain_utils/chain/signer/substrate/core/verifier.dart';
import 'package:blockchain_utils/chain/signer/types/signature.dart';
export 'package:blockchain_utils/chain/signer/substrate/signers/substrate_ecdsa.dart';
export 'package:blockchain_utils/chain/signer/substrate/signers/substrate_sr25519.dart';
export 'package:blockchain_utils/chain/signer/substrate/signers/substrate_eddsa.dart';

/// Substrate signer: dispatches to the ED25519/ECDSA/SR25519 signer for the
/// key's algorithm.
class SubstrateSigner extends ISignatureSigner<IVerifiyingKey, ISigningKey> {
  final BaseSubstrateSigner signer;
  SubstrateSigner(this.signer) : super(signer.signingKey);

  factory SubstrateSigner.fromBytes(
    List<int> keyBytes,
    CryptoKeyType algorithm,
  ) {
    return SubstrateSigner(BaseSubstrateSigner.fromBytes(keyBytes, algorithm));
  }
  factory SubstrateSigner.fromSubstrate(Substrate substrate) {
    return SubstrateSigner(BaseSubstrateSigner.fromSubstrate(substrate));
  }

  SignedContent<ISignature> sign(List<int> digest) {
    return signer.sign(digest.asBytes);
  }

  SignedContent<ISignature> vrfSign(
    List<int> message, {
    List<int>? context,
    List<int>? extra,
  }) {
    return signer.vrfSign(
      message.asBytes,
      extra: extra?.asBytes,
      context: context?.asBytes,
    );
  }

  @override
  SubstrateVerifier toVerifier() {
    return SubstrateVerifier(signer.toVerifier());
  }
}

/// Substrate signature verifier: dispatches to the ED25519/ECDSA/SR25519
/// verifier for the key's algorithm.
class SubstrateVerifier extends ISignatureVerifier<IVerifiyingKey> {
  final BaseSubstrateVerifier verifier;
  SubstrateVerifier(this.verifier) : super(verifier.verificationKey);

  factory SubstrateVerifier.fromBytes(
    List<int> keyBytes,
    CryptoKeyType algorithm,
  ) {
    return SubstrateVerifier(
      BaseSubstrateVerifier.fromBytes(keyBytes, algorithm),
    );
  }
  factory SubstrateVerifier.fromSubstrate(Substrate substrate) {
    return SubstrateVerifier(BaseSubstrateVerifier.fromSubstrate(substrate));
  }
  bool verify(List<int> message, List<int> signature) {
    return verifier.verify(message.asBytes, signature.asBytes);
  }

  bool vrfVerify(
    List<int> message,
    List<int> vrfSign, {
    List<int>? context,
    List<int>? extra,
  }) {
    return verifier.vrfVerify(
      message.asBytes,
      vrfSign.asBytes,
      context: context?.asBytes,
      extra: extra?.asBytes,
    );
  }
}
