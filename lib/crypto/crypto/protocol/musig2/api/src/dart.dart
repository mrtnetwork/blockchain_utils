import 'package:blockchain_utils/crypto/crypto/protocol/musig2/musig2.dart';
import 'package:blockchain_utils/crypto/crypto/group/weierstrass/weierstrass.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// [MuSig2Api] backed by this package's pure-Dart [MuSig2].
class DartMuSig2Api implements MuSig2Api {
  final Musig2Context context;
  DartMuSig2Api({Musig2Context? context}) : context = Musig2Const();

  @override
  Secp256k1Point aggPublicKeys(List<List<int>> keys) {
    return context.aggPublicKeys(keys).publicKey;
  }

  @override
  Secp256k1Point keyAggAndTweak({
    required List<List<int>> publicKeys,
    required List<MuSig2Tweak> tweaks,
  }) {
    return context
        .keyAggAndTweak(publicKeys: publicKeys, tweaks: tweaks)
        .publicKey;
  }

  @override
  BuBytes nonceAgg(List<List<int>> pubnonces) {
    return context.nonceAgg(pubnonces);
  }

  @override
  MuSig2Nonce nonceGenerate({
    required List<int> publicKey,
    List<int>? rand,
    List<int>? sk,
    List<int>? aggPubKey,
    List<int>? msg,
    List<int>? extra,
  }) {
    return context.nonceGenerate(
      publicKey: publicKey,
      aggPubKey: aggPubKey,
      extra: extra,
      msg: msg,
      rand: rand,
      sk: sk,
    );
  }

  @override
  BuBytes partialSigAgg({
    required List<List<int>> signatures,
    required MuSig2Session session,
  }) {
    return context.partialSigAgg(signatures: signatures, session: session);
  }

  @override
  bool partialSigVerify({
    required List<int> signature,
    required List<int> pubnonce,
    required List<int> pk,
    required MuSig2Session session,
  }) {
    return context.partialSigVerify(
      signature: signature,
      pubnonce: pubnonce,
      pk: pk,
      session: session,
    );
  }

  @override
  BuBytes sign({
    required List<int> secnonce,
    required List<int> sk,
    required MuSig2Session session,
  }) {
    return context.sign(secnonce: secnonce, sk: sk, session: session);
  }

  @override
  List<BuBytes> sortPublicKeys(List<List<int>> keys) {
    return context.sortPublicKeys(keys);
  }

  @override
  MuSig2DeterministicSignature deterministicSign({
    required List<int> sk,
    required List<int> aggotherNonce,
    required List<List<int>> publicKeys,
    List<MuSig2Tweak> tweaks = const [],
    required List<int> msg,
    List<int>? rand,
  }) {
    return context.deterministicSign(
      sk: sk,
      aggotherNonce: aggotherNonce,
      publicKeys: publicKeys,
      msg: msg,
      rand: rand,
      tweaks: tweaks,
    );
  }

  @override
  bool verifyAggregate({
    required List<int> message,
    required List<int> signature,
    required List<int> aggXOnly,
  }) {
    return context.verifyAggregate(
      message: message,
      signature: signature,
      aggXOnly: aggXOnly,
    );
  }
}
