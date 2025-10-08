import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/cbor/utils/dynamic_bytes.dart';
import 'package:blockchain_utils/cbor/core/tags.dart';
import 'package:blockchain_utils/cbor/core/cbor.dart';

/// A class representing a CBOR (Concise Binary Object Representation) Set value.
class CborSetValue<T extends CborObject>
    extends CborIterableObject<Iterable<T>> {
  /// Constructor for creating a CborSetValue instance with the provided parameters.
  /// It accepts a set of all encodable cbor object.
  CborSetValue(super.value);

  /// Encode the value into CBOR bytes
  @override
  List<int> encode() {
    final bytes = CborBytesTracker();
    bytes.pushTags(CborTags.set);
    bytes.pushInt(MajorTags.array, value.length);
    for (final v in value) {
      final encodeObj = v.encode();
      bytes.pushBytes(encodeObj);
    }
    return bytes.toBytes();
  }

  /// Returns the string representation of the value.
  @override
  String toString() {
    return value.join(",");
  }

  /// Encode the value into CBOR bytes an then to hex
  @override
  String toCborHex() {
    return BytesUtils.toHexString(encode());
  }

  /// override equal operation
  @override
  operator ==(other) {
    if (other is! CborSetValue) return false;
    return CompareUtils.iterableIsEqual(value, other.value);
  }

  /// override hashcode
  @override
  int get hashCode => value.hashCode;

  @override
  CborIterableEncodingType get encoding => CborIterableEncodingType.set;
}
