import 'package:blockchain_utils/crypto/crypto/keys/bls12_381/aggregate/aggregate.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/keys/bls12_381/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/group/bls12_381/src/g1.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Min-signature-size scheme: the signature lives in **G1** (48 bytes
/// compressed) instead of G2 (96 bytes) -- the mirror image of the
/// min-pubkey-size scheme, where it's the public key that's small.
class Bls12G2Signature extends ISignature {
  final G1Projective signature;
  const Bls12G2Signature(this.signature);
  factory Bls12G2Signature.fromBytes(List<int> bytes) {
    try {
      return Bls12G2Signature(G1Projective.fromBytesUnchecked(bytes));
    } catch (_) {
      throw CoreErrors.cryptoFailed(
        "Bls12G2Signature.fromBytes",
        reason: "Invalid bls g1 signature.",
      );
    }
  }
  factory Bls12G2Signature.aggregateSignatures(List<List<int>> signatures) {
    return BlsMinSigAggregateUtils.aggregateSignatures(
      signatures.map((e) => Bls12G2Signature.fromBytes(e)).toList(),
    );
  }
  @override
  BuBytes toBytes({CryptoKeyEncoding encoding = CryptoKeyEncoding.base}) {
    return signature.toBytes(mode: encoding);
  }

  @override
  List<dynamic> get variables => [signature];
}

class Bls12G2VerifiyingParams implements IVerifiyingParams {
  final Bls12G2Signature signature;
  final Bls12SigningParams signingParams;

  Bls12G2VerifiyingParams({
    required this.signature,
    required this.signingParams,
  });
}
