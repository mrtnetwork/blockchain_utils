import 'package:blockchain_utils/bip/ecc/keys/ecdsa_keys.dart';
import 'package:blockchain_utils/crypto/crypto/ec/musig2/constants/const.dart';
import 'package:blockchain_utils/crypto/crypto/ec/musig2/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/ec/musig2/utils/utils.dart';
import 'package:blockchain_utils/crypto/crypto/ec/core/point.dart';
import 'package:blockchain_utils/exception/exception/exception.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';

abstract class Musig2Bsae {
  const Musig2Bsae();
  List<int> nonceAgg(List<List<int>> pubnonces);

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
  List<List<int>> sortPublicKeys({required List<List<int>> keys}) {
    return MuSig2Utils.sortPublicKeys(keys);
  }

  /// Aggregates public keys for MuSig2
  MuSig2KeyAggContext aggPublicKeys({required List<List<int>> keys});

  /// Verifies a MuSig2 partial signature
  bool partialSigVerify({
    required List<int> signature,
    required List<int> pubnonce,
    required List<int> pk,
    required MuSig2Session session,
  }) {
    if (pubnonce.length != MuSig2Constants.pubnonceLength) {
      throw ArgumentException.invalidOperationArguments(
        "partialSigVerify",
        name: "pubnonce",
        reason: "Invalid pubnonce bytes length.",
        expecteLen: MuSig2Constants.pubnonceLength,
      );
    }
    final values = MuSig2Utils.decodeSession(session);
    final sBig = BigintUtils.fromBytes(signature);
    if (sBig >= MuSig2Constants.order) return false;
    final rS1 = MuSig2Utils.encodePointAsEven(
      pubnonce.sublist(0, EcdsaKeysConst.pubKeyCompressedByteLen),
    );
    final rS2 = MuSig2Utils.encodePointAsEven(
      pubnonce.sublist(
        EcdsaKeysConst.pubKeyCompressedByteLen,
        EcdsaKeysConst.pubKeyCompressedByteLen * 2,
      ),
    );
    BaseProjectivePointNative reS = (rS1 + (rS2 * values.bAsInteger));
    if (values.r.isOdd) {
      reS = -reS;
    }
    final p = MuSig2Utils.encodePoint(pk);
    final a = MuSig2Utils.getSessionKeyAggCoeff(session: session, pk: p);
    BigInt g = BigInt.one;
    if (values.publicKey.isOdd) {
      g = MuSig2Constants.order - BigInt.one;
    }
    g = g * values.gaccAsInteger % MuSig2Constants.order;
    final expected = MuSig2Constants.generator * sBig;
    final r = (reS + (p * (values.eAsInteger * a * g % MuSig2Constants.order)));

    return expected == r;
  }

  /// Generates a MuSig2 partial signature
  List<int> sign({
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
  List<int> partialSigAgg({
    required List<List<int>> signatures,
    required MuSig2Session session,
  }) {
    final values = MuSig2Utils.decodeSession(session);
    BigInt s = BigInt.zero;
    for (final i in signatures) {
      final sBig = BigintUtils.fromBytes(i);
      if (sBig >= MuSig2Constants.order) {
        throw ArgumentException.invalidOperationArguments(
          "partialSigAgg",
          name: "signatures",
          reason: "Invalid signatures.",
        );
      }
      s = (s + sBig) % MuSig2Constants.order;
    }
    BigInt g = BigInt.one;
    if (values.publicKey.isOdd) {
      g = MuSig2Constants.order - BigInt.one;
    }
    s =
        (s + values.eAsInteger * g * values.taccAsInteger) %
        MuSig2Constants.order;
    return [...values.r.toXonly(), ...BigintUtils.toBytes(s)];
  }

  MuSig2KeyAggContext keyAggAndTweak({
    required List<List<int>> publicKeys,
    required List<MuSig2Tweak> tweaks,
  });
}
