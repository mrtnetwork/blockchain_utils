import 'dart:typed_data';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/crypto/crypto/ec/extended/crypto_ops/crypto_ops.dart';
import 'package:blockchain_utils/crypto/crypto/ec/utils/ed25519.dart';
import 'package:blockchain_utils/exception/exception/exception.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/crypto/crypto/ec/curve/curves.dart';
import 'package:blockchain_utils/crypto/crypto/ec/eddsa/keys/publickey.dart';
import 'package:blockchain_utils/crypto/crypto/ec/extended/native/edwards.dart';
import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:blockchain_utils/signer/exception/signing_exception.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';

/// Represents an EdDSA private key and provides methods for key operations.
class EDDSAPrivateKey with ConstantEquality<EDDSAPrivateKey> {
  final EDPoint generator;
  int get baselen => publicKey.generator.curve.baselen;

  /// immutable key bytes
  final List<int> key;
  final List<int> extendedKey;
  final BigInt secret;
  final EDDSAPublicKey publicKey;

  /// Retrieves the private key bytes.
  List<int> get privateKey => key.clone();

  EDDSAPrivateKey._({
    required this.generator,
    required List<int> privateKey,
    required this.secret,
    EDDSAPublicKey? publicKey,
    required List<int> extendedKey,
  }) : key = privateKey.asImmutableBytesConst,
       extendedKey = extendedKey.asImmutableBytesConst,
       publicKey =
           publicKey ??
           EDDSAPublicKey(generator, (generator * secret).toBytes());
  factory EDDSAPrivateKey({
    required EDPoint generator,
    required List<int> secretKey,
    required EllipticCurveTypes type,
  }) {
    final int baselen = generator.curve.baselen;
    if (secretKey.length != generator.curve.baselen &&
        secretKey.length != generator.curve.baselen * 2) {
      throw ArgumentException.invalidOperationArguments(
        "EDDSAPrivateKey",
        name: "secretKey",
        reason: "Invalid secret key bytes length.",
      );
    }
    switch (type) {
      case EllipticCurveTypes.ed25519:
      case EllipticCurveTypes.ed25519Blake2b:
        if (secretKey.length != generator.curve.baselen) {
          throw ArgumentException.invalidOperationArguments(
            "EDDSAPrivateKey",
            name: "secretKey",
            reason: "Invalid secret key bytes length.",
          );
        }
        final extendedKey = switch (type) {
          EllipticCurveTypes.ed25519Blake2b => BLAKE2b.hash(secretKey),
          _ => SHA512.hash(secretKey),
        };
        final keyBytes = extendedKey.sublist(0, baselen);
        final prunedKey = _keyPrune(keyBytes, generator);
        final pubkey = Ed25519Utils.scalarMultBase(prunedKey);
        final secret = BigintUtils.fromBytes(
          prunedKey,
          byteOrder: Endian.little,
        );
        return EDDSAPrivateKey._(
          generator: generator,
          privateKey: secretKey,
          publicKey: EDDSAPublicKey(generator, pubkey),
          secret: secret,
          extendedKey: extendedKey.sublist(baselen),
        );
      case EllipticCurveTypes.ed25519Kholaw:
        final List<int> privateKeyPart = secretKey.sublist(0, baselen);
        final List<int> extendedKey = secretKey.sublist(baselen);
        final pubkey = Ed25519Utils.scalarMultBase(privateKeyPart);
        final secret = BigintUtils.fromBytes(
          privateKeyPart,
          byteOrder: Endian.little,
        );
        return EDDSAPrivateKey._(
          generator: generator,
          privateKey: privateKeyPart,
          publicKey: EDDSAPublicKey(generator, pubkey),
          secret: secret,
          extendedKey: extendedKey,
        );
      default:
        throw ArgumentException.invalidOperationArguments(
          "EDDSAPrivateKey",
          reason: "Unsupported secret key algorithm.",
        );
    }
  }

  /// Creates an EdDSA private key from a random value using a provided hash method.
  ///
  /// Parameters:
  ///   - [generator]: The Edwards curve generator point.
  ///   - [privateKey]: The private key bytes.
  ///   - [hashMethod]: A serializable hash function for key generation.
  ///
  factory EDDSAPrivateKey.fromBytes({
    required EDPoint generator,
    required List<int> secretKey,
    required HashFunc hashMethod,
  }) {
    // final baselen = (generator.curve.baselen + 1 + 7) ~/ 8;
    final int baselen = generator.curve.baselen;
    if (secretKey.length != generator.curve.baselen) {
      throw ArgumentException.invalidOperationArguments(
        "EDDSAPrivateKey",
        reason: "Invalid secret key bytes length.",
      );
    }
    final extendedKey = hashMethod().update(secretKey).digest();
    final a = extendedKey.sublist(0, baselen);
    final prunedKey = _keyPrune(a, generator);
    final secret = BigintUtils.fromBytes(prunedKey, byteOrder: Endian.little);
    return EDDSAPrivateKey._(
      generator: generator,
      privateKey: secretKey,
      secret: secret,
      extendedKey: extendedKey.sublist(baselen),
    );
  }

