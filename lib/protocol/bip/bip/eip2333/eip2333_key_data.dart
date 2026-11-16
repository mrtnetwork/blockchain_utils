import 'dart:typed_data';
import 'package:blockchain_utils/exception/exception/core_errors.dart';

import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/protocol/bip/bip/eip2333/eip2333_const.dart';
import 'package:blockchain_utils/protocol/hd_key/types.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Child index for EIP-2333.
///
/// Unlike BIP-32 there is no hardened concept: every `0 <= index < 2^32`
/// is valid and uses the same Lamport derivation.
class Eip2333KeyIndex with Equality implements HdKeyIndex {
  final int index;
  const Eip2333KeyIndex._(this.index);

  factory Eip2333KeyIndex(int index) {
    if (index < 0 || index > Eip2333Const.maxIndex) {
      throw CoreErrors.invalidOperationArguments(
        'Eip2333KeyIndex',
        name: 'index',
        reason: 'Invalid key index.',
      );
    }
    return Eip2333KeyIndex._(index);
  }

  factory Eip2333KeyIndex.fromBytes(
    List<int> bytes, {
    Endian endian = Endian.big,
  }) {
    return Eip2333KeyIndex(IntUtils.fromBytes(bytes, byteOrder: endian));
  }

  /// Big-endian 4-byte encoding (`I2OSP(index, 4)`).
  @override
  BuBytes toBytes([Endian endian = Endian.big]) {
    return index.toBytes(length: 4, byteOrder: endian);
  }

  int toInt() => index;

  @override
  String toString() => 'index: $index';

  @override
  List<dynamic> get variables => [index];
}

/// Depth of an EIP-2333 key in the tree (`m` = 0).
class Eip2333Depth with Equality implements KeyDepth {
  @override
  final int depth;
  const Eip2333Depth._(this.depth);
  factory Eip2333Depth(int depth) {
    try {
      return Eip2333Depth._(depth.asU8);
    } catch (_) {
      throw CoreErrors.invalidOperationArguments(
        'Eip2333Depth',
        name: 'depth',
        reason: 'Invalid depth',
      );
    }
  }

  Eip2333Depth increase() => Eip2333Depth(depth + 1);

  @override
  BuBytes toBytes([Endian endian = Endian.big]) {
    return depth.toBytes(length: 1, byteOrder: endian);
  }

  int toInt() => depth;

  @override
  List<dynamic> get variables => [depth];
}

/// Key data for EIP-2333, mirrors `Bip32KeyData`.
///
/// EIP-2333 has no chain code / fingerprint / xpub concept, only the
/// position in the tree, so both default to `null` while still satisfying
/// `BaseCryptoKeyData` (and therefore `HDKeyManager`) bounds.
class Eip2333KeyData
    with Equality
    implements
        BaseCryptoKeyData<
          ChainCode?,
          Eip2333KeyIndex,
          Eip2333Depth,
          KeyFingerPrint?
        > {
  @override
  final Eip2333Depth depth;
  @override
  final Eip2333KeyIndex index;
  @override
  final ChainCode? chainCode = null;
  @override
  final KeyFingerPrint? fingerPrint = null;
  Eip2333KeyData({Eip2333Depth? depth, Eip2333KeyIndex? index})
    : depth = depth ?? Eip2333Depth(0),
      index = index ?? Eip2333KeyIndex(0);

  @override
  List<dynamic> get variables => [depth, index];
}
