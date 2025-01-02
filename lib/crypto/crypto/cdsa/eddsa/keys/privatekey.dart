import 'dart:typed_data';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/compare/hash_code.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/curve/curves.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/eddsa/keys/publickey.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/point/edwards.dart';
import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';

/// Represents an EdDSA private key and provides methods for key operations.
class EDDSAPrivateKey {
  final EDPoint generator;
  final int baselen;

  /// immutable key bytes
  final List<int> key;
  final List<int>? _extendedKey;
  final BigInt secret;
  final EDDSAPublicKey publicKey;

  /// Retrieves the private key bytes.
  List<int> get privateKey => List<int>.from(key);

  EDDSAPrivateKey._(this.generator, this.baselen, List<int> privateKey,
      this.secret, List<int>? extendedKey)
      : key = privateKey.asImmutableBytes,
        _extendedKey = extendedKey?.asImmutableBytes,
        publicKey = EDDSAPublicKey(generator, (generator * secret).toBytes());

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
  ///   - ArgumentException: If the private key size is invalid.
  ///
  factory EDDSAPrivateKey(
    EDPoint generator,
    List<int> privateKey,
    HashFunc hashMethod,
  ) {
    final baselen = (generator.curve.p.bitLength + 1 + 7) ~/ 8;
    if (privateKey.length != baselen) {
      throw ArgumentException(
          'Incorrect size of private key, expected: $baselen bytes');
    }
    final extendedKey = hashMethod().update(privateKey).digest();
    final a = extendedKey.sublist(0, baselen);
    final prunedKey = _keyPrune(List<int>.from(a), generator);
    final secret = BigintUtils.fromBytes(prunedKey, byteOrder: Endian.little);
    return EDDSAPrivateKey._(
        generator, baselen, privateKey, secret, extendedKey.sublist(baselen));
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
  ///   - ArgumentException: If the private key size is invalid.
  ///
  factory EDDSAPrivateKey.fromKhalow(EDPoint generator, List<int> privateKey) {
    final baselen = (generator.curve.p.bitLength + 1 + 7) ~/ 8;
    if (privateKey.length < baselen) {
      throw ArgumentException(
          'Incorrect size of private key, expected: ${baselen * 2} bytes');
    }
    final List<int> privateKeyPart = privateKey.sublist(0, baselen);
    final List<int> extendedKey = privateKey.sublist(baselen);
    final secret =
        BigintUtils.fromBytes(privateKeyPart, byteOrder: Endian.little);
    return EDDSAPrivateKey._(
        generator, baselen, privateKeyPart, secret, extendedKey);
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
      throw const ArgumentException(
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
  List<int> sign(
    List<int> data,
    HashFunc hashMethod,
  ) {
    List<int> dom = List.empty();
    if (generator.curve == Curves.curveEd448) {
      dom = List<int>.from([...'SigEd448'.codeUnits, 0x00, 0x00]);
    }

    final r = BigintUtils.fromBytes(
        hashMethod()
            .update(List<int>.from([...dom, ..._extendedKey ?? [], ...data]))
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
    return List<int>.from([
      ...R,
      ...BigintUtils.toBytes(s, length: baselen, order: Endian.little)
    ]);
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
