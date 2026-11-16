import 'dart:typed_data';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/api/api.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/helper.dart';

import 'package:blockchain_utils/chain/address/neworks/others/xmr_addr.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/binary/src/binary_operation.dart';
import 'package:blockchain_utils/crypto/crypto/keys/ed25519/ed25519.dart';

/// A class containing constants related to Monero subaddresses.
class MoneroSubaddressConst {
  /// Prefix for Monero subaddresses.
  static const subaddrPrefix = [83, 117, 98, 65, 100, 100, 114, 0];

  /// Maximum allowed index for a Monero subaddress.
  static const subaddrMaxIdx = BinaryOps.maxUint32;

  /// Byte length of the index used for Monero subaddresses.
  static const subaddrIdxByteLen = 4;
}

class MoneroComputeKey {
  /// Public spend key
  final ED25519MoneroPublicKey pubSKey;

  /// Public view key
  final ED25519MoneroPublicKey pubVKey;

  /// private key
  final ED25519MoneroPrivateKey privateKey;

  const MoneroComputeKey({
    required this.pubSKey,
    required this.pubVKey,
    required this.privateKey,
  });
}

/// A class representing a Monero subaddress, which consists of private and public keys.
class MoneroSubaddress {
  /// Private view key
  final ED25519MoneroPrivateKey privVKey;

  /// Public spend key
  final ED25519MoneroPublicKey pubSKey;

  /// Public view key
  final ED25519MoneroPublicKey pubVKey;

  /// Constructor for creating a Monero subaddress.
  ///
  /// The constructor takes a private view key [privVKey] and a public spend key [pubSKey].
  /// Optionally, it can also accept a public view key [publicVkey] (defaulting to `null`).
  MoneroSubaddress(
    this.privVKey,
    this.pubSKey, [
    ED25519MoneroPublicKey? publicVkey,
  ]) : pubVKey = publicVkey ?? privVKey.publicKey;

  /// Compute the subaddress keys based on minor and major indexes.
  MoneroComputeKey computeKeys(int minorIndex, int majorIndex) {
    if (minorIndex < 0 || minorIndex > MoneroSubaddressConst.subaddrMaxIdx) {
      throw CoreErrors.invalidOperationArguments(
        "computeKeys",
        name: "minorIndex",
        reason: "Invalid minor index.",
      );
    }
    if (majorIndex < 0 || majorIndex > MoneroSubaddressConst.subaddrMaxIdx) {
      throw CoreErrors.invalidOperationArguments(
        "computeKeys",
        name: "majorIndex",
        reason: "Invalid major index.",
      );
    }

    if (minorIndex == 0 && majorIndex == 0) {
      return MoneroComputeKey(
        pubSKey: pubSKey,
        pubVKey: pubVKey,
        privateKey: privVKey,
      );
    }

    final List<int> majorIdxBytes = majorIndex.toBytes(
      length: MoneroSubaddressConst.subaddrIdxByteLen,
      byteOrder: Endian.little,
    );
    final List<int> minorIdxBytes = minorIndex.toBytes(
      length: MoneroSubaddressConst.subaddrIdxByteLen,
      byteOrder: Endian.little,
    );

    // final List<int> privVKeyBytes = privVKey.raw;
    return privVKey.toBytes().useValue((sk) {
      final List<int> mBytes = QuickCrypto.keccak256Hash([
        ...MoneroSubaddressConst.subaddrPrefix,
        ...sk,
        ...majorIdxBytes,
        ...minorIdxBytes,
      ]);
      final List<int> secretKey = blockchainUtils.api.ed25519.scReduce(mBytes);
      final mult = blockchainUtils.api.ed25519.multBase(secretKey);
      final newPoint = blockchainUtils.api.ed25519.add(mult, pubSKey.keyBytes);
      final ED25519MoneroPublicKey subaddrPubSKey =
          ED25519MoneroPublicKey.fromBytes(newPoint);
      final subaddrPubVKeyPoint = blockchainUtils.api.ed25519.mult(
        sk,
        newPoint,
      );
      final ED25519MoneroPublicKey subaddrPubVKey =
          ED25519MoneroPublicKey.fromBytes(subaddrPubVKeyPoint);

      final sKey = ED25519MoneroPrivateKey.fromBytes(secretKey);
      return MoneroComputeKey(
        pubSKey: subaddrPubSKey,
        pubVKey: subaddrPubVKey,
        privateKey: sKey,
      );
    }, zero: true);
  }

  /// Compute and encode Monero subaddress keys into a string representation.
  ///
  /// This method calculates the Monero subaddress keys using the provided [minorIndex]
  /// and [majorIndex] and encodes them into a string representation. It also takes the
  /// [netVer] parameter to specify the network version.
  ///
  /// It returns the encoded string representation of the subaddress keys.
  String computeAndEncodeKeys(
    int minorIndex,
    int majorIndex,
    List<int> netVer,
  ) {
    final keys = computeKeys(minorIndex, majorIndex);
    return XmrAddrEncoder().encodeKey(
      keys.pubSKey.toBytes(),
      pubVKey: keys.pubVKey.toBytes(),
      netVersion: netVer,
    );
  }
}
