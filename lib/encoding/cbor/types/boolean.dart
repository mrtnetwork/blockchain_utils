import 'package:blockchain_utils/encoding/cbor/utils/cbor_utils.dart';

import 'package:blockchain_utils/encoding/cbor/utils/dynamic_bytes.dart';
import 'package:blockchain_utils/encoding/cbor/core/tags.dart';
import 'package:blockchain_utils/encoding/cbor/core/cbor.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// A class representing a CBOR (Concise Binary Object Representation) boolean value.
class CborBooleanValue extends CborObject<bool> {
  /// Constructor for creating a CborBooleanValue instance with the provided parameters.
  /// It accepts the boolean value.
  const CborBooleanValue(super.value);

  factory CborBooleanValue.decode(List<int> bytes) {
    return CborUtils.decodeCbor(bytes);
  }

  /// Encode the value into CBOR bytes
  @override
  BuBytes encode() {
    final bytes = CborBytesTracker();
    bytes.pushInt(
      MajorTags.simpleOrFloat,
      value ? SimpleTags.simpleTrue : SimpleTags.simpleFalse,
    );
    return bytes.buffer();
  }

  @override
  String toString() {
    return "CborBooleanValue($value)";
  }
}
