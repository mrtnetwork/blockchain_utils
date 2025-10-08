import 'dart:typed_data';
import 'package:blockchain_utils/crypto/crypto/cdsa/utils/ed25519.dart';
import 'package:blockchain_utils/crypto/crypto/exception/exception.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/curve/curves.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/point/edwards.dart';
import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:blockchain_utils/utils/utils.dart';

/// Represents an EdDSA public key in the Edwards curve format.
class EDDSAPublicKey {
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
      this.generator, List<int> _encoded, this.baselen, this._point)
      : _encoded = _encoded.asImmutableBytes;

  /// Creates an EdDSA public key from a generator, encoded public key bytes, and an optional public point.
  ///
  /// This constructor initializes an EdDSA public key using the provided generator,
  /// encoded public key bytes, and an optional public point. It calculates the length
  /// of the base data and ensures that the size of the encoded public key matches the
  /// expected size based on the generator's curve. If no public point is provided,
  /// the constructor attempts to create one from the encoded public key bytes.
  ///
  /// Parameters:
  ///   - generator: The generator point associated with this public key.
  ///   - publicKey: The encoded form of the public key as bytes.
  ///   - publicPoint: An optional Edwards curve point (if already available).
  ///
  /// Throws:
  ///   - CryptoException: If the size of the encoded public key does not match the
  ///     expected size based on the generator's curve.
  ///
  /// Details:
  ///   - The constructor performs initialization and validation of the public key
  ///     components. It ensures that the encoded public key's size matches the
  ///     expected size for the associated curve.
  ///   - If the public point is not provided, the constructor attempts to create
  ///     it from the encoded public key bytes.
  ///
  /// Note: This constructor is used to create EdDSA public keys from the generator
  ///       and encoded public key bytes, making them ready for cryptographic operations.
  ///       The public point can be optionally provided if it is already available.
  factory EDDSAPublicKey(EDPoint generator, List<int> publicKey) {
    return EDDSAPublicKey.fromPoint(generator, Ed25519Utils.asPoint(publicKey));
  }

  /// Creates an EdDSA public key from a generator and an existing public point.
  ///
  /// This constructor initializes an EdDSA public key using the provided generator
  /// and an existing public point. It calculates the length of the base data and ensures
  /// that the size of the encoded public key bytes extracted from the public point
  /// matches the expected size based on the generator's curve.
  ///
  /// Parameters:
  ///   - generator: The generator point associated with this public key.
  ///   - publicPoint: An existing Edwards curve public point.
  ///
  /// Throws:
  ///   - CryptoException: If the size of the encoded public key extracted from the public
  ///     point does not match the expected size based on the generator's curve.
  ///
  /// Details:
  ///   - The constructor initializes the public key using an existing public point,
  ///     and it calculates the base data length and validates the size of the
  ///     encoded public key bytes.
  ///
  /// Note: This constructor is used when you have an existing public point and want
  ///       to create an EdDSA public key from it. It performs necessary validation
  ///       and prepares the public key for cryptographic operations.
  factory EDDSAPublicKey.fromPoint(
    EDPoint generator,
    EDPoint publicPoint,
  ) {
    final int baselen = (generator.curve.p.bitLength + 1 + 7) ~/ 8;
    final pubkeyBytes = publicPoint.toBytes();
    if (pubkeyBytes.length != baselen) {
      throw CryptoException(
          'Incorrect size of the public key, expected: $baselen bytes');
    }
    return EDDSAPublicKey._(generator, pubkeyBytes, baselen, publicPoint);
  }

  @override
  bool operator ==(other) {
    if (other is EDDSAPublicKey) {
      if (identical(this, other)) return true;
      final equal = generator.curve == other.generator.curve &&
          BytesUtils.bytesEqual(_encoded, other._encoded);
      return equal;
    }
    return false;
  }

  /// Retrieves the public key as an Edwards curve point.
  EDPoint get point => _point;

  /// Retrieves the public key as an Edwards curve point.
  EDPoint publicPoint() => _point;

  /// Retrieves the encoded public key as bytes.
  List<int> toBytes() {
    return List<int>.from(_encoded);
  }

  /// Verifies a signature against the provided data using this public key.
  ///
  /// This method verifies an EdDSA signature against the given data using this
  /// public key. It checks the validity of the signature by comparing it to the
  /// data, the encoded public key, and the associated hash function.
  ///
  /// Parameters:
  ///   - data: The data to be verified.
  ///   - signature: The EdDSA signature bytes to be verified.
  ///   - hashMethod: A serializable hash function for data hashing.
  ///
  /// Returns:
  ///   - bool: True if the signature is valid; otherwise, false.
  ///
  /// Throws:
  ///   - CryptoException: If the signature length is invalid or if the signature is
  ///     found to be invalid during the verification process.
  ///
  /// Details:
  ///   - This method verifies the provided EdDSA signature by checking its length
  ///     and comparing it to the encoded public key, data, and a hash of the combined
  ///     values.
  ///   - It calculates a verification key 'R' and uses the hash function to compute
  ///     the scalar 'k' to confirm the signature's validity.
  ///
  /// Note: The 'verify' method is essential for verifying EdDSA signatures and ensuring
  ///       the authenticity and integrity of data.
  bool verify(
    List<int> data,
    List<int> signature,
    HashFunc hashMethod,
  ) {
    if (signature.length != 2 * baselen) {
      throw CryptoException(
          'Invalid signature length, expected: ${2 * baselen} bytes');
    }

    final R = EDPoint.fromBytes(
        curve: generator.curve, data: signature.sublist(0, baselen));
    final S = BigintUtils.fromBytes(signature.sublist(baselen),
        byteOrder: Endian.little);

    if (S >= generator.order!) {
      throw const CryptoException('Invalid signature');
    }

    List<int> dom = List.empty();

    if (generator.curve == Curves.curveEd448) {
      dom = List<int>.from([...'SigEd448'.codeUnits, 0x00, 0x00]);
    }
    final h = hashMethod();
    h.update(List<int>.from([...dom, ...R.toBytes(), ..._encoded, ...data]));
    final k = BigintUtils.fromBytes(h.digest(), byteOrder: Endian.little);
    if (generator * S != _point * k + R) {
      return false;
    }

    return true;
  }

  @override
  int get hashCode {
    return HashCodeGenerator.generateBytesHashCode(_encoded, [generator.curve]);
  }
}
