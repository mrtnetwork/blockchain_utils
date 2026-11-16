import 'package:blockchain_utils/crypto/crypto/keys/bls12_381/minimal_signature_size/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/bls12_381/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

class Bls12G2AggregateVerifiyingParams implements IVerifiyingParams {
  final Bls12G2Signature signature;
  final List<BuBytes> messages;
  final BuBytes? dst;

  Bls12G2AggregateVerifiyingParams({
    required this.signature,
    required List<List<int>> messages,
    List<int>? dst,
  }) : messages = messages.map((e) => e.asImmutableBytes).toImutableList,
       dst = dst?.asImmutableBytes;
}

class Bls12G2AggregateFastVerifiyingParams implements IVerifiyingParams {
  final Bls12G2Signature signature;
  final Bls12SigningParams signingParams;

  Bls12G2AggregateFastVerifiyingParams({
    required this.signature,
    required this.signingParams,
  });
}

class Bls12G2AggregateBatchVerifiyingParams implements IVerifiyingParams {
  final List<Bls12G2Signature> signatures;
  final List<BuBytes> messages;
  final BuBytes? dst;

  Bls12G2AggregateBatchVerifiyingParams({
    required List<Bls12G2Signature> signatures,
    required List<List<int>> messages,
    List<int>? dst,
  }) : messages = messages.map((e) => e.asImmutableBytes).toImutableList,
       dst = dst?.asImmutableBytes,
       signatures = signatures.immutable;
}

class Bls12G2BatchSignature extends ISignature {
  final List<Bls12G2Signature> signatures;
  final Bls12G2Signature aggregateSignature;
  Bls12G2BatchSignature({
    required this.aggregateSignature,
    required List<Bls12G2Signature> signatures,
  }) : signatures = signatures.immutable;

  @override
  BuBytes toBytes({CryptoKeyEncoding encoding = CryptoKeyEncoding.base}) {
    return aggregateSignature.toBytes(encoding: encoding);
  }

  @override
  List<dynamic> get variables => [aggregateSignature];
}
