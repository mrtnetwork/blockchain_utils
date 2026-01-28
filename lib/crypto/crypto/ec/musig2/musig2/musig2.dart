import 'package:blockchain_utils/bip/address/encoders.dart';
import 'package:blockchain_utils/bip/ecc/keys/ecdsa_keys.dart';
import 'package:blockchain_utils/crypto/crypto/ec/musig2/constants/const.dart';
import 'package:blockchain_utils/crypto/crypto/ec/musig2/exception/exception.dart';
import 'package:blockchain_utils/crypto/crypto/ec/musig2/musig2/base.dart';
import 'package:blockchain_utils/crypto/crypto/ec/musig2/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/ec/musig2/utils/utils.dart';
import 'package:blockchain_utils/crypto/crypto/ec/core/point.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exception/exception.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/signer/exception/signing_exception.dart';
import 'package:blockchain_utils/utils/binary/bytes_tracker.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';

class MuSig2 extends Musig2Bsae {
  const MuSig2();

  /// Aggregates public nonces for MuSig2
  @override
  List<int> nonceAgg(List<List<int>> pubnonces) {
    if (pubnonces.length < MuSig2Constants.minimumRequiredKey) {
      throw ArgumentException.invalidOperationArguments(
        "nonceAgg",
        name: "pubnonces",
        reason: "Invalid public nonce length.",
      );
    }
    for (final i in pubnonces) {
      if (i.length != MuSig2Constants.pubnonceLength) {
        throw ArgumentException.invalidOperationArguments(
          "nonceAgg",
          name: "pubnonces",
          reason: "Invalid public nonce length.",
          expecteLen: MuSig2Constants.pubnonceLength,
        );
      }
    }
    final nonce = DynamicByteTracker();
    for (int i = 1; i < 3; i++) {
      BaseProjectivePointNative? rJ;
      for (final n in pubnonces) {
        final offset = (i - 1) * EcdsaKeysConst.pubKeyCompressedByteLen;
        final key = MuSig2Utils.encodePointAsEven(
          n.sublist(offset, offset + EcdsaKeysConst.pubKeyCompressedByteLen),
        );
        if (rJ != null) {
          rJ = (rJ + key);
        } else {
          rJ = key;
        }
      }
      if (rJ!.isZero()) {
        nonce.add(MuSig2Utils.zeroPk());
      } else {
        nonce.add(rJ.toBytes());
      }
    }

    return nonce.toBytes();
  }