  /// Creates an EdDSA private key from a private key value for Khalow curves.
  ///
  /// Parameters:
  ///   - [generator]: The Edwards curve generator point.
  ///   - [privateKey]: The private key bytes for Khalow curves.
  ///
  factory EDDSAPrivateKey.fromKhalow(EDPoint generator, List<int> secretKey) {
    final baselen = generator.curve.baselen;
    assert(secretKey.length == baselen || secretKey.length == baselen * 2);
    if (secretKey.length < baselen) {
      throw ArgumentException.invalidOperationArguments(
        "EDDSAPrivateKey",
        name: "secretKey",
        reason: "Invalid secret key bytes length.",
      );
    }
    final List<int> privateKeyPart = secretKey.sublist(0, baselen);
    final List<int> extendedKey = secretKey.sublist(baselen);
    final secret = BigintUtils.fromBytes(
      privateKeyPart,
      byteOrder: Endian.little,
    );
    return EDDSAPrivateKey._(
      generator: generator,
      privateKey: privateKeyPart,
      secret: secret,
      extendedKey: extendedKey,
    );
  }

  /// Prunes the key to achieve improved security.
  static List<int> _keyPrune(List<int> key, EDPoint generator) {
    final h = generator.curve.cofactor();
    int hLog;
    if (h == BigInt.from(4)) {
      hLog = 2;
    } else if (h == BigInt.from(8)) {
      hLog = 3;
    } else {
      throw ArgumentException.invalidOperationArguments(
        "EDDSAPrivateKey",
        reason: "Invalid secret key generator.",
      );
    }
    key[0] &= ~((1 << hLog) - 1);

    final l = generator.curve.p.bitLength;
    if (l % 8 == 0) {
      key[key.length - 1] = 0;
      key[key.length - 2] |= 0x80;
    } else {
      key[key.length - 1] =
          key[key.length - 1] & ((1 << (l % 8)) - 1) | (1 << (l % 8) - 1);
    }
    return key;
  }

  /// Signs the provided data using this private key.
  List<int> sign(List<int> data, HashFunc hashMethod) {
    final order = generator.order;
    if (order == null) {
      throw ArgumentException.invalidOperationArguments(
        "sign",
        reason: "Invalid curve generator.",
      );
    }
    List<int> dom = List.empty();
    if (generator.curve == Curves.curveEd448) {
      dom = [...'SigEd448'.codeUnits, 0x00, 0x00];
    }
    final r = BigintUtils.fromBytes(
      hashMethod().update([...dom, ...extendedKey, ...data]).digest(),
      byteOrder: Endian.little,
    );
    final R = (generator * r).toBytes();
    BigInt k = BigintUtils.fromBytes(
      hashMethod().update([
        ...dom,
        ...R,
        ...publicKey.toBytes(),
        ...data,
      ]).digest(),
      byteOrder: Endian.little,
    );

    k %= order;
    final s = (r + k * secret) % order;
    final signature = [
      ...R,
      ...BigintUtils.toBytes(s, length: baselen, order: Endian.little),
    ];
    if (publicKey.verify(data, signature, hashMethod)) {
      return signature;
    }
    throw CryptoSignException.signatureVerificationFailed;
  }

  List<int> signConst(List<int> data, HashFunc hashMethod) {
    if (generator.curve != Curves.curveEd25519) {
      throw const CryptoSignException(
        "Constant-time signing is only supported for Ed25519.",
      );
    }
    final secBytes = BigintUtils.toBytes(
      secret,
      length: generator.curve.baselen,
      order: Endian.little,
    );
    final hash = hashMethod().update([...extendedKey, ...data]).digest();
    final rScalar = Ed25519Utils.scalarReduceConst(hash);
    final R = Ed25519Utils.scalarMultBase(rScalar);
    final kBytes =
        hashMethod().update([...R, ...publicKey.toBytes(), ...data]).digest();
    List<int> s = Ed25519Utils.scalarReduceConst(kBytes);
    List<int> s2 = List.filled(32, 0);
    CryptoOps.scMulAdd(s2, s, secBytes, rScalar);
    CryptoOps.scReduce32Copy(s2, s2);
    if (Ed25519Utils.scIsZero(s) || Ed25519Utils.scIsZero(rScalar)) {
      throw const CryptoSignException(
        "ECDSA signing aborted. s generation failed.",
      );
    }
    final signature = [...R, ...s2];
    if (publicKey.verify(data, signature, hashMethod)) {
      return signature;
    }
    throw CryptoSignException.signatureVerificationFailed;
  }

  @override
  List<List<int>> get secretFields => [key];

  @override
  List<Object?> get publicFields => [publicKey];
}
