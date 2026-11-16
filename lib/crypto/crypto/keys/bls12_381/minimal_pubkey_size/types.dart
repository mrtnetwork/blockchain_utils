import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/keys/bls12_381/aggregate/aggregate.dart';
import 'package:blockchain_utils/crypto/crypto/keys/bls12_381/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/group/bls12_381/bls12.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

class Bls12G1Signature extends ISignature {
  final G2Projective signature;
  const Bls12G1Signature(this.signature);

  factory Bls12G1Signature.fromBytes(List<int> bytes) {
    try {
      return Bls12G1Signature(G2Projective.fromBytes(bytes));
    } catch (e) {
      throw CoreErrors.cryptoFailed(
        "Bls12G1Signature.fromBytes",
        reason: "Invalid bls g2 signature.",
        details: {"error": e.toString()},
      );
    }
  }
  factory Bls12G1Signature.aggregateSignatures(List<List<int>> signatures) {
    return BlsMinPubkeyAggregateUtils.aggregateSignatures(
      signatures.map((e) => Bls12G1Signature.fromBytes(e)).toList(),
    );
  }

  @override
  BuBytes toBytes({CryptoKeyEncoding encoding = CryptoKeyEncoding.base}) {
    return signature.toBytes(mode: encoding);
  }

  @override
  List<dynamic> get variables => [signature];
}

class Bls12G1VerifiyingParams implements IVerifiyingParams {
  final Bls12G1Signature signature;
  final Bls12SigningParams signingParams;
  Bls12G1VerifiyingParams({
    required this.signature,
    required this.signingParams,
  });
}
