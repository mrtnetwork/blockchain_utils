import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/bip/substrate/core/substrate_base.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/signer/substrate/core/signer.dart';
import 'package:blockchain_utils/signer/substrate/core/verifier.dart';

class SubstrateSigner {
  final BaseSubstrateSigner _signer;
  const SubstrateSigner._(this._signer);
  BaseSubstrateSigner get signer => _signer;

  factory SubstrateSigner.fromBytes(
      List<int> keyBytes, EllipticCurveTypes algorithm) {
    return SubstrateSigner._(
        BaseSubstrateSigner.fromBytes(keyBytes, algorithm));
  }
  factory SubstrateSigner.fromSubstrate(Substrate substrate) {
    return SubstrateSigner._(BaseSubstrateSigner.fromSubstrate(substrate));
  }

  List<int> sign(List<int> digest) {
    return _signer.sign(digest.asBytes);
  }

  List<int> vrfSign(List<int> message, {List<int>? context, List<int>? extra}) {
    return _signer.vrfSign(message.asBytes,
        extra: extra?.asBytes, context: context?.asBytes);
  }
}

class SubstrateVerifier {
  final BaseSubstrateVerifier _verifier;
  const SubstrateVerifier._(this._verifier);

  factory SubstrateVerifier.fromBytes(
      List<int> keyBytes, EllipticCurveTypes algorithm) {
    return SubstrateVerifier._(
        BaseSubstrateVerifier.fromBytes(keyBytes, algorithm));
  }
  factory SubstrateVerifier.fromSubstrate(Substrate substrate) {
    return SubstrateVerifier._(BaseSubstrateVerifier.fromSubstrate(substrate));
  }
  bool verify(List<int> message, List<int> signature) {
    return _verifier.verify(message.asBytes, signature.asBytes);
  }

  bool vrfVerify(List<int> message, List<int> vrfSign,
      {List<int>? context, List<int>? extra}) {
    return _verifier.vrfVerify(message.asBytes, vrfSign.asBytes,
        context: context?.asBytes, extra: extra?.asBytes);
  }
}
