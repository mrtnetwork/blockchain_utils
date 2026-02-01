import 'dart:typed_data';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/zip32/exception/exception.dart';
import 'package:blockchain_utils/exception/exception/exception.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';
import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';

abstract class DiversifiedTransmissionKey with Equality {
  const DiversifiedTransmissionKey();
  List<int> toBytes();
}

/// Represents an 11-byte Zcash Orchard diversifier index.
class DiversifierIndex with Equality {
  final List<int> inner;
  DiversifierIndex(List<int> inner)
    : inner =
          inner
              .exc(
                operation: "DiversifierIndex",
                name: "sk",
                reason: "Invalid iversifier index bytes length.",
                length: 11,
              )
              .asImmutableBytes;
  factory DiversifierIndex.zero() {
    return DiversifierIndex(List<int>.filled(11, 0));
  }
  factory DiversifierIndex.fromBigInt(BigInt value) {
    if (value.bitLength > 88) {
      throw ArgumentException.invalidOperationArguments(
        "fromBigInt",
        reason: "Value is to large.",
      );
    }
    final toBytes = BigintUtils.toBytes(
      value.asU128,
      length: 16,
      order: Endian.little,
    );
    return DiversifierIndex(toBytes.sublist(0, 11));
  }
  factory DiversifierIndex.from(int value) {
    final toBytes = IntUtils.toBytes(
      value.asU32,
      length: 4,
      byteOrder: Endian.little,
    );
    return DiversifierIndex(List.filled(11, 0)..setAll(0, toBytes));
  }

  /// Returns the underlying bytes of the index.
  List<int> toBytes() {
    return inner.clone();
  }

  /// Returns a new DiversifierIndex incremented by 1; throws on overflow.
  DiversifierIndex increment() {
    final key = toBytes();
    for (int k = 0; k < 11; k++) {
      key[k] = (key[k] + 1).toU8;
      if (key[k] != 0) {
        return DiversifierIndex(key);
      }
    }
    throw Zip32Error("DiversifierIndex increment overflowed.");
  }

  /// Attempts to increment the index; returns null if overflow occurs.
  DiversifierIndex? tryIncrement() {
    try {
      return increment();
    } on Zip32Error {
      return null;
    }
  }

  /// Converts to a Bip32KeyIndex if the upper bytes are zero, otherwise null.
  Bip32KeyIndex? toBip32Index() {
    final part = inner.sublist(4);
    if (part.every((e) => e == 0)) {
      return Bip32KeyIndex.fromBytes(
        inner.sublist(0, 4),
        endian: Endian.little,
      );
    }
    return null;
  }

  /// Returns the index as a 32-bit integer.
  int toU32() => IntUtils.fromBytes(inner, byteOrder: Endian.little).asU32;

  /// Returns the index as a 128-bit integer.
  BigInt toU128() =>
      BigintUtils.fromBytes(inner, byteOrder: Endian.little).asU128;

  @override
  List<dynamic> get variables => [inner];
}

/// Represents a generic Shielded address with a transmission key and diversifier.
abstract class ShieldAddress<PKD extends DiversifiedTransmissionKey>
    with Equality {
  final PKD transmissionKey;
  final Diversifier diversifier;
  const ShieldAddress({
    required this.transmissionKey,
    required this.diversifier,
  });
  @override
  List<dynamic> get variables => [transmissionKey, diversifier];

  /// Returns the diversifier as bytes.
  List<int> toBytes();
}

class Diversifier with Equality {
  final List<int> inner;
  Diversifier(List<int> inner)
    : inner =
          inner
              .exc(
                length: 11,
                operation: "Diversifier",
                reason: "Invalid diversifier bytes length.",
              )
              .asImmutableBytes;

  List<int> toBytes() {
    return inner.clone();
  }

  @override
  List<dynamic> get variables => [inner];
}

/// Abstract base for an incoming viewing key that can derive shielded addresses.
abstract class IncomingViewingKey<ADDR extends ShieldAddress> with Equality {
  /// Returns the address at a given diversifier index.
  ADDR addressAt(DiversifierIndex index);

  /// Returns the address for a specific diversifier.
  ADDR address(Diversifier drivator);

  /// Returns the diversifier index corresponding to a given address.
  DiversifierIndex? diversifierIndex(ADDR address);

  /// Finds the address and its diversifier index if it exists.
  (ADDR, DiversifierIndex)? findAddress(DiversifierIndex index);

  /// Serializes the viewing key to bytes.
  List<int> toBytes();
}
