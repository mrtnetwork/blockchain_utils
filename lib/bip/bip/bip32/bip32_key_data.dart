import 'dart:typed_data';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/exception/exception.dart';

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
class Bip32ChainCode {
  final List<int> _chainCode;
  Bip32ChainCode([List<int>? chaincode])
      : _chainCode = chaincode ??
            List<int>.filled(Bip32KeyDataConst.chaincodeByteLen, 0);

  /// Get the fixed length in bytes.
  static int fixedLength() {
    return Bip32KeyDataConst.chaincodeByteLen;
  }

  List<int> toBytes() {
    return List<int>.from(_chainCode);
  }

  String toHex() {
    return BytesUtils.toHexString(_chainCode);
  }
}

/// BIP32 fingerprint class.
/// It represents a BIP32 fingerprint.

class Bip32FingerPrint {
  final List<int> _fPrint;
  Bip32FingerPrint._(this._fPrint);
  factory Bip32FingerPrint([List<int>? fprint]) {
    fprint ??= List<int>.from(Bip32KeyDataConst.fingerprintMasterKey);
    if (fprint.length < fixedLength()) {
      throw const ArgumentException("Invalid fingerprint length");
    }
    fprint = fprint.sublist(0, fixedLength());
    return Bip32FingerPrint._(fprint);
  }
  List<int> toBytes() {
    return List<int>.from(_fPrint);
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
        toBytes(), Bip32KeyDataConst.fingerprintMasterKey);
  }
}

/// BIP32 depth class.
/// It represents a BIP32 depth.
class Bip32Depth {
  late final int _depth;
  int get depth => _depth;

  Bip32Depth(int depth) {
    /// Construct class.

    if (depth < 0) {
      throw ArgumentException("Invalid depth ($depth)");
    }
    _depth = depth;
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
  List<int> toBytes([Endian endian = Endian.big]) {
    return IntUtils.toBytes(depth, length: fixedLength(), byteOrder: endian);
  }

  /// Get the depth as an integer.
  int toInt() {
    return depth;
  }

  /// Equality operator.
  bool equals(dynamic other) {
    if (other is! int && other is! Bip32Depth) {
      return false;
    }

    if (other is int) {
      return depth == other;
    }
    return depth == other.depth;
  }
}

/// BIP32 key index class.
/// It represents a BIP32 key index.
class Bip32KeyIndex {
  final int index;

  const Bip32KeyIndex._(this.index);

  /// Harden the specified index and return it.
  factory Bip32KeyIndex.hardenIndex(int index) {
    return Bip32KeyIndex(
        BitUtils.setBit(index, Bip32KeyDataConst.keyIndexHardenedBitNum));
  }

  /// Unharden the specified index and return it.
  factory Bip32KeyIndex.unhardenIndex(int index) {
    return Bip32KeyIndex(
        BitUtils.resetBit(index, Bip32KeyDataConst.keyIndexHardenedBitNum));
  }

  /// Get if the specified index is hardened.
  static bool isHardenedIndex(int index) {
    return BitUtils.intIsBitSet(
        index, Bip32KeyDataConst.keyIndexHardenedBitNum);
  }

  factory Bip32KeyIndex(int index) {
    if (index < 0 || index > Bip32KeyDataConst.keyIndexMaxVal) {
      throw ArgumentException("Invalid key index ($index)");
    }
    return Bip32KeyIndex._(index);
  }
  factory Bip32KeyIndex.fromBytes(List<int> bytes) {
    return Bip32KeyIndex(IntUtils.fromBytes(bytes, byteOrder: Endian.little));
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
  List<int> toBytes([Endian endian = Endian.big]) {
    return IntUtils.toBytes(index, length: fixedLength(), byteOrder: endian);
  }

  /// Get the key index as an integer.
  int toInt() {
    return index;
  }

  bool equals(dynamic other) {
    /// Equality operator.
    if (other is! int && other is! Bip32KeyIndex) {
      return false;
    }

    if (other is int) {
      return index == other;
    }
    return index == other.index;
  }

  @override
  String toString() {
    return "index: $index";
  }
}

/// BIP32 key data class.
/// It contains all additional data related to a BIP32 key (e.g. depth, chain code, etc...).
class Bip32KeyData {
  final Bip32Depth depth;
  final Bip32KeyIndex index;
  final Bip32ChainCode chainCode;
  final Bip32FingerPrint parentFingerPrint;

  Bip32KeyData({
    Bip32Depth? depth,
    Bip32KeyIndex? index,
    Bip32ChainCode? chainCode,
    Bip32FingerPrint? parentFingerPrint,
  })  : depth = depth ?? Bip32Depth(0),
        index = index ?? Bip32KeyIndex(0),
        chainCode = chainCode ?? Bip32ChainCode(),
        parentFingerPrint = parentFingerPrint ?? Bip32FingerPrint();
}
