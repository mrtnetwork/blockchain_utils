import 'package:blockchain_utils/binary/utils.dart';
import 'package:blockchain_utils/cbor/utils/dynamic_bytes.dart';
import 'package:blockchain_utils/cbor/core/tags.dart';
import 'package:blockchain_utils/cbor/core/cbor.dart';

/// A class representing a CBOR (Concise Binary Object Representation) Map value.
class CborMapValue<K, V> implements CborObject {
  /// Constructor for creating a CborMapValue instance with the provided parameters.
  /// It accepts the Map with all cbor encodable key and value and an optional list of CBOR tags.
  CborMapValue.fixedLength(this.value, [this.tags = const []])
      : _isFixedLength = true;

  /// Constructor for creating a CborMapValue instance with the provided parameters.
  /// It accepts the Map with all cbor encodable key and value and an optional list of CBOR tags.
  /// this method encode values with indefinite tag.
  CborMapValue.dynamicLength(this.value, [this.tags = const []])
      : _isFixedLength = false;

  /// value as Map
  @override
  final Map<K, V> value;

  /// List of CBOR tags associated with the URL value.
  @override
  final List<int> tags;
  final bool _isFixedLength;

  /// check is fixedLength or inifinitie
  bool get isFixedLength => _isFixedLength;

  /// Encode the value into CBOR bytes
  @override
  List<int> encode() {
    final bytes = CborBytesTracker();
    bytes.pushTags(tags);
    if (isFixedLength) {
      bytes.pushInt(MajorTags.map, value.length);
    } else {
      bytes.pushIndefinite(MajorTags.map);
    }
    for (final v in value.entries) {
      final keyObj = CborObject.fromDynamic(v.key);
      final encodeKeyObj = keyObj.encode();
      bytes.pushBytes(encodeKeyObj);
      final valueObj = CborObject.fromDynamic(v.value);
      final encodeValueObj = valueObj.encode();
      bytes.pushBytes(encodeValueObj);
    }
    if (!isFixedLength) {
      bytes.breakDynamic();
    }
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

  bool containsKey(dynamic val) {
    return value.containsKey(val);
  }
}
