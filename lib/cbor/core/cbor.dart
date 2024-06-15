import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/cbor/types/types.dart';
import 'package:blockchain_utils/cbor/utils/cbor_utils.dart';
import 'package:blockchain_utils/exception/exception.dart';

/// An abstract class representing a CBOR (Concise Binary Object Representation) object.
/// CBOR objects can hold various data types and optional tags, providing a flexible way
/// to represent structured data in a compact binary format.
abstract class CborObject {
  /// Encode the object's value to its CBOR representation and return it as a List<int>.
  List<int> encode();

  /// Convert the object's CBOR representation to a hexadecimal string.
  String toCborHex();

  /// An abstract property representing the dynamic value contained in the CBOR object.
  abstract final dynamic value;

  /// Create a new CborObject by decoding the given CBOR-encoded bytes
  factory CborObject.fromCbor(List<int> cborBytes) {
    return CborUtils.decodeCbor(cborBytes);
  }

  /// Create a new CborObject by decoding the given CBOR-encoded hex
  factory CborObject.fromCborHex(String cborHex) {
    return CborUtils.decodeCbor(BytesUtils.fromHexString(cborHex));
  }

  /// Create a new CborObject from a dynamic value and an optional list of CBOR tags.
  factory CborObject.fromDynamic(dynamic value, [List<int> tags = const []]) {
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
    } else if (value is BigInt) {
      return CborBigIntValue(value);
    } else if (value is String) {
      return CborStringValue(value);
    } else if (value is List<String>) {
      return CborIndefiniteStringValue(value);
    } else if (value is List<int>) {
      return CborBytesValue(value);
    } else if (value is List<List<int>>) {
      return CborDynamicBytesValue(value);
    } else if (value is Map) {
      return CborMapValue.fixedLength(value);
    } else if (value is List<dynamic>) {
      return CborListValue.fixedLength(
          value.map((e) => CborObject.fromDynamic(e)).toList());
    }
    throw UnimplementedError("does not supported");
  }
}

// An abstract class representing a numeric CBOR (Concise Binary Object Representation) object.
// Numeric CBOR objects are a subset of CBOR objects that specifically store numeric values.
// This class implements the CborObject interface, which allows numeric values to be used
// in the context of CBOR-encoded data structures.
abstract class CborNumeric implements CborObject {
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
    throw const ArgumentException("invalid cbornumeric");
  }

  /// Convert the CborNumeric object to an integer.
  int toInt();

  /// Convert the CborNumeric object to a BigInt.
  BigInt toBigInt();
}
