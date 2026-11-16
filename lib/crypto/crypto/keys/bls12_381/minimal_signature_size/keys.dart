import 'dart:typed_data';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/api/api.dart';
import 'package:blockchain_utils/crypto/crypto/group/group.dart';
import 'package:blockchain_utils/crypto/crypto/keys/bls12_381/minimal_signature_size/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/bls12_381/minimal_signature_size/verify_signing.dart';
import 'package:blockchain_utils/crypto/crypto/keys/bls12_381/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/core/i_keys.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/encoding/der/der.dart';

import 'package:blockchain_utils/crypto/crypto/keys/utils/ecdsa.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exceptions.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';

/// BLS12-381 min-signature-size scheme constants (keys in G2, signatures in G1).
class Bls12G2KeyConst {
  static const int privKeyByteLen = 32;
  static const int compressedPubKeyLength = 96;
  static const int uncompressedPubKeyLength = 192;
}

/// Min-signature-size public key -- mirror of [Bls12G1PublicKey], but the
/// point lives in **G2** (compressed = 96 bytes, vs. 48 for G1).
class Bls12G2PublicKey extends IBlsMinSigVerificationKey
    with Equality
    implements IPublicKey<Bls12G2VerifiyingParams> {
  final BuBytes keyBytes;
  Bls12G2PublicKey._(this.keyBytes);

  // Live point, parsed on demand from [keyBytes].
  // NOTE: every access re-parses (full validation); compute-heavy
  // call sites will be converted to bytes-APIs next phase.
  // G2Projective get point => G2Projective.fromBytes(keyBytes);

  /// Decodes a compressed or uncompressed G2 public key. Same big-endian /
  /// zkcrypto-compatible point encoding as G1 -- see the note on
  /// [Bls12G1PublicKey.fromBytes].
  factory Bls12G2PublicKey.fromBytes(List<int> keyBytes) {
    if (keyBytes.length != Bls12G2KeyConst.compressedPubKeyLength &&
        keyBytes.length != Bls12G2KeyConst.uncompressedPubKeyLength) {
      throw CoreErrors.invalidOperationArguments(
        "Bls12G2PublicKey",
        name: "keyBytes",
        reason: "Invalid public key bytes length.",
      );
    }
    final normalized = normalizePublicKey(keyBytes);
    if (normalized == null) {
      throw CoreErrors.invalidOperationArguments(
        "Bls12G2PublicKey",
        name: "keyBytes",
        reason: "Invalid public key bytes.",
      );
    }
    return Bls12G2PublicKey._(normalized);
  }

  /// Validates 96/192-byte [keyBytes] through the backend signing API and
  /// returns its canonical 96-byte compressed base encoding, or null when
  /// invalid (bad prefix, range, curve membership, or identity). Single
  /// source of truth for key parsing.
  static BuBytes? normalizePublicKey(List<int> keyBytes) {
    return blockchainUtils.api.signing.bls.normalizeG2PublicKey(keyBytes);
  }

  factory Bls12G2PublicKey.fromDer(List<int> keyBytes) {
    final raw = DerCodec.decodeBls12381PublicKeySpki(keyBytes);
    return Bls12G2PublicKey.fromBytes(raw);
  }

  @override
  CryptoKeyType get type => CryptoKeyType.bls12G2;

  static bool isValidBytes(List<int> keyBytes) {
    return normalizePublicKey(keyBytes) != null;
  }

  /// Checks whether [keyBytes] has a valid length for the given [encoding].
  ///
  /// This check validates only the key length and does not verify whether
  /// [keyBytes] represents a valid public key.
  static bool isValidKeyEncoding(
    List<int> keyBytes,
    CryptoKeyEncoding encoding,
  ) {
    return switch (encoding) {
      CryptoKeyEncoding.base
          when keyBytes.length == Bls12G2KeyConst.compressedPubKeyLength =>
        true,
      CryptoKeyEncoding.uncompressed
          when keyBytes.length == Bls12G2KeyConst.uncompressedPubKeyLength =>
        true,
      _ => false,
    };
  }

  @override
  BuBytes toBytes({CryptoKeyEncoding mode = CryptoKeyEncoding.base}) {
    if (mode == CryptoKeyEncoding.base) return keyBytes;
    return CryptoKeysUtils.ensureSupportPubKeyMode(
      mode: mode,
      type: type,
      onModeBytes:
          (mode) => switch (mode) {
            CryptoKeyEncoding.base => keyBytes.cloneBytes(),
            CryptoKeyEncoding.uncompressed => G2Projective.fromBytes(
              keyBytes,
            ).toBytes(mode: mode),
          },
    );
  }

  BuBytes toDer({CryptoKeyEncoding mode = CryptoKeyEncoding.base}) {
    return DerCodec.encodeBls12381PublicKeySpki(toBytes(mode: mode));
  }

  @override
  List<dynamic> get variables => [keyBytes];
}

