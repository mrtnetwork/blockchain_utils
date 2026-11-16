import 'package:blockchain_utils/encoding/cbor/utils/cbor_utils.dart';

import 'package:blockchain_utils/encoding/cbor/utils/dynamic_bytes.dart';
import 'package:blockchain_utils/encoding/cbor/core/tags.dart';
import 'package:blockchain_utils/encoding/cbor/core/cbor.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// A class representing a CBOR (Concise Binary Object Representation) null value.
class CborNullValue extends CborObject<Null> {
  /// Constructor for creating a CborNullValue instance with the provided parameters.
  const CborNullValue() : super(null);

  factory CborNullValue.decode(List<int> bytes) {
    return CborUtils.decodeCbor(bytes);
  }

  /// Encode the value into CBOR bytes
  @override
  BuBytes encode() {
    final bytes = CborBytesTracker();
    bytes.pushInt(MajorTags.simpleOrFloat, SimpleTags.simpleNull);
    return bytes.buffer();
  }

  /// Returns the string representation of the value.
  @override
  String toString() {
    return "CborNullValue()";
  }
}

/// A class representing a CBOR (Concise Binary Object Representation) undefined value.
class CborUndefinedValue extends CborObject<Null> {
  /// Constructor for creating a CborUndefinedValue instance with the provided parameters.
  const CborUndefinedValue() : super(null);

  factory CborUndefinedValue.decode(List<int> bytes) {
    return CborUtils.decodeCbor(bytes);
  }

  /// Encode the value into CBOR bytes
  @override
  BuBytes encode() {
    final bytes = CborBytesTracker();
    bytes.pushInt(MajorTags.simpleOrFloat, SimpleTags.simpleUndefined);
    return bytes.buffer();
  }

  /// Returns the string representation of the value.
  @override
  String toString() {
    return "CborUndefinedValue()";
  }
}
