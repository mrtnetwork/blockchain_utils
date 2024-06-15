import 'package:blockchain_utils/bip/substrate/substrate_base.dart';
import 'package:blockchain_utils/bip/substrate/substrate_keys.dart';
import 'package:blockchain_utils/signer/substrate/core/signer.dart';
import 'package:blockchain_utils/signer/substrate/core/verifier.dart';
import 'package:blockchain_utils/utils/utils.dart';

class SubstrateSigner {
  final BaseSubstrateSigner _signer;
  const SubstrateSigner._(this._signer);

  factory SubstrateSigner.fromBytes(
      List<int> keyBytes, SubstrateKeyAlgorithm algorithm) {
    return SubstrateSigner._(
        BaseSubstrateSigner.fromBytes(keyBytes, algorithm));
  }
  factory SubstrateSigner.fromSubstrate(Substrate substrate) {
    return SubstrateSigner._(BaseSubstrateSigner.fromSubstrate(substrate));
  }

  List<int> sign(List<int> digest) {
    BytesUtils.validateBytes(digest);
    return _signer.sign(digest);
  }

  List<int> vrfSign(List<int> message, {List<int>? context, List<int>? extra}) {
    BytesUtils.validateBytes(message);
    BytesUtils.validateBytes(context ?? []);
    BytesUtils.validateBytes(extra ?? []);
    return _signer.vrfSign(message, extra: extra, context: context);
  }
}

class SubstrateVerifier {
  final BaseSubstrateVerifier _verifier;
  const SubstrateVerifier._(this._verifier);

  factory SubstrateVerifier.fromBytes(
      List<int> keyBytes, SubstrateKeyAlgorithm algorithm) {
    return SubstrateVerifier._(
        BaseSubstrateVerifier.fromBytes(keyBytes, algorithm));
  }
  factory SubstrateVerifier.fromSubstrate(Substrate substrate) {
    return SubstrateVerifier._(BaseSubstrateVerifier.fromSubstrate(substrate));
  }
  bool verify(List<int> message, List<int> signature) {
    BytesUtils.validateBytes(message);
    BytesUtils.validateBytes(signature);
    return _verifier.verify(message, signature);
  }

  bool vrfVerify(List<int> message, List<int> vrfSign,
      {List<int>? context, List<int>? extra}) {
    BytesUtils.validateBytes(message);
    BytesUtils.validateBytes(vrfSign);
    BytesUtils.validateBytes(context ?? []);
    BytesUtils.validateBytes(extra ?? []);
    return _verifier.vrfVerify(message, vrfSign,
        context: context, extra: extra);
  }
}
