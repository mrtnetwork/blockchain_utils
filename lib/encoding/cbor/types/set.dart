import 'package:blockchain_utils/encoding/cbor/core/cbor.dart';
import 'package:blockchain_utils/encoding/cbor/core/tags.dart';
import 'package:blockchain_utils/encoding/cbor/utils/cbor_utils.dart';
import 'package:blockchain_utils/encoding/cbor/utils/dynamic_bytes.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// A class representing a CBOR (Concise Binary Object Representation) Set value.
class CborSetValue<T extends CborObject>
    extends CborIterableObject<Iterable<T>> {
  /// Constructor for creating a CborSetValue instance with the provided parameters.
  /// It accepts a set of all encodable cbor object.
  CborSetValue(super.value);

  factory CborSetValue.decode(List<int> bytes) {
    return CborUtils.decodeCbor(bytes);
  }

  /// Encode the value into CBOR bytes
  @override
  BuBytes encode() {
    final bytes = CborBytesTracker();
    bytes.pushTags(CborTags.set);
    bytes.pushInt(MajorTags.array, value.length);
    for (final v in value) {
      final encodeObj = v.encode();
      bytes.pushBytes(encodeObj);
    }
    return bytes.buffer();
  }

  /// Returns the string representation of the value.
  @override
  String toString() {
    return "CborSetValue({${value.join(", ")}})";
  }

  @override
  CborIterableEncodingType get encoding => CborIterableEncodingType.set;

  @override
  Object getValue() {
    return value.map((e) => e.value).toSet();
  }
}
