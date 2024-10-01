import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/cbor/utils/dynamic_bytes.dart';
import 'package:blockchain_utils/cbor/core/tags.dart';
import 'package:blockchain_utils/cbor/core/cbor.dart';

/// A class representing a CBOR (Concise Binary Object Representation) Set value.
class CborSetValue<T> implements CborObject {
  /// Constructor for creating a CborSetValue instance with the provided parameters.
  /// It accepts a set of all encodable cbor object.
  CborSetValue(this.value);

  /// value as set
  @override
  final Set<T> value;

  /// Encode the value into CBOR bytes
  @override
  List<int> encode() {
    final bytes = CborBytesTracker();
    bytes.pushTags(CborTags.set);
    bytes.pushInt(MajorTags.array, value.length);
    for (final v in value) {
      final obj = CborObject.fromDynamic(v);
      final encodeObj = obj.encode();
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
}
