import 'dart:typed_data';

import 'package:blockchain_utils/numbers/bigint_utils.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/curve/curves.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/eddsa/publickey.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/point/edwards.dart';
import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:blockchain_utils/compare/compare.dart';

/// Represents an EdDSA private key and provides methods for key operations.
class EDDSAPrivateKey {
  final EDPoint generator;
  final int baselen;
  late final List<int> _privateKey;
  late final List<int> _h;
  EDDSAPublicKey? _publicKey;
  late final BigInt _s;
  final bool isKhalow;

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
  ///   - ArgumentError: If the private key size is invalid.
  ///
  EDDSAPrivateKey(
    this.generator,
    List<int> privateKey,
    SerializableHash Function() hashMethod,
  )   : baselen = (generator.curve.p.bitLength + 1 + 7) ~/ 8,
        isKhalow = false {
    if (privateKey.length != baselen) {
      throw ArgumentError(
          'Incorrect size of private key, expected: $baselen bytes');
    }

    _privateKey = List<int>.from(privateKey);
    _h = hashMethod().update(privateKey).digest();
    final a = _h.sublist(0, baselen);
    final prunedKey = _keyPrune(List<int>.from(a));
    _s = BigintUtils.fromBytes(prunedKey, byteOrder: Endian.little);
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
  ///   - ArgumentError: If the private key size is invalid.
  ///
  EDDSAPrivateKey.fromKhalow(
    this.generator,
    List<int> privateKey,
  )   : baselen = (generator.curve.p.bitLength + 1 + 7) ~/ 8,
        isKhalow = true {
    if (privateKey.length != baselen) {
      throw ArgumentError(
          'Incorrect size of private key, expected: $baselen bytes');
    }
    _privateKey = privateKey;
    _s = BigintUtils.fromBytes(_privateKey, byteOrder: Endian.little);
  }

  /// Retrieves the private key bytes.
  List<int> get privateKey => List<int>.from(_privateKey);

  @override
  bool operator ==(Object other) {
    if (other is EDDSAPrivateKey) {
      return generator.curve == other.generator.curve &&
          bytesEqual(_privateKey, other._privateKey);
    }
    return false;
  }

  /// Prunes the key to achieve improved security.
  List<int> _keyPrune(List<int> key) {
    final h = generator.curve.cofactor();
    int hLog;
    if (h == BigInt.from(4)) {
      hLog = 2;
    } else if (h == BigInt.from(8)) {
      hLog = 3;
    } else {
      throw ArgumentError('Only cofactor 4 and 8 curves are supported');
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

  /// Retrieves the public key associated with this private key.
  EDDSAPublicKey publicKey() {
    if (_publicKey != null) {
      return _publicKey!;
    }
    final publicPoint = generator * _s;
    _publicKey ??= EDDSAPublicKey(generator, publicPoint.toBytes(),
        publicPoint: publicPoint);
    return _publicKey!;
  }

  /// Signs the provided data using this private key.
  List<int> sign(
    List<int> data,
    SerializableHash Function() hashMethod,
  ) {
    final A = publicKey().publicKey();
    final prefix = _h.sublist(baselen);
    List<int> dom = List.empty();
    if (generator.curve == Curves.curveEd448) {
      dom = List<int>.from([...'SigEd448'.codeUnits, 0x00, 0x00]);
    }

    final r = BigintUtils.fromBytes(
        hashMethod()
            .update(List<int>.from([...dom, ...prefix, ...data]))
            .digest(),
        byteOrder: Endian.little);
    final R = (generator * r).toBytes();

    BigInt k = BigintUtils.fromBytes(
        hashMethod()
            .update(List<int>.from([...dom, ...R, ...A, ...data]))
            .digest(),
        byteOrder: Endian.little);

    k %= generator.order!;
    final s = (r + k * _s) % generator.order!;
    return List<int>.from([
      ...R,
      ...BigintUtils.toBytes(s, length: baselen, order: Endian.little)
    ]);
  }

  @override
  int get hashCode => _privateKey.hashCode ^ generator.hashCode;
}
