import 'package:blockchain_utils/cbor/exception/exception.dart';
import 'package:blockchain_utils/cbor/extention/extenton.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/cbor/types/types.dart';
import 'package:blockchain_utils/cbor/utils/cbor_utils.dart';

/// An abstract class representing a CBOR (Concise Binary Object Representation) object.
/// CBOR objects can hold various data types and optional tags, providing a flexible way
/// to represent structured data in a compact binary format.
abstract class CborObject<T> {
  const CborObject(this.value);

  /// Encode the object's value to its CBOR representation and return it as a `List<int>`.
  List<int> encode();

  /// Convert the object's CBOR representation to a hexadecimal string.
  String toCborHex();

  /// An abstract property representing the dynamic value contained in the CBOR object.
  final T value;

  /// Create a new CborObject by decoding the given CBOR-encoded bytes
  factory CborObject.fromCbor(List<int> cborBytes) {
    return CborUtils.decodeCbor(cborBytes).cast();
  }

  /// Create a new CborObject by decoding the given CBOR-encoded hex
  factory CborObject.fromCborHex(String cborHex) {
    return CborObject.fromCbor(BytesUtils.fromHexString(cborHex));
  }

  /// Create a new CborObject from a dynamic value and an optional list of CBOR tags.
  factory CborObject.fromDynamic(dynamic value, [List<int> tags = const []]) {
    final cborObject = () {
      if (value is CborObject) {
        return value;
      } else if (value == null) {
        return const CborNullValue();
      } else if (value is bool) {
        return CborBoleanValue(value);
      } else if (value is int) {
        return CborIntValue(value);
      } else if (value is double) {
        return CborFloatValue(value);
      } else if (value is DateTime) {
        return CborEpochFloatValue(value);
      } else if (value is BigInt) {
        return CborBigIntValue(value);
      } else if (value is String) {
        return CborStringValue(value);
      } else if (value is List<String>) {
        return CborIndefiniteStringValue(value);
      } else if (value is List<int> && BytesUtils.isValidBytes(value)) {
        return CborBytesValue(value);
      } else if (value is List<List<int>>) {
        return CborDynamicBytesValue(value);
      } else if (value is Map) {
        return CborMapValue.definite({
          for (final i in value.entries)
            CborObject.fromDynamic(i.key): CborObject.fromDynamic(i.value)
        });
      } else if (value is List) {
        return CborListValue.definite(
            value.map((e) => CborObject.fromDynamic(e)).toList());
      }
      throw CborException(
          "cbor encoder not found for type ${value.runtimeType}");
    }();
    return cborObject.cast();
  }

  static T deserialize<T extends CborObject>(List<int> bytes) {
    return CborObject.fromCbor(bytes).cast();
  }
}

// An abstract class representing a numeric CBOR (Concise Binary Object Representation) object.
// Numeric CBOR objects are a subset of CBOR objects that specifically store numeric values.
// This class implements the CborObject interface, which allows numeric values to be used
// in the context of CBOR-encoded data structures.
abstract class CborNumeric<T> extends CborObject<T> {
  const CborNumeric(super.value);

  /// Retrieve the numeric value from a CborNumeric object and return it as a BigInt.
  /// This function is used to extract the numeric value from different CborNumeric subtypes.
  static BigInt getCborNumericValue(CborNumeric val) {
    if (val is CborIntValue) {
      return BigInt.from(val.value);
    } else if (val is CborBigIntValue) {
      return val.value;
    } else if (val is CborSafeIntValue) {
      return val.value;
    }
    throw const CborException("invalid cbornumeric");
  }

  /// Convert the CborNumeric object to an integer.
  int toInt();

  /// Convert the CborNumeric object to a BigInt.
  BigInt toBigInt();
}

enum CborIterableEncodingType {
  definite,
  inDefinite,
  set;

  static CborIterableEncodingType fromName(String? name) {
    return values.firstWhere((e) => e.name == name,
        orElse: () =>
            throw const CborException("Invalid itrable encoding type."));
  }
}

///Iterable
abstract class CborIterableObject<T extends Iterable> extends CborObject<T> {
  const CborIterableObject(super.value);

  CborIterableEncodingType get encoding;
}

enum CborLengthEncoding {
  canonical,
  nonCanonical;

  static CborLengthEncoding fromName(String? name) {
    return values.firstWhere((e) => e.name == name,
        orElse: () =>
            throw const CborException("Invalid CBOR length encoding type."));
  }
}
