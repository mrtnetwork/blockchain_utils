import 'package:blockchain_utils/cbor/core/cbor.dart';
import 'package:blockchain_utils/cbor/core/tags.dart';
import 'package:blockchain_utils/cbor/utils/cbor_utils.dart';
import 'package:blockchain_utils/cbor/utils/dynamic_bytes.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';

abstract class CborBytes<T> extends CborObject<T> {
  const CborBytes(super.value);
  @override
  List<int> getValue();

  factory CborBytes.decode(List<int> bytes) {
    return CborUtils.decodeCbor(bytes);
  }

  /// Returns the string representation of the value.
  @override
  String toString() {
    return BytesUtils.toHexString(getValue());
  }
}

/// A class representing a CBOR (Concise Binary Object Representation) bytes value.
class CborBytesValue extends CborBytes<List<int>> {
  /// Constructor for creating a CborBytesValue instance with the provided parameters.
  /// It accepts the bytes value.
  CborBytesValue(List<int> bytes) : super(bytes.asImmutableBytes);
  CborBytesValue.unsafe(super.value);
  factory CborBytesValue.decode(List<int> bytes) {
    return CborUtils.decodeCbor(bytes);
  }

  /// Encode the value into CBOR bytes
  @override
  List<int> encode() {
    final bytes = CborBytesTracker();
    bytes.pushInt(MajorTags.byteString, value.length);
    bytes.pushBytes(value);
    return bytes.buffer();
  }

  /// Encode the value into CBOR bytes an then to hex
  @override
  String toCborHex() {
    return BytesUtils.toHexString(encode());
  }

  @override
  List<int> getValue() {
    return value;
  }
}

/// A class representing a CBOR (Concise Binary Object Representation) bytes value with indefinite tag.
class CborDynamicBytesValue extends CborBytes<List<List<int>>> {
  /// Constructor for creating a CborDynamicBytesValue instance with the provided parameters.
  /// It accepts the bytes value.
  CborDynamicBytesValue(List<List<int>> value)
    : super(value.map((e) => e.asImmutableBytes).toList().immutable);

  factory CborDynamicBytesValue.decode(List<int> bytes) {
    return CborUtils.decodeCbor(bytes);
  }

  /// Encode the value into CBOR bytes
  @override
  List<int> encode() {
    final bytes = CborBytesTracker();
    bytes.pushIndefinite(MajorTags.byteString);
    for (final v in value) {
      bytes.pushInt(MajorTags.byteString, v.length);
      bytes.pushBytes(v);
    }
    bytes.breakDynamic();
    return bytes.buffer();
  }

  /// Encode the value into CBOR bytes an then to hex
  @override
  String toCborHex() {
    return BytesUtils.toHexString(encode());
  }

  @override
  List<int> getValue() {
    return value.expand((e) => e).toList();
  }
}
