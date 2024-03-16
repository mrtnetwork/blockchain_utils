import 'package:blockchain_utils/binary/utils.dart';
import 'package:blockchain_utils/cbor/utils/dynamic_bytes.dart';
import 'package:blockchain_utils/cbor/core/cbor.dart';

/// A class representing a CBOR (Concise Binary Object Representation) tag value.
class CborTagValue<T> implements CborObject {
  /// Constructor for creating a CborBoleanValue instance with the provided parameters.
  /// It accepts the all encodable cbor value.
  CborTagValue(this.value, List<int> tags)
      : tags = List<int>.unmodifiable(tags);

  final List<int> tags;

  /// The value as a T.
  @override
  final T value;

  /// Encode the value into CBOR bytes
  @override
  List<int> encode() {
    final bytes = CborBytesTracker();
    bytes.pushTags(tags);
    final obj = CborObject.fromDynamic(value).encode();
    bytes.pushBytes(obj);
    return bytes.toBytes();
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
