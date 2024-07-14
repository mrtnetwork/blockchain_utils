import 'package:blockchain_utils/bip/substrate/scale/substrate_scale_enc_base.dart';
import 'package:blockchain_utils/bip/substrate/scale/substrate_scale_enc_bytes.dart';
import 'package:blockchain_utils/bip/substrate/scale/substrate_scale_enc_uint.dart';
import 'package:blockchain_utils/bip/substrate/exception/substrate_ex.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';

/// A constants class that provides predefined values and regular expressions related to Substrate paths
/// and SCALE encoders for integers.
class SubstratePathConst {
  /// The maximum length in bytes for encoding an element
  static const int encodedElemMaxByteLen = 32;

  /// Regular expression for Substrate paths
  static const String rePath = r"\/+[^/]+";

  /// Prefix for soft paths
  static const String softPathPrefix = "/";

  /// Prefix for hard paths
  static const String hardPathPrefix = "//";

  /// SCALE encoders for different integer sizes
  static const Map<int, SubstrateScaleEncoderBase> scaleIntEncoders = {
    8: SubstrateScaleU8Encoder(),
    16: SubstrateScaleU16Encoder(),
    32: SubstrateScaleU32Encoder(),
    64: SubstrateScaleU64Encoder(),
    128: SubstrateScaleU128Encoder(),
    256: SubstrateScaleU256Encoder(),
  };
}

/// Represents a Substrate path element, which can be either soft or hard, and provides methods for
/// working with path elements, including serialization, validation, and computing chain code.
class SubstratePathElem {
  /// The raw string representation of the path element.
  late final String elem;

  /// Indicates whether the path element is hard (true) or soft (false).
  late final bool isHard;

  /// Creates a new instance of [SubstratePathElem] with the provided [element].
  SubstratePathElem(String element) {
    if (!isElemValid(element)) {
      throw SubstratePathError("Invalid path element ($element)");
    }

    elem = element.replaceAll("/", "");
    isHard = element.startsWith(SubstratePathConst.hardPathPrefix);
  }

  /// Checks if the path element is soft (not hard).
  bool get isSoft {
    return !isHard;
  }

  /// Computes and returns the chain code for the path element.
  List<int> get chainCode {
    return computeChainCode;
  }

  /// Returns the string representation of the path element, including the appropriate prefix
  String toStr() {
    final prefix = isHard
        ? SubstratePathConst.hardPathPrefix
        : SubstratePathConst.softPathPrefix;
    return "$prefix$elem";
  }

  @override
  String toString() {
    return toStr();
  }

  /// Computes the chain code based on the path element and its data type.
  List<int> get computeChainCode {
    SubstrateScaleEncoderBase? scaleEnc;
    final BigInt? toInt = BigInt.tryParse(elem);
    if (toInt != null) {
      final bitLen = toInt.bitLength;
      for (final minBitLen in SubstratePathConst.scaleIntEncoders.keys) {
        if (bitLen <= minBitLen) {
          scaleEnc = SubstratePathConst.scaleIntEncoders[minBitLen];
          break;
        }
      }

      if (scaleEnc == null) {
        throw SubstratePathError("Invalid integer bit length ($bitLen)");
      }
    } else {
      scaleEnc = const SubstrateScaleBytesEncoder();
    }

    final encData = scaleEnc.encode(elem);
    const maxLen = SubstratePathConst.encodedElemMaxByteLen;
    if (encData.length > maxLen) {
      return QuickCrypto.blake2b256Hash(encData);
    } else {
      return List<int>.from(
          encData.toList() + List.filled(maxLen - encData.length, 0));
    }
  }

  /// Checks if the provided path element is valid according to Substrate path rules.
  bool isElemValid(String elem) {
    return (elem.startsWith(SubstratePathConst.softPathPrefix) ||
            elem.startsWith(SubstratePathConst.hardPathPrefix)) &&
        elem.lastIndexOf("/") < 2 &&
        elem.replaceAll("/", "").isNotEmpty;
  }
}

/// Represents a Substrate path, which is an ordered sequence of [SubstratePathElem] elements.
/// This class provides methods for creating, manipulating, and serializing paths.
class SubstratePath extends Iterable {
  /// A list of path elements that make up the Substrate path.
  final List<SubstratePathElem> elems;

  /// Creates a new [SubstratePath] with the provided list of [elems].
  SubstratePath([this.elems = const <SubstratePathElem>[]]);

  /// Adds a [SubstratePathElem] to the path and returns a new [SubstratePath] instance.
  SubstratePath addElem(SubstratePathElem elem) {
    return SubstratePath([...elems, elem]);
  }

  /// Converts the Substrate path to its string representation by joining the elements.
  String toStr() {
    return toList().join();
  }

  @override
  String toString() {
    return toStr();
  }

  /// Retrieves a path element at the specified index.
  SubstratePathElem operator [](int idx) {
    return elems[idx];
  }

  /// Returns an iterator for iterating over the path elements.
  @override
  Iterator get iterator => elems.iterator;
}

/// Parses a string representation of a Substrate path and returns a [SubstratePath] object.
class SubstratePathParser {
  /// Parses the input [path] and constructs a [SubstratePath] object.
  ///
  /// The [path] should be a string representation of a Substrate path.
  /// Throws a [SubstratePathError] if the path is invalid.
  static SubstratePath parse(String path) {
    if (path.isNotEmpty && !path.startsWith('/')) {
      throw SubstratePathError('Invalid path ($path)');
    }

    /// Extract path elements using a regular expression and create a SubstratePath object.
    final paths = RegExp(SubstratePathConst.rePath)
        .allMatches(path)
        .map((match) => match.group(0)!)
        .toList();
    return SubstratePath(paths.map((e) => SubstratePathElem(e)).toList());
  }
}