  /// Generates a MuSig2 nonce for signing
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
        expecteLen: EcdsaKeysConst.pubKeyCompressedByteLen,
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
    final k1 = MuSig2Utils.toScalarBigInt(
      MuSig2Utils.nonceHash(
        rand: rand,
        publicKey: publicKey,
        aggPk: aggPubKey,
        i: 0,
        messagePrefix: msg,
        extraIn: extra,
      ),
    );
    final k2 = MuSig2Utils.toScalarBigInt(
      MuSig2Utils.nonceHash(
        rand: rand,
        publicKey: publicKey,
        aggPk: aggPubKey,
        i: 1,
        messagePrefix: msg,
        extraIn: extra,
      ),
    );
    final rs1 = MuSig2Constants.generator * k1;
    final rs2 = MuSig2Constants.generator * k2;
    final pubNonce = [...rs1.toBytes(), ...rs2.toBytes()];
    final secNonce = [
      ...BigintUtils.toBytes(k1),
      ...BigintUtils.toBytes(k2),
      ...publicKey,
    ];
    return MuSig2Nonce(secnonce: secNonce, pubnonce: pubNonce);
  }

  /// Aggregates public keys for MuSig2
  @override
  MuSig2KeyAggContext aggPublicKeys({required List<List<int>> keys}) {
    return MuSig2Utils.aggPublicKeys(keys: keys);
  }

  /// Generates a MuSig2 partial signature
  @override
  List<int> sign({
    required List<int> secnonce,
    required List<int> sk,
    required MuSig2Session session,
  }) {
    if (secnonce.length != MuSig2Constants.secnoncelength) {
      throw ArgumentException.invalidOperationArguments(
        "sign",
        name: "secnonce",
        reason: "Invalid secret nonce bytes length.",
        expecteLen: MuSig2Constants.secnoncelength,
      );
    }
    final values = MuSig2Utils.decodeSession(session);
    BigInt k1 = BigintUtils.fromBytes(
      secnonce.sublist(0, MuSig2Constants.xOnlyBytesLength),
    );
    BigInt k2 = BigintUtils.fromBytes(
      secnonce.sublist(
        MuSig2Constants.xOnlyBytesLength,
        MuSig2Constants.xOnlyBytesLength * 2,
      ),
    );
    if (k1 <= BigInt.zero || k1 >= MuSig2Constants.order) {
      throw ArgumentException.invalidOperationArguments(
        "sign",
        name: "secnonce",
        reason: "Invalid secret nonce.",
      );
    }
    if (k2 <= BigInt.zero || k2 >= MuSig2Constants.order) {
      throw ArgumentException.invalidOperationArguments(
        "sign",
        name: "secnonce",
        reason: "Invalid secret nonce.",
      );
    }
    BigInt kE1 = k1;
    BigInt kE2 = k2;
    if (values.r.isOdd) {
      kE1 = MuSig2Constants.order - k1;
      kE2 = MuSig2Constants.order - k2;
    }

    BigInt d = BigintUtils.fromBytes(sk);
    if (d <= BigInt.zero || d >= MuSig2Constants.order) {
      throw ArgumentException.invalidOperationArguments(
        "sign",
        name: "sk",
        reason: "Invalid secret key.",
      );
    }
    final p = MuSig2Constants.generator * d;
    final pkBytes = p.toBytes();
    final pkOffset = MuSig2Constants.xOnlyBytesLength * 2;
    if (!BytesUtils.bytesEqual(
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
    final a = MuSig2Utils.getSessionKeyAggCoeff(session: session, pk: p);
    BigInt g = BigInt.one;
    if (values.publicKey.isOdd) {
      g = MuSig2Constants.order - BigInt.one;
    }
    d = g * values.gaccAsInteger * d % MuSig2Constants.order;
    final s =
        (kE1 + values.bAsInteger * kE2 + values.eAsInteger * a * d) %
        MuSig2Constants.order;
    final sig = BigintUtils.toBytes(s).toImutableBytes;
    final rS1 = MuSig2Constants.generator * k1;
    final rS2 = MuSig2Constants.generator * k2;
    final List<int> pubnonce = [...rS1.toBytes(), ...rS2.toBytes()];
    final verify = partialSigVerify(
      signature: sig,
      pubnonce: pubnonce,
      pk: pkBytes,
      session: session,
    );
    if (!verify) {
      throw CryptoSignException.signatureVerificationFailed;
    }
    return sig;
  }

  /// Generates a deterministic MuSig2 signature
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
    final aggPk = MuSig2Utils.keyAggAndTweak(
      publicKeys: publicKeys,
      tweaks: tweaks,
    );
    final aggPkX = aggPk.xOnly().asImmutableBytes;
    final k1 = MuSig2Utils.toScalarBigInt(
      MuSig2Utils.deterministicNonceHash(
        sk: rand,
        aggotherNonce: aggotherNonce,
        aggPk: aggPkX,
        i: 0,
        msg: msg,
      ),
    );
    final k2 = MuSig2Utils.toScalarBigInt(
      MuSig2Utils.deterministicNonceHash(
        sk: rand,
        aggotherNonce: aggotherNonce,
        aggPk: aggPkX,
        i: 1,
        msg: msg,
      ),
    );

    if (k1 == BigInt.zero || k2 == BigInt.zero) {
      throw MuSig2Exception("Derive nonce hash failed.");
    }
    final rs1 = MuSig2Constants.generator * k1;
    final rs2 = MuSig2Constants.generator * k2;
    final pk = MuSig2Utils.generatePublicKey(sk);
    final pubnonce = [...rs1.toBytes(), ...rs2.toBytes()];
    final secnonce =
        [
          ...BigintUtils.toBytes(k1),
          ...BigintUtils.toBytes(k2),
          ...pk,
        ].asImmutableBytes;
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
  MuSig2KeyAggContext keyAggAndTweak({
    required List<List<int>> publicKeys,
    required List<MuSig2Tweak> tweaks,
  }) {
    return MuSig2Utils.keyAggAndTweak(publicKeys: publicKeys, tweaks: tweaks);
  }
}
