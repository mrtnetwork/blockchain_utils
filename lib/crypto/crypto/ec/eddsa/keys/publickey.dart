import 'dart:typed_data';
import 'package:blockchain_utils/crypto/crypto/ec/utils/ed25519.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/crypto/crypto/ec/curve/curves.dart';
import 'package:blockchain_utils/crypto/crypto/ec/extended/native/edwards.dart';
import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';

/// Represents an EdDSA public key in the Edwards curve format.
class EDDSAPublicKey with Equality {
  /// The generator point associated with this public key.
  final EDPoint generator;

  /// The encoded form of the public key.
  final List<int> _encoded;

  /// The length of the base data used in encoding.
  final int baselen;

  /// The Edwards curve point derived from the encoded public key.
  final EDPoint _point;

  /// immutable key
  List<int> get key => _encoded;

  EDDSAPublicKey._(
    this.generator,
    List<int> _encoded,
    this.baselen,
    this._point,
  ) : _encoded = _encoded.asImmutableBytes;

  /// Creates an EdDSA public key from a generator, encoded public key bytes, and an optional public point.
  ///
  /// Parameters:
  ///   - [generator]: The generator point associated with this public key.
  ///   - [publicKey]: The encoded form of the public key as bytes.
  ///
  /// Throws:
  ///   - CryptoException: If the size of the encoded public key does not match the
  ///     expected size based on the generator's curve.
  ///
  factory EDDSAPublicKey(EDPoint generator, List<int> publicKey) {
    return EDDSAPublicKey.fromPoint(generator, Ed25519Utils.asPoint(publicKey));
  }

  /// Creates an EdDSA public key from a generator and an existing public point.
  ///
  /// Parameters:
  ///   - [generator]: The generator point associated with this public key.
  ///   - [publicPoint]: An existing Edwards curve public point.
  ///
  /// Throws:
  ///   - [ArgumentException]: If the size of the encoded public key extracted from the public
  ///     point does not match the expected size based on the generator's curve.
  ///
  factory EDDSAPublicKey.fromPoint(EDPoint generator, EDPoint publicPoint) {
    final int baselen = (generator.curve.p.bitLength + 1 + 7) ~/ 8;
    final pubkeyBytes = publicPoint.toBytes();
    if (pubkeyBytes.length != baselen) {
      throw ArgumentException.invalidOperationArguments(
        "EDDSAPublicKey",
        name: "publicPoint",
        reason: "Invalid public key point.",
      );
    }
    return EDDSAPublicKey._(generator, pubkeyBytes, baselen, publicPoint);
  }

  /// Retrieves the public key as an Edwards curve point.
  EDPoint get point => _point;

  /// Retrieves the public key as an Edwards curve point.
  EDPoint publicPoint() => _point;

  /// Retrieves the encoded public key as bytes.
  List<int> toBytes() {
    return _encoded.clone();
  }

  /// Verifies a signature against the provided data using this public key.
  ///
  /// Parameters:
  ///   - [data]: The data to be verified.
  ///   - [signature]: The EdDSA signature bytes to be verified.
  ///   - [hashMethod]: A serializable hash function for data hashing.
  ///
  /// Throws:
  ///   - [ArgumentException]: If the signature length is invalid or if the signature is
  ///     found to be invalid during the verification process.
  ///
  bool verify(List<int> data, List<int> signature, CbHashFunc hashMethod) {
    final n = generator.order;
    if (n == null) {
      throw ArgumentException.invalidOperationArguments(
        "verify",
        name: "generator",
        reason: "Invalid curve generator.",
      );
    }
    if (signature.length != 2 * baselen) {
      throw ArgumentException.invalidOperationArguments(
        "verify",
        name: "signature",
        reason: "Invalid signature bytes length.",
      );
    }

    final R = EDPoint.fromBytes(
      curve: generator.curve,
      data: signature.sublist(0, baselen),
    );
    final S = BigintUtils.fromBytes(
      signature.sublist(baselen),
      byteOrder: Endian.little,
    );

    if (S >= n) {
      throw ArgumentException.invalidOperationArguments(
        "verify",
        name: "signature",
        reason: "Invalid signature bytes.",
      );
    }

    List<int> dom = List.empty();

    if (generator.curve == Curves.curveEd448) {
      dom = [...'SigEd448'.codeUnits, 0x00, 0x00];
    }
    final h = hashMethod();
    h.update([...dom, ...R.toBytes(), ..._encoded, ...data]);
    final k = BigintUtils.fromBytes(h.digest(), byteOrder: Endian.little);
    if (generator * S != _point * k + R) {
      return false;
    }

    return true;
  }

  @override
  List<dynamic> get variables => [key, generator.curve];
}
