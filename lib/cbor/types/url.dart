import 'package:blockchain_utils/cbor/utils/cbor_utils.dart';

import 'package:blockchain_utils/cbor/utils/dynamic_bytes.dart';
import 'package:blockchain_utils/cbor/core/tags.dart';
import 'package:blockchain_utils/cbor/types/string.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';

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
  List<int> encode() {
    final bytes = CborBytesTracker();
    bytes.pushTags(CborTags.uri);
    final toBytes = CborStringValue(value);
    bytes.pushBytes(toBytes.encode());
    return bytes.toBytes();
  }

  /// Returns the string representation of the value.
  @override
  String toString() {
    return value;
  }

  /// Encode the value into CBOR bytes an then to hex
  @override
  String toCborHex() {
    return BytesUtils.toHexString(encode());
  }

  @override
  String getValue() {
    return value;
  }
}
