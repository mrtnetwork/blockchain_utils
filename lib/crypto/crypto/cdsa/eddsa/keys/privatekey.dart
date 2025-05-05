import 'dart:typed_data';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/crypto_ops/crypto_ops.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/utils/ed25519.dart';
import 'package:blockchain_utils/crypto/crypto/exception/exception.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/compare/hash_code.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/curve/curves.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/eddsa/keys/publickey.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/point/edwards.dart';
import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';

/// Represents an EdDSA private key and provides methods for key operations.
class EDDSAPrivateKey {
  final EDPoint generator;
  int get baselen => publicKey.generator.curve.baselen;

  /// immutable key bytes
  final List<int> key;
  final List<int> extendedKey;
  final BigInt secret;
  final EDDSAPublicKey publicKey;

  /// Retrieves the private key bytes.
  List<int> get privateKey => List<int>.from(key);

  EDDSAPrivateKey._(
      {required this.generator,
      required List<int> privateKey,
      required this.secret,
      EDDSAPublicKey? publicKey,
      required List<int> extendedKey})
      : key = privateKey.asImmutableBytes,
        extendedKey = extendedKey.asImmutableBytes,
        publicKey = publicKey ??
            EDDSAPublicKey(generator, (generator * secret).toBytes());
  factory EDDSAPrivateKey(
      {required EDPoint generator,
      required List<int> privateKey,
      required EllipticCurveTypes type}) {
    final int baselen = generator.curve.baselen;
    if (privateKey.length != generator.curve.baselen &&
        privateKey.length != generator.curve.baselen * 2) {
      throw CryptoException(
          'Incorrect size of private key, expected: $baselen or ${baselen * 2} bytes');
    }
    switch (type) {
      case EllipticCurveTypes.ed25519:
      case EllipticCurveTypes.ed25519Blake2b:
        if (privateKey.length != generator.curve.baselen) {
          throw CryptoException(
              'Incorrect size of private key, expected: $baselen bytes');
        }
        final extendedKey = switch (type) {
          EllipticCurveTypes.ed25519Blake2b =>
            BLAKE2b().update(privateKey).digest(),
          _ => SHA512().update(privateKey).digest()
        };
        final keyBytes = extendedKey.sublist(0, baselen);
        final prunedKey = _keyPrune(keyBytes, generator);
        final pubkey = Ed25519Utils.scalarMultBase(prunedKey);
        final secret =
            BigintUtils.fromBytes(prunedKey, byteOrder: Endian.little);
        return EDDSAPrivateKey._(
            generator: generator,
            privateKey: privateKey,
            publicKey: EDDSAPublicKey(generator, pubkey),
            secret: secret,
            extendedKey: extendedKey.sublist(baselen));
      case EllipticCurveTypes.ed25519Kholaw:
        final List<int> privateKeyPart = privateKey.sublist(0, baselen);
        final List<int> extendedKey = privateKey.sublist(baselen);
        final pubkey = Ed25519Utils.scalarMultBase(privateKeyPart);
        final secret =
            BigintUtils.fromBytes(privateKeyPart, byteOrder: Endian.little);
        return EDDSAPrivateKey._(
            generator: generator,
            privateKey: privateKeyPart,
            publicKey: EDDSAPublicKey(generator, pubkey),
            secret: secret,
            extendedKey: extendedKey);
      default:
        throw CryptoException("");
    }
  }

  /// Creates an EdDSA private key from a random value using a provided hash method.
  ///
  /// The private key is generated from the provided hash method and the provided
  /// random value. It prunes the key for improved security.
  ///
  /// Parameters:
  ///   - generator: The Edwards curve generator point.
  ///   - privateKey: The private key bytes.
  ///   - hashMethod: A serializable hash function for key generation.
  ///
  /// Throws:
  ///   - CryptoException: If the private key size is invalid.
  ///
  factory EDDSAPrivateKey.fromBytes(
      {required EDPoint generator,
      required List<int> privateKey,
      required HashFunc hashMethod}) {
    // final baselen = (generator.curve.baselen + 1 + 7) ~/ 8;
    final int baselen = generator.curve.baselen;
    if (privateKey.length != generator.curve.baselen) {
      throw CryptoException(
          'Incorrect size of private key, expected: $baselen bytes');
    }
    final extendedKey = hashMethod().update(privateKey).digest();
    final a = extendedKey.sublist(0, baselen);
    final prunedKey = _keyPrune(a, generator);
    final secret = BigintUtils.fromBytes(prunedKey, byteOrder: Endian.little);
    return EDDSAPrivateKey._(
        generator: generator,
        privateKey: privateKey,
        secret: secret,
        extendedKey: extendedKey.sublist(baselen));
  }

