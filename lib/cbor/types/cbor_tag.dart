import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/cbor/utils/dynamic_bytes.dart';
import 'package:blockchain_utils/cbor/core/cbor.dart';

/// A class representing a CBOR (Concise Binary Object Representation) tag value.
class CborTagValue<T> implements CborObject {
  /// Constructor for creating a CborBoleanValue instance with the provided parameters.
  /// It accepts the all encodable cbor value.
  CborTagValue(T value, List<int> tags)
      : _value = value,
        tags = tags.immutable;

  final List<int> tags;

  final T _value;
  @override
  T get value => _value;

  /// Encode the value into CBOR bytes
  @override
  List<int> encode() {
    final bytes = CborBytesTracker();
    bytes.pushTags(tags);
    final obj = CborObject.fromDynamic(_value).encode();
    bytes.pushBytes(obj);
    return bytes.buffer();
  }

  /// Encode the value into CBOR bytes an then to hex
  @override
  String toCborHex() {
    return BytesUtils.toHexString(encode());
  }

  /// Returns the string representation of the value.
  @override
  String toString() {
    return value.toString();
  }
}
