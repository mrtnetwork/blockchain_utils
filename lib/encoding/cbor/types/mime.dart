import 'package:blockchain_utils/encoding/cbor/utils/cbor_utils.dart';

import 'package:blockchain_utils/encoding/cbor/utils/dynamic_bytes.dart';
import 'package:blockchain_utils/encoding/cbor/core/tags.dart';
import 'package:blockchain_utils/encoding/cbor/core/cbor.dart';
import 'package:blockchain_utils/encoding/cbor/types/string.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// A class representing a CBOR (Concise Binary Object Representation) mime value.
class CborMimeValue extends CborObject<String> {
  /// Constructor for creating a CborMimeValue instance with the provided parameters.
  /// It accepts the string value.
  const CborMimeValue(super.value);

  factory CborMimeValue.decode(List<int> bytes) {
    return CborUtils.decodeCbor(bytes);
  }

  /// Encode the value into CBOR bytes
  @override
  BuBytes encode() {
    final bytes = CborBytesTracker();
    bytes.pushTags(CborTags.mime);
    final toBytes = CborStringValue(value);
    bytes.pushBytes(toBytes.encode());
    return bytes.buffer();
  }

  /// Returns the string representation of the value.
  @override
  String toString() {
    return "CborMimeValue($value)";
  }
}