  /// Creates an EdDSA private key from a private key value for Khalow curves.
  ///
  /// This constructor is specifically used for Khalow curves where the private
  /// key is not pruned. It creates the private key from the provided private key value.
  ///
  /// Parameters:
  ///   - generator: The Edwards curve generator point.
  ///   - privateKey: The private key bytes for Khalow curves.
  ///
  /// Throws:
  ///   - CryptoException: If the private key size is invalid.
  ///
  factory EDDSAPrivateKey.fromKhalow(EDPoint generator, List<int> privateKey) {
    // final baselen = (generator.curve.p.bitLength + 1 + 7) ~/ 8;
    final baselen = generator.curve.baselen;
    assert(privateKey.length == baselen || privateKey.length == baselen * 2);
    if (privateKey.length < baselen) {
      throw CryptoException(
          'Incorrect size of private key, expected: ${baselen * 2} bytes');
    }
    final List<int> privateKeyPart = privateKey.sublist(0, baselen);
    final List<int> extendedKey = privateKey.sublist(baselen);
    final secret =
        BigintUtils.fromBytes(privateKeyPart, byteOrder: Endian.little);
    return EDDSAPrivateKey._(
        generator: generator,
        privateKey: privateKeyPart,
        secret: secret,
        extendedKey: extendedKey);
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
      throw const CryptoException(
          'Invalid private key. Only cofactor 4 and 8 curves are supported');
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
    List<int> dom = List.empty();
    if (generator.curve == Curves.curveEd448) {
      dom = List<int>.from([...'SigEd448'.codeUnits, 0x00, 0x00]);
    }
    final r = BigintUtils.fromBytes(
        hashMethod()
            .update(List<int>.from([...dom, ...extendedKey, ...data]))
            .digest(),
        byteOrder: Endian.little);
    final R = (generator * r).toBytes();
    BigInt k = BigintUtils.fromBytes(
        hashMethod()
            .update(
                List<int>.from([...dom, ...R, ...publicKey.toBytes(), ...data]))
            .digest(),
        byteOrder: Endian.little);

    k %= generator.order!;
    final s = (r + k * secret) % generator.order!;
    final signature = [
      ...R,
      ...BigintUtils.toBytes(s, length: baselen, order: Endian.little)
    ];
    if (publicKey.verify(data, signature, hashMethod)) {
      return signature;
    }
    throw const CryptoException(
        'The created signature does not pass verification.');
  }

  List<int> signConst(List<int> data, HashFunc hashMethod) {
    if (generator.curve != Curves.curveEd25519) {
      throw CryptoException(
          "Constant-time signing is only supported for Ed25519.");
    }
    final secBytes = BigintUtils.toBytes(secret,
        length: generator.curve.baselen, order: Endian.little);
    final hash =
        hashMethod().update(List<int>.from([...extendedKey, ...data])).digest();
    final rScalar = Ed25519Utils.scalarReduceConst(hash);
    final R = Ed25519Utils.scalarMultBase(rScalar);
    final kBytes = hashMethod()
        .update(List<int>.from([...R, ...publicKey.toBytes(), ...data]))
        .digest();
    List<int> s = Ed25519Utils.scalarReduceConst(kBytes);
    List<int> s2 = List.filled(32, 0);
    CryptoOps.scMulAdd(s2, s, secBytes, rScalar);
    CryptoOps.scReduce32Copy(s2, s2);
    if (Ed25519Utils.scIsZero(s) || Ed25519Utils.scIsZero(rScalar)) {
      throw CryptoException(
          "Invalid signature: scalar value is zero, which is not allowed in Ed25519 signing.");
    }
    final signature = [...R, ...s2];
    if (publicKey.verify(data, signature, hashMethod)) {
      return signature;
    }
    throw const CryptoException(
        'The created signature does not pass verification.');
  }

  @override
  bool operator ==(Object other) {
    if (other is EDDSAPrivateKey) {
      if (identical(this, other)) return true;
      return generator.curve == other.generator.curve &&
          BytesUtils.bytesEqual(key, other.key);
    }
    return false;
  }

  @override
  int get hashCode =>
      HashCodeGenerator.generateBytesHashCode(key, [generator.curve]);
}
