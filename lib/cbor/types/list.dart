import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/cbor/utils/dynamic_bytes.dart';
import 'package:blockchain_utils/cbor/core/tags.dart';
import 'package:blockchain_utils/cbor/core/cbor.dart';

/// A class representing a CBOR (Concise Binary Object Representation) List value.
class CborListValue<T extends CborObject> extends CborIterableObject<List<T>> {
  /// Constructor for creating a CborListValue instance with the provided parameters.
  /// It accepts the List of all cbor encodable value.
  ///
  CborListValue.definite(super.value)
      : encoding = CborIterableEncodingType.definite;

  /// Constructor for creating a CborListValue instance with the provided parameters.
  /// It accepts the List of all cbor encodable value.
  /// this method encode values with indefinite tag.
  CborListValue.inDefinite(super.value)
      : encoding = CborIterableEncodingType.inDefinite;

  @override
  final CborIterableEncodingType encoding;

  /// check is fixedLength or inifinitie
  bool get isDefinite => encoding == CborIterableEncodingType.definite;

  /// Encode the value into CBOR bytes
  @override
  List<int> encode() {
    final bytes = CborBytesTracker();
    if (isDefinite) {
      bytes.pushInt(MajorTags.array, value.length);
    } else {
      bytes.pushIndefinite(MajorTags.array);
    }
    for (final v in value) {
      final encodeObj = v.encode();
      bytes.pushBytes(encodeObj);
    }
    if (!isDefinite) {
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
    return value.join(",");
  }
}
