import 'package:blockchain_utils/api/api/api.dart';
import 'package:blockchain_utils/crypto/crypto/keys/bls12_381/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/group/bls12_381/bls12.dart';
import 'package:blockchain_utils/crypto/crypto/group/jubjub/fields/field.dart';

import 'package:blockchain_utils/crypto/crypto/keys/bls12_381/minimal_signature_size/types.dart';

/// Min-signature-size scheme (mirror of [IBlsSigningKey]):
///   - hash-to-curve lands in G1 (via [BlsHashToG1], not [BlsHashToG2])
///   - the signature is therefore a G1 point (48 bytes compressed)
///   - `sk` is unchanged: still the JubJubFq scalar in Fr
abstract class IBlsMinSigSigningKey<P extends IBlsMinSigVerificationKey>
    implements ISigningKey<Bls12G2Signature, Bls12SigningParams, P> {
  JubJubFq scalar();
  @override
  Bls12G2Signature sign(Bls12SigningParams params) {
    return takeSecretKey().useValue(
      (k) => blockchainUtils.api.signing.bls.signMinSig(
        sk: k,
        message: params.message,
        dst: params.dst,
      ),
    );
  }
}

/// Mirror of [IBlsVerificationKey]: the public key now lives in **G2**
/// (via [G2Projective.generator]), so verification checks
///   e(H(m), pk) == e(sig, G2.generator)
/// which is the same pairing identity as the min-pubkey-size scheme, just
/// with the roles of G1 and G2 swapped -- see the derivation in the PR
/// description / accompanying notes for why this equation (rather than
/// e(pk, H(m)) == e(G2.generator, sig)) is the one that actually holds:
/// sig = sk*H(m), pk = sk*G2.generator, and pairing bilinearity gives
/// e(H(m), pk) = e(H(m), G2.generator)^sk = e(sig, G2.generator).
abstract class IBlsMinSigVerificationKey
    implements IVerifiyingKey<Bls12G2VerifiyingParams> {
  @override
  bool verify(Bls12G2VerifiyingParams params) {
    return blockchainUtils.api.signing.bls.verifyMinSig(
      pk: toBytes(),
      message: params.signingParams.message,
      dst: params.signingParams.dst,
      signature: params.signature,
    );
  }
}
