import 'package:blockchain_utils/cbor/core/cbor.dart';
import 'package:blockchain_utils/cbor/core/tags.dart';
import 'package:blockchain_utils/cbor/utils/cbor_utils.dart';
import 'package:blockchain_utils/cbor/utils/dynamic_bytes.dart';

/// A class representing a CBOR (Concise Binary Object Representation) Map value.
class CborMapValue<K extends CborObject, V extends CborObject>
    extends CborObject<Map<K, V>> {
  /// Constructor for creating a CborMapValue instance with the provided parameters.
  /// It accepts the Map with all cbor encodable key and value.
  CborMapValue.definite(super.value) : definite = true;

  /// Constructor for creating a CborMapValue instance with the provided parameters.
  /// It accepts the Map with all cbor encodable key and value.
  /// this method encode values with indefinite tag.
  CborMapValue.inDefinite(super.value) : definite = false;

  CborMapValue.fromEntries(Iterable<MapEntry<K, V>> entries)
    : definite = false,
      super(Map<K, V>.fromEntries(entries));

  factory CborMapValue.decode(List<int> bytes) {
    return CborUtils.decodeCbor(bytes);
  }

  final bool definite;

  /// check if is definite
  bool get isDefinite => definite;

  /// Encode the value into CBOR bytes
  @override
  List<int> encode() {
    final bytes = CborBytesTracker();
    if (definite) {
      bytes.pushInt(MajorTags.map, value.length);
    } else {
      bytes.pushIndefinite(MajorTags.map);
    }
    for (final v in value.entries) {
      final encodeKeyObj = v.key.encode();
      bytes.pushBytes(encodeKeyObj);
      final encodeValueObj = v.value.encode();
      bytes.pushBytes(encodeValueObj);
    }
    if (!definite) {
      bytes.breakDynamic();
    }
    return bytes.toBytes();
  }

  /// Returns the string representation of the value.
  @override
  String toString() {
    return "CborMapValue($value)";
  }

  bool containsKey(dynamic val) {
    return value.containsKey(val);
  }

  @override
  Map getValue() {
    return {
      for (final i in value.entries) i.key.getValue(): i.value.getValue(),
    };
  }
}