/// Min-signature-size private key -- mirror of [Bls12G1PrivateKey]. Only
/// the public-key line changes: `G2Projective.generator * sk` instead of
/// `G1Projective.generator * sk`. All the scalar byte-encoding notes on
/// [Bls12G1PrivateKey] (IETF big-endian in/out, LE internally via
/// [JubJubFq]) apply unchanged -- `sk` is still an element of Fr regardless
/// of which group the public key is computed in.
class Bls12G2PrivateKey extends IBlsMinSigSigningKey<Bls12G2PublicKey>
    with Equality
    implements
        IPrivateKey<Bls12G2Signature, Bls12SigningParams, Bls12G2PublicKey> {
  final SecretBytes sk;
  @override
  final Bls12G2PublicKey publicKey;
  Bls12G2PrivateKey._(this.sk, this.publicKey);

  factory Bls12G2PrivateKey.fromSk(JubJubFq sk) {
    final skBytes = sk.toBytes(endian: Endian.big);
    try {
      final mult = blockchainUtils.api.g2.multBase(skBytes);
      final point = G2Projective.fromBytes(mult);
      return Bls12G2PrivateKey._(
        SecretBytes(skBytes),
        Bls12G2PublicKey.fromBytes(point.toBytes()),
      );
    } finally {
      skBytes.forceZero();
    }
  }

  factory Bls12G2PrivateKey.fromBytes(List<int> keyBytes) {
    if (keyBytes.length != Bls12G2KeyConst.privKeyByteLen) {
      throw CoreErrors.invalidOperationArguments(
        "Bls12G2PrivateKey",
        name: "keyBytes",
        reason: "Invalid secret key bytes length.",
      );
    }
    return Bls12G2PrivateKey.fromSk(
      JubJubFq.fromBytes(keyBytes, endian: Endian.big),
    );
  }

  factory Bls12G2PrivateKey.random() {
    final seed = QuickCrypto.generateRandom(length: 64);
    try {
      return Bls12G2PrivateKey.fromSk(JubJubFq.fromBytes64(seed));
    } finally {
      seed.forceZero();
    }
  }

  @override
  CryptoKeyType get type => CryptoKeyType.bls12G2;

  static bool isValidBytes(List<int> keyBytes) {
    if (keyBytes.length != Bls12G2KeyConst.privKeyByteLen) {
      return false;
    }
    try {
      Bls12G2PrivateKey.fromBytes(keyBytes);
      return true;
    } catch (_) {}
    return false;
  }

  @override
  List<dynamic> get variables => [publicKey];

  @override
  Bls12G2PublicKey verificationKey() => publicKey;

  void _ensureAlive(String operation) {
    if (sk.isZeroed) {
      throw CoreErrors.badState(
        operation,
        reason: "Private key has been disposed.",
      );
    }
  }

  @override
  JubJubFq scalar() {
    _ensureAlive("Bls12G2PrivateKey.scalar");
    return JubJubFq.fromBytes(sk, endian: Endian.big);
  }

  @override
  SecretBytes toBytes({SecretTransform? transform}) {
    _ensureAlive("Bls12G2PrivateKey.toBytes");
    return sk.cloneBytes(transform: transform);
  }

  @override
  void dispose() {
    sk.zero();
  }

  @override
  SecretBytes takeSecretKey() {
    _ensureAlive("Bls12G2PrivateKey.takeSecretKey");
    return sk;
  }
}
