import 'package:blockchain_utils/bip/address/p2tr_addr.dart';
import 'package:blockchain_utils/bip/ecc/keys/ecdsa_keys.dart';
import 'package:blockchain_utils/crypto/crypto/ec/musig2/constants/const.dart';
import 'package:blockchain_utils/crypto/crypto/ec/musig2/musig2/base.dart';
import 'package:blockchain_utils/crypto/crypto/ec/musig2/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/ec/musig2/utils/utils.dart';
import 'package:blockchain_utils/crypto/crypto/ec/musig2/utils/utils_const.dart';
import 'package:blockchain_utils/crypto/crypto/ec/projective/secp256k1/constants/constants.dart';
import 'package:blockchain_utils/crypto/crypto/ec/projective/secp256k1/impl/secp256k1.dart';
import 'package:blockchain_utils/crypto/crypto/ec/projective/secp256k1/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/ec/utils/secp256k1.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exception/exception.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/signer/exception/signing_exception.dart';
import 'package:blockchain_utils/utils/binary/bytes_tracker.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';

class Musig2Const extends Musig2Bsae {
  const Musig2Const();
  @override
  MuSig2KeyAggContext aggPublicKeys({required List<List<int>> keys}) {
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
    final aggPkX = aggPk.xOnly().asImmutableBytesConst;
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
    final rs1 = Secp256k1Utils.secp256k1MultBase(scalar: k1);
    final rs2 = Secp256k1Utils.secp256k1MultBase(scalar: k2);
    final pk = Secp256k1Utils.generatePublicKeyBlind(scalarBytes: sk);
    if (pk == null) {
      throw ArgumentException.invalidOperationArguments(
        "deterministicSignConst",
        name: "sk",
        reason: "Invalid secret key bytes.",
      );
    }
    // final pk = MuSig2Utils.generatePublicKey(sk);
    final pubnonce = [
      ...Secp256k1Utils.geToBytes(rs1),
      ...Secp256k1Utils.geToBytes(rs2),
    ];
    final secnonce = [
      ...Secp256k1Utils.scalarToBytes(k1, validate: false),
      ...Secp256k1Utils.scalarToBytes(k2, validate: false),
      ...pk,
    ];
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
  List<int> nonceAgg(List<List<int>> pubnonces) {
    if (pubnonces.length < MuSig2Constants.minimumRequiredKey) {
      throw ArgumentException.invalidOperationArguments(
        "nonceAggConst",
        name: "pubnonces",
        reason: "Invalid public nonce length.",
      );
    }
    for (final i in pubnonces) {
      if (i.length != MuSig2Constants.pubnonceLength) {
        throw ArgumentException.invalidOperationArguments(
          "nonceAggConst",
          name: "pubnonces",
          reason: "Invalid public nonce length.",
        );
      }
    }
    final nonce = DynamicByteTracker();
    for (int i = 1; i < 3; i++) {
      Secp256k1Gej? rJ;
      for (final n in pubnonces) {
        final offset = (i - 1) * EcdsaKeysConst.pubKeyCompressedByteLen;
        final key = MuSig2UtilsConst.encodePointAsEvenConst(
          n.sublist(offset, offset + EcdsaKeysConst.pubKeyCompressedByteLen),
        );
        if (rJ != null) {
          Secp256k1.secp256k1GejAddGe(rJ, rJ, key);
        } else {
          rJ = Secp256k1Gej();
          Secp256k1.secp256k1GejSetGe(rJ, key);
        }
      }
      if (rJ!.infinity.toBool) {
        nonce.add(MuSig2Utils.zeroPk());
      } else {
        final e = Secp256k1Ge();
        Secp256k1.secp256k1GeSetGej(e, rJ);
        nonce.add(Secp256k1Utils.geToBytes(e));
      }
    }

    return nonce.toBytes();
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
      throw ArgumentException.invalidOperationArguments(
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
      msg = [
        1,
        ...BigintUtils.toBytes(BigInt.from(msg.length), length: 8),
        ...msg,
      ];
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
    final rs1 = Secp256k1Utils.secp256k1MultBase(scalar: k1);
    final rs2 = Secp256k1Utils.secp256k1MultBase(scalar: k2);
    final pubNonce = [
      ...Secp256k1Utils.geToBytes(rs1),
      ...Secp256k1Utils.geToBytes(rs2),
    ];
    final secNonce = [
      ...Secp256k1Utils.scalarToBytes(k1, clean: true),
      ...Secp256k1Utils.scalarToBytes(k2, clean: true),
      ...publicKey,
    ];
    return MuSig2Nonce(secnonce: secNonce, pubnonce: pubNonce);
  }

  @override
  List<int> sign({
    required List<int> secnonce,
    required List<int> sk,
    required MuSig2Session session,
    Secp256k1ECmultGenContext? context,
  }) {
    if (secnonce.length != MuSig2Constants.secnoncelength) {
      throw ArgumentException.invalidOperationArguments(
        "sign",
        name: "secnonce",
        reason: "Invalid secret nonce bytes length.",
        expecteLen: MuSig2Constants.secnoncelength,
      );
    }
    final values = MuSig2UtilsConst.decodeSessionConst(session);
    final r = Secp256k1Utils.loadPublicKey(values.r.toBytes());
    if (r == null) {
      throw ArgumentException.invalidOperationArguments(
        "signConst",
        name: "r",
        reason: "Invalid session public r public key.",
      );
    }
    final isOdd = Secp256k1.secp256k1FeIsOdd(r.y);
    final k1 = Secp256k1Utils.scalarFromBytes(
      secnonce.sublist(0, MuSig2Constants.xOnlyBytesLength),
    );
    final k2 = Secp256k1Utils.scalarFromBytes(
      secnonce.sublist(
        MuSig2Constants.xOnlyBytesLength,
        MuSig2Constants.xOnlyBytesLength * 2,
      ),
    );
    final k1Scalar = k1.clone();
    final k2Scalar = k2.clone();
    Secp256k1.secp256k1ScalarCondNegate(k1Scalar, isOdd);
    Secp256k1.secp256k1ScalarCondNegate(k2Scalar, isOdd);
    final d = Secp256k1Utils.scalarFromBytes(sk);
    context ??= Secp256k1Utils.initalizeBlindEcMultContext();
    Secp256k1Gej R = Secp256k1Gej();
    Secp256k1.secp256k1ECmultGen(context, R, d);
    Secp256k1Ge mid1 = Secp256k1Utils.secp256k1MultBase(
      scalar: d,
      context: context,
    );
    // Secp256k1.secp256k1GeSetGej(mid1, R);
    final pkBytes = Secp256k1Utils.secp256k1ECkeyPubkeySerialize(mid1, true);
    if (pkBytes == null) {
      throw ArgumentException.invalidOperationArguments(
        "sign",
        name: "sk",
        reason: "Invalid secret key.",
      );
    }
    final pkOffset = MuSig2Constants.xOnlyBytesLength * 2;
    if (!BytesUtils.bytesEqualConst(
      secnonce.sublist(
        pkOffset,
        pkOffset + EcdsaKeysConst.pubKeyCompressedByteLen,
      ),
      pkBytes,
    )) {
      throw ArgumentException.invalidOperationArguments(
        "sign",
        reason: "Missmatch between secret key and public key.",
      );
    }
    final a = MuSig2Utils.getSessionKeyAggCoeffConst(
      session: session,
      pkBytes: pkBytes,
    );
    final aggPk = Secp256k1Utils.loadPublicKey(values.publicKey.toBytes());
    if (aggPk == null) {
      throw ArgumentException.invalidOperationArguments(
        "sign",
        reason: "Invalid agg public key.",
      );
    }
    Secp256k1Scalar g = Secp256k1Const.secp256k1ScalarOne.clone();
    if (Secp256k1.secp256k1FeIsOdd(aggPk.y) != 0) {
      Secp256k1.secp256k1ScalarNegate(g, g);
    }
    Secp256k1Scalar gcc = Secp256k1Utils.scalarFromBytes(values.gacc);
    Secp256k1Scalar b = Secp256k1Utils.scalarFromBytes(values.b);
    Secp256k1Scalar e = Secp256k1Utils.scalarFromBytes(values.e);
    Secp256k1.secp256k1ScalarMul(g, gcc, g);
    Secp256k1.secp256k1ScalarMul(d, g, d);
    Secp256k1Scalar s1 = Secp256k1Scalar();
    Secp256k1Scalar s2 = Secp256k1Scalar();
    Secp256k1.secp256k1ScalarMul(s1, b, k2Scalar);
    Secp256k1.secp256k1ScalarAdd(s1, s1, k1Scalar);
    Secp256k1.secp256k1ScalarMul(s2, e, a);
    Secp256k1.secp256k1ScalarMul(s2, s2, d);
    Secp256k1.secp256k1ScalarAdd(s1, s1, s2);

    if (Secp256k1.secp256k1ScalarIsZero(s1).toBool) {
      throw const CryptoSignException(
        'Signing failed due to generate signature scalar.',
      );
    }
    final rS1 = Secp256k1Utils.generatePublicKeyBlind(scalar: k1);
    final rS2 = Secp256k1Utils.generatePublicKeyBlind(scalar: k2);
    if (rS1 == null || rS2 == null) {
      throw const CryptoSignException(
        'Signing failed due to generate pubnonce.',
      );
    }
    final signature = Secp256k1Utils.scalarToBytes(
      s1,
      clean: true,
      validate: false,
    );
    final List<int> pubnonce = [...rS1, ...rS2];
    final verify = partialSigVerify(
      signature: signature,
      pubnonce: pubnonce,
      pk: pkBytes,
      session: session,
    );
    if (!verify) {
      throw CryptoSignException.signatureVerificationFailed;
    }
    return signature;
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
