import 'package:blockchain_utils/chain/address/protocol/p2tr_addr.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/protocol/musig2/constants/const.dart';
import 'package:blockchain_utils/crypto/crypto/protocol/musig2/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/protocol/musig2/utils/utils_const.dart';
import 'package:blockchain_utils/crypto/crypto/group/weierstrass/weierstrass.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/chain/signer/const/constants.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/crypto/crypto/keys/constants/ecdsa.dart';

/// Contract for a MuSig2 signing session: nonce generation/aggregation,
/// key aggregation, partial signing, and signature aggregation.
abstract class Musig2Context {
  const Musig2Context();
  BuBytes nonceAgg(List<List<int>> pubnonces);

  /// Generates a MuSig2 nonce for signing
  MuSig2Nonce nonceGenerate({
    required List<int> publicKey,
    List<int>? rand,
    List<int>? sk,
    List<int>? aggPubKey,
    List<int>? msg,
    List<int>? extra,
  });

  /// sort public keys
  List<BuBytes> sortPublicKeys(List<List<int>> keys) {
    return MuSig2UtilsConst.sortPublicKeys(
      keys.map((e) => e.asImmutableBytes).toList(),
    );
  }

  /// Aggregates public keys for MuSig2
  MuSig2KeyAggContext aggPublicKeys(List<List<int>> keys);

  /// Verifies a MuSig2 partial signature
  bool partialSigVerify({
    required List<int> signature,
    required List<int> pubnonce,
    required List<int> pk,
    required MuSig2Session session,
  }) {
    if (pubnonce.length != MuSig2Constants.pubnonceLength) {
      throw CoreErrors.invalidOperationArguments(
        "partialSigVerify",
        name: "pubnonce",
        reason: "Invalid pubnonce bytes length.",
      );
    }
    final values = MuSig2UtilsConst.decodeSessionConst(session);
    Secp256k1Fr s;
    try {
      s = Secp256k1Fr.fromBytes(signature);
    } catch (_) {
      return false;
    }
    final rS1 = MuSig2UtilsConst.encodePointAsEvenConst(
      pubnonce.sublist(0, EcdsaKeysConst.pubKeyCompressedByteLen),
    );
    final rS2 = MuSig2UtilsConst.encodePointAsEvenConst(
      pubnonce.sublist(
        EcdsaKeysConst.pubKeyCompressedByteLen,
        EcdsaKeysConst.pubKeyCompressedByteLen * 2,
      ),
    );
    Secp256k1Point reS = rS1 + (rS2 * values.bFr);
    if (values.r.isOdd) {
      reS = -reS;
    }
    final p = MuSig2UtilsConst.encodePoint(pk);
    final a = MuSig2UtilsConst.getSessionKeyAggCoeffConst(
      session: session,
      pkBytes: p.toBytes(),
    );
    var g = Secp256k1Fr.one;
    if (values.publicKey.isOdd) {
      g = -g;
    }
    g = g * values.gaccFr;
    final expected = MuSig2Constants.generator * s;
    final r = reS + (p * (values.eFr * a * g));

    return expected == r;
  }

  /// Generates a MuSig2 partial signature
  BuBytes sign({
    required List<int> secnonce,
    required List<int> sk,
    required MuSig2Session session,
  });

  /// Generates a deterministic MuSig2 signature
  MuSig2DeterministicSignature deterministicSign({
    required List<int> sk,
    required List<int> aggotherNonce,
    required List<List<int>> publicKeys,
    List<MuSig2Tweak> tweaks = const [],
    required List<int> msg,
    List<int>? rand,
  });

  /// Aggregates MuSig2 partial signatures
  BuBytes partialSigAgg({
    required List<List<int>> signatures,
    required MuSig2Session session,
  }) {
    final values = MuSig2UtilsConst.decodeSessionConst(session);
    var s = Secp256k1Fr.zero;
    for (final i in signatures) {
      try {
        s = s + Secp256k1Fr.fromBytes(i);
      } catch (_) {
        throw CoreErrors.invalidOperationArguments(
          "partialSigAgg",
          name: "signatures",
          reason: "Invalid signatures.",
        );
      }
    }

    var g = Secp256k1Fr.one;
    if (values.publicKey.isOdd) {
      g = -g;
    }
    s = s + values.eFr * g * values.taccFr;
    return BuBytes.concat([values.r.toXOnly(), s.toBytes()]);
  }

  MuSig2KeyAggContext keyAggAndTweak({
    required List<List<int>> publicKeys,
    required List<MuSig2Tweak> tweaks,
  });

  bool verifyAggregate({
    required List<int> message,
    required List<int> signature,
    required List<int> aggXOnly,
  }) {
    if (signature.length != CryptoSignerConst.ecdsaSignatureLength) {
      return false;
    }
    final sig = signature;
    final half = MuSig2Constants.xOnlyBytesLength;
    if (sig.length != half * 2) return false;

    final rBytes = sig.sublist(0, half);
    final sBytes = sig.sublist(half, half * 2);
    Secp256k1Fr s;
    try {
      s = Secp256k1Fr.fromBytes(sBytes);
    } catch (_) {
      return false;
    }

    late final Secp256k1Point p;
    try {
      p = P2TRUtils.liftX(aggXOnly);
    } catch (_) {
      return false;
    }

    final eHash = P2TRUtils.taggedHash(MuSig2Constants.challengeDomain, [
      ...rBytes,
      ...aggXOnly,
      ...message,
    ]);
    final e = Secp256k1Fr.fromBytesUnchecked(eHash);

    final r = (MuSig2Constants.generator * s) + (-(p * e));
    if (r.isZero() || r.isOdd) return false;
    return BytesUtils.bytesEqual(r.toXOnly(), rBytes);
  }
}
