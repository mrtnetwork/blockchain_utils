import 'package:blockchain_utils/cbor/utils/cbor_utils.dart';

import 'package:blockchain_utils/cbor/utils/dynamic_bytes.dart';
import 'package:blockchain_utils/cbor/core/tags.dart';
import 'package:blockchain_utils/cbor/core/cbor.dart';
import 'package:blockchain_utils/cbor/types/string.dart';

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
  List<int> encode() {
    final bytes = CborBytesTracker();
    bytes.pushTags(CborTags.mime);
    final toBytes = CborStringValue(value);
    bytes.pushBytes(toBytes.encode());
    return bytes.toBytes();
  }

  /// Returns the string representation of the value.
  @override
  String toString() {
    return "CborMimeValue($value)";
  }
}
