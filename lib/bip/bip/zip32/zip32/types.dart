import 'dart:typed_data';
import 'package:blockchain_utils/bip/bip/bip32/bip32_key_data.dart';
import 'package:blockchain_utils/bip/bip/zip32/exception/exception.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';
import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';

abstract class DiversifiedTransmissionKey with Equality {
  const DiversifiedTransmissionKey();
  List<int> toBytes();
}

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
    if (value.bitLength > 88) throw Zip32Error("message");
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
  List<int> toBytes() {
    return inner.clone();
  }

  DiversifierIndex increment() {
    final key = toBytes();
    for (int k = 0; k < 11; k++) {
      key[k] = (key[k] + 1).toU8; // wrapping add
      if (key[k] != 0) {
        return DiversifierIndex(key);
      }
    }
    throw Zip32Error.cryptoFailureWith(
      "DiversifierIndex",
      reason: "DiversifierIndex increment overflowed.",
    );
  }

  DiversifierIndex? tryIncrement() {
    try {
      return increment();
    } on Zip32Error {
      return null;
    }
  }

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

  int toU32() => IntUtils.fromBytes(inner, byteOrder: Endian.little).asU32;
  BigInt toU128() =>
      BigintUtils.fromBytes(inner, byteOrder: Endian.little).asU128;

  @override
  List<dynamic> get variables => [inner];
}

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

abstract class IncomingViewingKey<ADDR extends ShieldAddress> with Equality {
  ADDR addressAt(DiversifierIndex index);
  ADDR address(Diversifier drivator);
  DiversifierIndex? diversifierIndex(ADDR address);
  (ADDR, DiversifierIndex)? findAddress(DiversifierIndex index);
  List<int> toBytes();
}
