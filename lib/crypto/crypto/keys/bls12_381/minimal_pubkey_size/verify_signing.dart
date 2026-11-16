import 'package:blockchain_utils/api/api.dart';
import 'package:blockchain_utils/crypto/crypto/keys/bls12_381/minimal_pubkey_size/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/bls12_381/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/group/jubjub/jubjub.dart';

abstract class IBlsSigningKey<P extends IBlsVerificationKey>
    implements ISigningKey<Bls12G1Signature, Bls12SigningParams, P> {
  JubJubFq scalar();
  @override
  Bls12G1Signature sign(Bls12SigningParams params) {
    return takeSecretKey().useValue(
      (k) => blockchainUtils.api.signing.bls.signMinPk(
        sk: k,
        message: params.message,
        dst: params.dst,
      ),
    );
  }
}

abstract class IBlsVerificationKey
    implements IVerifiyingKey<Bls12G1VerifiyingParams> {
  @override
  bool verify(Bls12G1VerifiyingParams params) {
    return blockchainUtils.api.signing.bls.verifyMinPk(
      pk: toBytes(),
      message: params.signingParams.message,
      dst: params.signingParams.dst,
      signature: params.signature,
    );
  }
}
