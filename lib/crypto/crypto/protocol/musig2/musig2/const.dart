import 'package:blockchain_utils/chain/address/protocol/p2tr_addr.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/protocol/musig2/constants/const.dart';
import 'package:blockchain_utils/crypto/crypto/protocol/musig2/musig2/base.dart';
import 'package:blockchain_utils/crypto/crypto/protocol/musig2/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/protocol/musig2/utils/utils_const.dart';
import 'package:blockchain_utils/crypto/crypto/group/weierstrass/weierstrass.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';
import 'package:blockchain_utils/crypto/crypto/keys/constants/ecdsa.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// [MuSig2] variant over the limb-based [Secp256k1Point] backend.
///
/// Scalar clamping and blinding contexts of the old backend are gone:
/// scalars are canonical [Secp256k1Fr] values and every mult is a uniform
/// double-and-add-always.
class Musig2Const extends Musig2Context {
  static Secp256k1Fr _fr(List<int> s) => Secp256k1Fr.fromBytes(s);

  @override
  MuSig2KeyAggContext aggPublicKeys(List<List<int>> keys) {
    return MuSig2UtilsConst.aggPublicKeys(keys: keys);
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
    if (rand != null) {
      rand = BytesUtils.xor(
        sk,
        P2TRUtils.taggedHash(MuSig2Constants.musigAuxDomain, rand),
      );
    } else {
      rand = sk.clone();
    }
    final aggPk = MuSig2UtilsConst.keyAggAndTweak(
      publicKeys: publicKeys,
      tweaks: tweaks,
    );
    final aggPkX = aggPk.xOnly().asImmutableBytes;
    final k1 = MuSig2UtilsConst.deterministicNonceHash(
      sk: rand,
      aggotherNonce: aggotherNonce,
      aggPk: aggPkX,
      i: 0,
      msg: msg,
    );
    final k2 = MuSig2UtilsConst.deterministicNonceHash(
      sk: rand,
      aggotherNonce: aggotherNonce,
      aggPk: aggPkX,
      i: 1,
      msg: msg,
    );
    final rs1 = Secp256k1Point.generator_ * k1;
    final rs2 = Secp256k1Point.generator_ * k2;
    Secp256k1Point pk;
    try {
      pk = Secp256k1Point.generator_ * _fr(sk);
    } catch (_) {
      throw CoreErrors.invalidOperationArguments(
        "deterministicSignConst",
        name: "sk",
        reason: "Invalid secret key bytes.",
      );
    }
    final pubnonce = [...rs1.toBytes(), ...rs2.toBytes()];
    final secnonce = [...k1.toBytes(), ...k2.toBytes(), ...pk.toBytes()];
    final aggnonce = nonceAgg([pubnonce, aggotherNonce]);
    final session = MuSig2Session(
      aggnonce: aggnonce,
      publicKeys: publicKeys,
      tweaks: tweaks,
      msg: msg,
    );
    final signature = sign(secnonce: secnonce, sk: sk, session: session);
    return MuSig2DeterministicSignature(
      pubnonce: pubnonce,
      signature: signature,
    );
  }

  @override
  BuBytes nonceAgg(List<List<int>> pubnonces) {
    if (pubnonces.length < MuSig2Constants.minimumRequiredKey) {
      throw CoreErrors.invalidOperationArguments(
        "nonceAggConst",
        name: "pubnonces",
        reason: "Invalid public nonce length.",
      );
    }
    for (final i in pubnonces) {
      if (i.length != MuSig2Constants.pubnonceLength) {
        throw CoreErrors.invalidOperationArguments(
          "nonceAggConst",
          name: "pubnonces",
          reason: "Invalid public nonce length.",
        );
      }
    }
    final nonce = BuBytes.empty();
    for (int i = 1; i < 3; i++) {
      Secp256k1Point? rJ;
      for (final n in pubnonces) {
        final offset = (i - 1) * EcdsaKeysConst.pubKeyCompressedByteLen;
        final key = MuSig2UtilsConst.encodePointAsEvenConst(
          n.sublist(offset, offset + EcdsaKeysConst.pubKeyCompressedByteLen),
        );
        rJ = rJ == null ? key : rJ + key;
      }
      if (rJ!.isZero()) {
        nonce.addAll(MuSig2UtilsConst.zeroPk());
      } else {
        nonce.addAll(rJ.toBytes());
      }
    }

    return nonce;
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
    if (publicKey.length != EcdsaKeysConst.pubKeyCompressedByteLen) {
      throw CoreErrors.invalidOperationArguments(
        "nonceGenerate",
        name: "publicKey",
        reason: "Invalid public key bytes length.",
      );
    }
    rand ??= QuickCrypto.generateRandom();
    if (sk != null) {
      rand = BytesUtils.xor(
        sk,
        P2TRUtils.taggedHash(MuSig2Constants.musigAuxDomain, rand),
      );
    }
    if (msg == null) {
      msg = [0];
    } else {
      msg = [1, ...msg.length.toBeBytes(length: 8), ...msg];
    }
    extra ??= [];
    aggPubKey ??= [];
    final k1 = MuSig2UtilsConst.nonceHash(
      rand: rand,
      publicKey: publicKey,
      aggPk: aggPubKey,
      i: 0,
      messagePrefix: msg,
      extraIn: extra,
    );
    final k2 = MuSig2UtilsConst.nonceHash(
      rand: rand,
      publicKey: publicKey,
      aggPk: aggPubKey,
      i: 1,
      messagePrefix: msg,
      extraIn: extra,
    );
    final rs1 = Secp256k1Point.generator_ * k1;
    final rs2 = Secp256k1Point.generator_ * k2;
    final pubNonce = [...rs1.toBytes(), ...rs2.toBytes()];
    final secNonce = [...k1.toBytes(), ...k2.toBytes(), ...publicKey];
    return MuSig2Nonce(secnonce: secNonce, pubnonce: pubNonce);
  }

