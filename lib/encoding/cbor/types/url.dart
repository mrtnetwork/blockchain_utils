import 'package:blockchain_utils/encoding/cbor/utils/cbor_utils.dart';

import 'package:blockchain_utils/encoding/cbor/utils/dynamic_bytes.dart';
import 'package:blockchain_utils/encoding/cbor/core/tags.dart';
import 'package:blockchain_utils/encoding/cbor/types/string.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// A class representing a CBOR (Concise Binary Object Representation) uri value.
class CborUriValue extends CborString<String> {
  /// Constructor for creating a CborUriValue instance with the provided parameters.
  /// It accepts string value of uri.
  const CborUriValue(super.value);

  factory CborUriValue.decode(List<int> bytes) {
    return CborUtils.decodeCbor(bytes);
  }

  /// Encode the value into CBOR bytes
  @override
  BuBytes encode() {
    final bytes = CborBytesTracker();
    bytes.pushTags(CborTags.uri);
    final toBytes = CborStringValue(value);
    bytes.pushBytes(toBytes.encode());
    return bytes.buffer();
  }

  /// Returns the string representation of the value.
  @override
  String toString() {
    return "CborUriValue($value)";
  }

  @override
  String getValue() {
    return value;
  }
}
