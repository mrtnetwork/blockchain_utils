import 'dart:typed_data';
import 'package:blockchain_utils/bip/bip/hd_key/types.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/utils/binary/bit_utils.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';

/// Class container for BIP32 key data constants.
class Bip32KeyDataConst {
  // Chaincode length in bytes
  static const int chaincodeByteLen = 32;
  // Depth length in bytes
  static const int depthByteLen = 1;
  // Fingerprint length in bytes
  static const int fingerprintByteLen = 4;
  // Fingerprint of master key
  static const List<int> fingerprintMasterKey = [0, 0, 0, 0];
  // Key index length in bytes
  static const int keyIndexByteLen = 4;
  // Key index maximum value
  static const int keyIndexMaxVal = 4294967295; // 2^32 - 1
  // Key index hardened bit number
  static const int keyIndexHardenedBitNum = 31;
  // harden Key index minimum value
  static const int hardenKeyIndexMinValue = 2147483648; // 2^31 - 1
}

/// BIP32 chaincode class.
/// It represents a BIP32 chaincode.
class Bip32ChainCode with Equality implements ChainCode {
  final List<int> _chainCode;
  Bip32ChainCode([List<int>? chaincode])
    : _chainCode =
          (chaincode ?? List<int>.filled(Bip32KeyDataConst.chaincodeByteLen, 0))
              .asImmutableBytes;

  /// Get the fixed length in bytes.
  static int fixedLength() {
    return Bip32KeyDataConst.chaincodeByteLen;
  }

  @override
  List<int> toBytes() {
    return _chainCode.clone();
  }

  @override
  String toHex() {
    return BytesUtils.toHexString(_chainCode);
  }

  @override
  List<dynamic> get variables => [_chainCode];
}

/// BIP32 fingerprint class.
/// It represents a BIP32 fingerprint.
class Bip32FingerPrint with Equality implements KeyFingerPrint {
  final List<int> _fPrint;
  Bip32FingerPrint._(this._fPrint);
  factory Bip32FingerPrint([List<int>? fprint]) {
    if (fprint == null) {
      return Bip32FingerPrint._(Bip32KeyDataConst.fingerprintMasterKey);
    }
    if (fprint.length < fixedLength()) {
      throw ArgumentException.invalidOperationArguments(
        "Bip32FingerPrint",
        reason: "Invalid fingerprint length",
      );
    }
    fprint = fprint.sublist(0, fixedLength());
    return Bip32FingerPrint._(fprint);
  }
  @override
  List<int> toBytes() {
    return _fPrint.clone();
  }

  String toHex() {
    return BytesUtils.toHexString(_fPrint);
  }

  /// Get the fixed length in bytes.
  static int fixedLength() {
    return Bip32KeyDataConst.fingerprintByteLen;
  }

  /// Get if the fingerprint corresponds to a master key.
  bool isMasterKey() {
    return BytesUtils.bytesEqual(
      toBytes(),
      Bip32KeyDataConst.fingerprintMasterKey,
    );
  }

  @override
  List<dynamic> get variables => [_fPrint];
}

/// BIP32 depth class.
/// It represents a BIP32 depth.
class Bip32Depth with Equality implements KeyDepth {
  @override
  final int depth;
  const Bip32Depth._(this.depth);
  factory Bip32Depth(int depth) {
    try {
      return Bip32Depth._(depth.asU8);
    } catch (_) {
      throw ArgumentException.invalidOperationArguments(
        "Bip32Depth",
        name: "depth",
        reason: "Invalid depth",
      );
    }
  }

  /// Get the fixed length in bytes.
  static int fixedLength() {
    return Bip32KeyDataConst.depthByteLen;
  }

  /// Get a new object with increased depth.
  Bip32Depth increase() {
    return Bip32Depth(depth + 1);
  }

  /// Get the depth as bytes.
  @override
  List<int> toBytes([Endian endian = Endian.big]) {
    return IntUtils.toBytes(depth, length: fixedLength(), byteOrder: endian);
  }

  /// Get the depth as an integer.
  int toInt() {
    return depth;
  }

  @override
  List<dynamic> get variables => [depth];
}

/// BIP32 key index class.
/// It represents a BIP32 key index.
class Bip32KeyIndex with Equality implements HdKeyIndex {
  final int index;

  const Bip32KeyIndex._(this.index);

  /// Harden the specified index and return it.
  factory Bip32KeyIndex.hardenIndex(int index) {
    return Bip32KeyIndex(
      BitUtils.setBit(index, Bip32KeyDataConst.keyIndexHardenedBitNum),
    );
  }

  /// Unharden the specified index and return it.
  factory Bip32KeyIndex.unhardenIndex(int index) {
    return Bip32KeyIndex(
      BitUtils.resetBit(index, Bip32KeyDataConst.keyIndexHardenedBitNum),
    );
  }

  /// Get if the specified index is hardened.
  static bool isHardenedIndex(int index) {
    return BitUtils.intIsBitSet(
      index,
      Bip32KeyDataConst.keyIndexHardenedBitNum,
    );
  }

  factory Bip32KeyIndex(int index) {
    if (index < 0 || index > Bip32KeyDataConst.keyIndexMaxVal) {
      throw ArgumentException.invalidOperationArguments(
        "Bip32KeyIndex",
        name: "index",
        reason: "Invalid key index.",
      );
    }
    return Bip32KeyIndex._(index);
  }
  factory Bip32KeyIndex.fromBytes(
    List<int> bytes, {
    Endian endian = Endian.little,
  }) {
    return Bip32KeyIndex(IntUtils.fromBytes(bytes, byteOrder: endian));
  }

  /// Get the fixed length in bytes.
  static int fixedLength() {
    return Bip32KeyDataConst.keyIndexByteLen;
  }

  /// Get a new Bip32KeyIndex object with the current key index hardened.
  Bip32KeyIndex harden() {
    return Bip32KeyIndex.hardenIndex(index);
  }

  /// Get a new Bip32KeyIndex object with the current key index unhardened.
  Bip32KeyIndex unharden() {
    return Bip32KeyIndex.unhardenIndex(index);
  }

  /// Get if the key index is hardened.
  bool get isHardened {
    return isHardenedIndex(index);
  }

  /// Get the key index as bytes.
  @override
  List<int> toBytes([Endian endian = Endian.big]) {
    return IntUtils.toBytes(index, length: fixedLength(), byteOrder: endian);
  }

  /// Get the key index as an integer.
  int toInt() {
    return index;
  }

  @override
  String toString() {
    return "index: $index";
  }

  @override
  List<dynamic> get variables => [index];
}

/// BIP32 key data class.
/// It contains all additional data related to a BIP32 key (e.g. depth, chain code, etc...).
class Bip32KeyData
    with Equality
    implements
        BaseCryptoKeyData<
          Bip32ChainCode,
          Bip32KeyIndex,
          Bip32Depth,
          Bip32FingerPrint
        > {
  @override
  final Bip32Depth depth;
  @override
  final Bip32KeyIndex index;
  @override
  final Bip32ChainCode chainCode;
  @override
  final Bip32FingerPrint fingerPrint;

  Bip32KeyData({
    Bip32Depth? depth,
    Bip32KeyIndex? index,
    Bip32ChainCode? chainCode,
    Bip32FingerPrint? fingerPrint,
  }) : depth = depth ?? Bip32Depth(0),
       index = index ?? Bip32KeyIndex(0),
       chainCode = chainCode ?? Bip32ChainCode(),
       fingerPrint = fingerPrint ?? Bip32FingerPrint();

  @override
  List<dynamic> get variables => [depth, index, chainCode, fingerPrint];
}
