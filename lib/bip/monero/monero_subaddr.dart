import 'dart:typed_data';
import 'package:blockchain_utils/bip/ecc/keys/ed25519_monero_keys.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/bip/address/xmr_addr.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/utils/ed25519_utils.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/curve/curves.dart';

/// A class containing constants related to Monero subaddresses.
class MoneroSubaddressConst {
  /// Prefix for Monero subaddresses.
  ///
  /// Monero subaddresses typically start with the byte sequence [83, 117, 98, 65, 100, 100, 114, 0].
  static const subaddrPrefix = [83, 117, 98, 65, 100, 100, 114, 0];

  /// Maximum allowed index for a Monero subaddress.
  ///
  /// Monero subaddresses use a 32-bit unsigned integer for indexing, and this constant
  /// represents the maximum valid index.
  static const subaddrMaxIdx = 4294967295;

  /// Byte length of the index used for Monero subaddresses.
  ///
  /// Monero subaddress indices are typically represented using 4 bytes.
  static const subaddrIdxByteLen = 4;
}

class MoneroComputeKey {
  /// Public spend key
  final MoneroPublicKey pubSKey;

  /// Public view key
  final MoneroPublicKey pubVKey;

  /// private key
  final MoneroPrivateKey privateKey;

  const MoneroComputeKey(
      {required this.pubSKey, required this.pubVKey, required this.privateKey});
}

/// A class representing a Monero subaddress, which consists of private and public keys.
class MoneroSubaddress {
  /// Private view key
  final MoneroPrivateKey privVKey;

  /// Public spend key
  final MoneroPublicKey pubSKey;

  /// Public view key
  final MoneroPublicKey pubVKey;

  /// Constructor for creating a Monero subaddress.
  ///
  /// The constructor takes a private view key [privVKey] and a public spend key [pubSKey].
  /// Optionally, it can also accept a public view key [publicVkey] (defaulting to `null`).
  MoneroSubaddress(this.privVKey, this.pubSKey, [MoneroPublicKey? publicVkey])
      : pubVKey = publicVkey ?? privVKey.publicKey;

  /// Compute the subaddress keys based on minor and major indexes.
  ///
  /// This method calculates Monero subaddress keys using the provided [minorIndex] and [majorIdx].
  /// If the indexes are out of valid range, it throws an `ArgumentException`.
  /// It returns a tuple of subaddress public spend key and subaddress public view key.
  MoneroComputeKey computeKeys(int minorIndex, int majorIndex) {
    if (minorIndex < 0 || minorIndex > MoneroSubaddressConst.subaddrMaxIdx) {
      throw ArgumentException('Invalid minor index ($minorIndex)');
    }
    if (majorIndex < 0 || majorIndex > MoneroSubaddressConst.subaddrMaxIdx) {
      throw ArgumentException('Invalid major index ($majorIndex)');
    }

    if (minorIndex == 0 && majorIndex == 0) {
      return MoneroComputeKey(
          pubSKey: pubSKey, pubVKey: pubVKey, privateKey: privVKey);
    }

    final List<int> majorIdxBytes = IntUtils.toBytes(majorIndex,
        length: MoneroSubaddressConst.subaddrIdxByteLen,
        byteOrder: Endian.little);
    final List<int> minorIdxBytes = IntUtils.toBytes(minorIndex,
        length: MoneroSubaddressConst.subaddrIdxByteLen,
        byteOrder: Endian.little);

    final List<int> privVKeyBytes = privVKey.raw;

    final List<int> mBytes = QuickCrypto.keccack256Hash(List<int>.from([
      ...MoneroSubaddressConst.subaddrPrefix,
      ...privVKeyBytes,
      ...majorIdxBytes,
      ...minorIdxBytes
    ]));
    final List<int> secretKey = Ed25519Utils.scalarReduce(mBytes);
    final BigInt mInt =
        BigintUtils.fromBytes(secretKey, byteOrder: Endian.little);
    final newPoint = pubSKey.point + (Curves.generatorED25519 * mInt);

    final MoneroPublicKey subaddrPubSKey = MoneroPublicKey.fromPoint(newPoint);
    final MoneroPublicKey subaddrPubVKey = MoneroPublicKey.fromPoint(
        (subaddrPubSKey.point *
            BigintUtils.fromBytes(privVKey.raw, byteOrder: Endian.little)));
    final sKey = MoneroPrivateKey.fromBytes(secretKey);

    return MoneroComputeKey(
        pubSKey: subaddrPubSKey, pubVKey: subaddrPubVKey, privateKey: sKey);
  }

  /// Compute and encode Monero subaddress keys into a string representation.
  ///
  /// This method calculates the Monero subaddress keys using the provided [minorIndex]
  /// and [majorIndex] and encodes them into a string representation. It also takes the
  /// [netVer] parameter to specify the network version.
  ///
  /// It returns the encoded string representation of the subaddress keys.
  String computeAndEncodeKeys(
      int minorIndex, int majorIndex, List<int> netVer) {
    final keys = computeKeys(minorIndex, majorIndex);

    return XmrAddrEncoder().encodeKey(keys.pubSKey.compressed,
        {"pub_vkey": keys.pubVKey.compressed, "net_ver": netVer});
  }
}
