import 'package:blockchain_utils/encoding/cbor/types/types.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/encoding/cbor/utils/cbor_utils.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';

/// An abstract class representing a CBOR (Concise Binary Object Representation) object.
/// CBOR objects can hold various data types and optional tags, providing a flexible way
/// to represent structured data in a compact binary format.
abstract class CborObject<T extends Object?> with Equality {
  const CborObject(this.value);

  /// Encode the object's value to its CBOR representation and return it as [BuBytes].
  BuBytes encode();

  String toCborHex() {
    return encode().toHex();
  }

  /// An abstract property representing the dynamic value contained in the CBOR object.
  final T value;

  /// Create a new CborObject by decoding the given CBOR-encoded bytes
  factory CborObject.fromCbor(List<int> cborBytes) {
    return CborUtils.decodeCbor(cborBytes);
  }

  /// Create a new CborObject by decoding the given CBOR-encoded hex
  factory CborObject.fromCborHex(String cborHex) {
    return CborObject.fromCbor(BytesUtils.fromHexString(cborHex));
  }

  /// Create a new CborObject from a dynamic value and an optional list of CBOR tags.
  factory CborObject.fromDynamic(
    dynamic value, {
    CborObject Function(Object value)? unknownType,
  }) {
    final cborObject = () {
      if (value is CborObject) {
        return value;
      } else if (value == null) {
        return const CborNullValue();
      } else if (value is bool) {
        return CborBooleanValue(value);
      } else if (value is String) {
        return CborStringValue(value);
      } else if (value is List<String>) {
        return CborIndefiniteStringValue(value);
      } else if (value is int) {
        return CborIntValue(value);
      } else if (value is double) {
        return CborFloatValue(value);
      } else if (value is DateTime) {
        return CborEpochFloatValue(value);
      } else if (value is BigInt) {
        return CborBigIntValue(value);
      } else if (value is List<int> && BytesUtils.areBytesValid(value)) {
        return CborBytesValue(value);
      } else if (value is List<List<int>> &&
          value.every((e) => BytesUtils.areBytesValid(e))) {
        return CborDynamicBytesValue(value);
      } else if (value is Map) {
        return CborMapValue.definite({
          for (final i in value.entries)
            CborObject.fromDynamic(
              i.key,
              unknownType: unknownType,
            ): CborObject.fromDynamic(i.value, unknownType: unknownType),
        });
      } else if (value is List) {
        return CborListValue.definite(
          value
              .map((e) => CborObject.fromDynamic(e, unknownType: unknownType))
              .toList(),
        );
      }
      if (unknownType != null) {
        return unknownType(value);
      }
      throw BuError(
        DefaultErrorType.notFound,
        "cbor encoder not found for type ${value.runtimeType}",
      );
    }();
    return cborObject.cast();
  }

  static T deserialize<T extends CborObject>(List<int> bytes) {
    return CborObject.fromCbor(bytes).cast();
  }

  Object? getValue() => value;

  @override
  List<dynamic> get variables => [value];

  E cast<E extends CborObject>() {
    if (this is E) return this as E;
    throw BuError(
      DefaultErrorType.castFailed,
      "Failed to cast value",
      details: {"expected": "E", "value": runtimeType.toString()},
    );
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
    throw CoreErrors.invalidOperationArguments(
      "getCborNumericValue",
      reason: "invalid CBOR integer value.",
    );
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
    return values.firstWhere(
      (e) => e.name == name,
      orElse:
          () =>
              throw const BuError(
                DefaultErrorType.invalidArgument,
                "Invalid iterable encoding type.",
              ),
    );
  }
}

///Iterable
abstract class CborIterableObject<T extends Iterable<CborObject>>
    extends CborObject<T> {
  const CborIterableObject(super.value);
  CborIterableEncodingType get encoding;
}

enum CborLengthEncoding {
  canonical,
  nonCanonical;

  static CborLengthEncoding fromName(String? name) {
    return values.firstWhere(
      (e) => e.name == name,
      orElse:
          () =>
              throw const BuError(
                DefaultErrorType.invalidLength,
                "Invalid CBOR length encoding type.",
              ),
    );
  }
}