  @override
  BuBytes sign({
    required List<int> secnonce,
    required List<int> sk,
    required MuSig2Session session,
  }) {
    if (secnonce.length != MuSig2Constants.secnoncelength) {
      throw CoreErrors.invalidOperationArguments(
        "sign",
        name: "secnonce",
        reason: "Invalid secret nonce bytes length.",
      );
    }
    final values = MuSig2UtilsConst.decodeSessionConst(session);
    final r = values.r;
    final isOdd = r.isOdd;
    final k1 = _fr(secnonce.sublist(0, MuSig2Constants.xOnlyBytesLength));
    final k2 = _fr(
      secnonce.sublist(
        MuSig2Constants.xOnlyBytesLength,
        MuSig2Constants.xOnlyBytesLength * 2,
      ),
    );
    // Effective nonces are negated when R is odd, but the self-verify
    // pubnonce below must carry the ORIGINAL nonces: `partialSigVerify`
    // applies the odd-R negation itself (same as `MuSig2.sign`).
    var kE1 = k1;
    var kE2 = k2;
    if (isOdd) {
      kE1 = -k1;
      kE2 = -k2;
    }
    Secp256k1Fr d;
    try {
      d = _fr(sk);
    } catch (_) {
      throw CoreErrors.invalidOperationArguments(
        "sign",
        name: "sk",
        reason: "Invalid secret key.",
      );
    }
    Secp256k1Point rPt = Secp256k1Point.generator_ * d;
    final pkBytes = rPt.toBytes();
    final pkOffset = MuSig2Constants.xOnlyBytesLength * 2;
    if (!BytesUtils.bytesEqualConst(
      secnonce.sublist(
        pkOffset,
        pkOffset + EcdsaKeysConst.pubKeyCompressedByteLen,
      ),
      pkBytes,
    )) {
      throw CoreErrors.invalidOperationArguments(
        "sign",
        reason: "Mismatch between secret key and public key.",
      );
    }
    final a = MuSig2UtilsConst.getSessionKeyAggCoeffConst(
      session: session,
      pkBytes: pkBytes,
    );
    final aggPk = Secp256k1Point.fromBytes(values.publicKey.toBytes());
    var g = Secp256k1Fr.one;
    if (aggPk.isOdd) {
      g = -g;
    }
    final gcc = _fr(values.gacc);
    final b = _fr(values.b);
    final e = _fr(values.e);
    final gacc = gcc * g;
    final dd = gacc * d;
    var s1 = b * kE2 + kE1;
    final s2 = e * a * dd;
    s1 = s1 + s2;

    if (s1.isZero()) {
      throw const BuError(
        DefaultErrorType.invalidSignature,
        'Signing failed due to generate signature scalar.',
      );
    }
    final rS1 = Secp256k1Point.generator_ * k1;
    final rS2 = Secp256k1Point.generator_ * k2;
    final signature = s1.toBytes();
    final List<int> pubnonce = [...rS1.toBytes(), ...rS2.toBytes()];
    final verify = partialSigVerify(
      signature: signature,
      pubnonce: pubnonce,
      pk: pkBytes,
      session: session,
    );
    if (!verify) {
      throw CoreErrors.signVerificationFailed;
    }
    return signature.asImmutableBytes;
  }

  @override
  MuSig2KeyAggContext keyAggAndTweak({
    required List<List<int>> publicKeys,
    required List<MuSig2Tweak> tweaks,
  }) {
    return MuSig2UtilsConst.keyAggAndTweak(
      publicKeys: publicKeys,
      tweaks: tweaks,
    );
  }
}
