import 'package:blockchain_utils/cbor/core/cbor.dart';
import 'package:blockchain_utils/cbor/utils/dynamic_bytes.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/utils.dart';

/// A class representing a CBOR (Concise Binary Object Representation) tag value.
class CborTagValue<T extends CborObject> extends CborObject<T> {
  /// Constructor for creating a CborBoleanValue instance with the provided parameters.
  /// It accepts the all encodable cbor value.
  CborTagValue(super.value, List<int> tags) : tags = tags.immutable;

  final List<int> tags;

  /// Encode the value into CBOR bytes
  @override
  List<int> encode() {
    final bytes = CborBytesTracker();
    bytes.pushTags(tags);
    bytes.pushBytes(value.encode());
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

  @override
  Object? getValue() {
    return value.getValue();
  }
}
