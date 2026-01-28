import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exception/exception.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';

class PrfExpandConst {
  static const List<int> prfExpandPersonalization = [
    90,
    99,
    97,
    115,
    104,
    95,
    69,
    120,
    112,
    97,
    110,
    100,
    83,
    101,
    101,
    100,
  ];
}

/// PRF domain identifiers and input shapes.
enum PrfExpand {
  saplingAsk(0x00),
  saplingNsk(0x01),
  saplingOvk(0x02),
  saplingRcm(0x04),
  saplingEsk(0x05),
  orchardAsk(0x06),
  orchardNk(0x07),
  orchardRivk(0x08),
  saplingZip32MasterDk(0x10),
  saplingZip32ChildIAsk(0x13),
  saplingZip32ChildINsk(0x14),
  saplingZip32InternalNsk(0x17),
  saplingZip32InternalDkOvk(0x18),

  // 1-byte input: [u8; 1]
  saplingDefaultDiversifier(0x03, length: [1]),

  // 32-byte input: [u8; 32]
  orchardEsk(0x04, length: [32]),
  orchardRcm(0x05, length: [32]),
  psi(0x09, length: [32]),
  saplingZip32ChildOvk(0x15, length: [32]),
  saplingZip32ChildDk(0x16, length: [32]),

  // 33-byte input: [u8; 33]
  transparentZip316Ovk(0xD0, length: [33]),

  // (32, 4)
  sproutZip32Child(0x80, length: [32, 4]),

  // (32, 32)
  orchardDkOvk(0x82, length: [32, 32]),
  orchardRivkInternal(0x83, length: [32, 32]),

  // (96, 32, 4)
  saplingZip32ChildHardened(0x11, length: [96, 32, 4]),
  saplingZip32ChildNonHardened(0x12, length: [96, 32, 4]),

  // (32, 4, 1, variable-length slice)
  orchardZip32Child(
    0x81,
    length: [32, 4, 1],
  ), // variable-length slice handled dynamically
  adhocZip32Child(0xAB, length: [32, 4, 1]),
  registeredZip32Child(0xAC, length: [32, 4, 1]);

  /// Domain separator identifier
  final int domainSeparator;

  /// Input lengths per component, e.g., [32, 4, 1], empty list if no input
  final List<int> length;

  const PrfExpand(this.domainSeparator, {this.length = const []});

  List<int> apply(List<int> sk, {List<List<int>> data = const []}) {
    switch (this) {
      case PrfExpand.orchardZip32Child:
      case PrfExpand.adhocZip32Child:
      case PrfExpand.registeredZip32Child:
        if (data.length != 3 && data.length != 4) {
          throw ArgumentException.invalidOperationArguments(
            "PrfExpand",
            name: "sk",
            reason: "Invalid bytes arguments length.",
          );
        }
        final a = data.elementAt(0);
        final b = data.elementAt(1);
        final c = data.elementAt(2);
        final d = data.elementAtOrNull(3) ?? <int>[];
        if (BytesUtils.bytesEqual(c, [0]) && d.isEmpty) {
          return _apply(sk, data: [a, b]);
        }
        return _apply(sk, data: [a, b, c, d]);
      default:
        if (data.length != length.length ||
            data.indexed.any((e) => e.$2.length != length[e.$1])) {
          throw ArgumentException.invalidOperationArguments(
            "PrfExpand",
            name: "sk",
            reason: "Invalid bytes arguments length.",
          );
        }
        return _apply(sk, data: data);
    }
  }

  List<int> _apply(List<int> sk, {List<List<int>> data = const []}) {
    return QuickCrypto.blake2b512Hash(
      sk,
      personalization: PrfExpandConst.prfExpandPersonalization,
      extraBlocks: [
        [domainSeparator],
        ...data,
      ],
    );
  }
}
