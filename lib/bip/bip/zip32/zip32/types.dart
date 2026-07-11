import 'dart:typed_data';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/bip44/base/bip44_base.dart';
import 'package:blockchain_utils/bip/bip/zip32/base/context.dart';
import 'package:blockchain_utils/bip/bip/zip32/exception/exception.dart';
import 'package:blockchain_utils/bip/bip/zip32/orchard/keys.dart'
    show OrchardFullViewingKey;
import 'package:blockchain_utils/bip/bip/zip32/sapling/keys.dart'
    show SaplingDiversifiableFullViewingKey;
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';
import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';

enum ZcashProtocol {
  orchard(1),
  sapling(0),
  transparent(2);

  bool get sheilded => this != transparent;
  bool get isOrchard => this == orchard;
  bool get isSapling => this == sapling;
  bool get isTransparent => this == transparent;
  final int value;
  const ZcashProtocol(this.value);
  static ZcashProtocol fromValue(int? value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ItemNotFoundException(name: "ZcashProtocol"),
    );
  }

  static ZcashProtocol fromName(String? name) {
    return values.firstWhere(
      (e) => e.name == name,
      orElse: () => throw ItemNotFoundException(name: "ZcashProtocol"),
    );
  }
}

abstract class DiversifiedTransmissionKey with Equality {
  const DiversifiedTransmissionKey();
  List<int> toBytes();
}

/// Represents an 11-byte Zcash Orchard diversifier index.
class DiversifierIndex with Equality implements Comparable<DiversifierIndex> {
  final List<int> inner;
  static BigInt get maxIndex => BigInt.parse("309485009821345068724781055");
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
      byteOrder: Endian.little,
    );
    return DiversifierIndex(toBytes.sublist(0, 11));
  }
  factory DiversifierIndex.from(int value) {
    return DiversifierIndex(
      List.filled(11, 0)..setAll(0, value.toU32LeBytes()),
    );
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

  @override
  int compareTo(DiversifierIndex other) {
    return toU128().compareTo(other.toU128());
  }
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
  const IncomingViewingKey();

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

  T cast<T extends IncomingViewingKey>() {
    if (this is! T) {
      throw CastFailedException<T>(value: this);
    }
    return this as T;
  }

  ZcashProtocol get protocol;
}

abstract class OutgoingViewingKey with Equality {
  List<int> toBytes();
}

abstract class DiversifiableFullViewingKey<
  ADDR extends ShieldAddress,
  IVK extends IncomingViewingKey<ADDR>,
  OVK extends OutgoingViewingKey,
  K extends KeyAgreementPrivateKey
>
    with Equality {
  const DiversifiableFullViewingKey();
  factory DiversifiableFullViewingKey.fromBytes(List<int> bytes) {
    const orchardFvkLengthInBytes = 96;
    const saplingLengthInBytes = 128;
    final length = bytes.length;
    if (length == orchardFvkLengthInBytes) {
      return OrchardFullViewingKey.fromBytesUnchecked(bytes).cast();
    }
    if (length == saplingLengthInBytes) {
      return SaplingDiversifiableFullViewingKey.fromBytes(bytes).cast();
    }
    throw ArgumentException.invalidOperationArguments(
      "DiversifiableFullViewingKey",
      reason: "Invalid diversifiable full view key bytes length.",
    );
  }

  IVK toIvk(Bip44Changes scope, {ZCryptoContext? context});
  OVK toOvk(Bip44Changes scope);
  K keyAgreement(Bip44Changes scope, {ZCryptoContext? context});

  Bip44Changes? scopeForAddress({
    required ADDR address,
    ZCryptoContext? context,
  });

  (DiversifierIndex, Bip44Changes)? getScopeAndDiversifierIndex(
    ADDR address, {
    ZCryptoContext? context,
  }) {
    for (final i in Bip44Changes.values) {
      final DiversifierIndex? index = toIvk(
        i,
        context: context,
      ).diversifierIndex(address);
      if (index != null) return (index, i);
    }
    return null;
  }

  List<int> toBytes();

  ZcashProtocol get protocol;

  T cast<
    T extends DiversifiableFullViewingKey<
      ShieldAddress,
      IncomingViewingKey,
      OutgoingViewingKey,
      KeyAgreementPrivateKey
    >
  >() {
    if (this is! T) {
      throw CastFailedException<T>(value: this);
    }
    return this as T;
  }
}

abstract class KeyAgreementPrivateKey with Equality {
  const KeyAgreementPrivateKey();
}
