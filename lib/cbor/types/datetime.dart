import 'package:blockchain_utils/binary/utils.dart';
import 'package:blockchain_utils/cbor/utils/dynamic_bytes.dart';
import 'package:blockchain_utils/cbor/utils/extentions.dart';
import 'package:blockchain_utils/cbor/core/tags.dart';
import 'package:blockchain_utils/cbor/core/cbor.dart';
import 'package:blockchain_utils/cbor/types/double.dart';
import 'package:blockchain_utils/cbor/types/int.dart';
import 'package:blockchain_utils/cbor/types/string.dart';
import 'package:blockchain_utils/compare/compare.dart';

/// A class representing a CBOR (Concise Binary Object Representation) DateTime value.
abstract class _CborDate implements CborObject {
  /// The value as a DateTime.
  @override
  abstract final DateTime value;

  /// List of CBOR tags associated with the URL value.
  @override
  abstract final List<int> tags;

  List<int> _getTags() {
    if (tags.isNotEmpty) return tags;
    if (this is CborStringDateValue) {
      return [CborTags.dateString];
    }
    return [CborTags.dateEpoch];
  }

  /// Encode the value into CBOR bytes an then to hex
  @override
  String toCborHex() {
    return BytesUtils.toHexString(encode());
  }

  List<int> _encode();

  /// Encode the value into CBOR bytes
  @override
  List<int> encode() {
    final bytes = CborBytesTracker();
    bytes.pushTags(_getTags());
    bytes.pushBytes(_encode());
    return bytes.toBytes();
  }

  /// Returns the string representation of the value.
  @override
  String toString() {
    return value.toIso8601String();
  }

  /// overide equal operation
  @override
  operator ==(other) {
    if (other is! _CborDate) return false;
    if (other.runtimeType != runtimeType) return false;
    return value.microsecondsSinceEpoch == other.value.microsecondsSinceEpoch &&
        bytesEqual(tags, other.tags);
  }

  /// ovveride hash code
  @override
  int get hashCode => value.hashCode;
}

/// A class representing a CBOR (Concise Binary Object Representation) String DateTime value.
class CborStringDateValue extends _CborDate {
  /// Constructor for creating a CborStringDateValue instance with the provided parameters.
  /// It accepts DateTime value, and an optional list of CBOR tags.
  CborStringDateValue(this.value, [this.tags = const []]);

  /// The value as a DateTime.
  @override
  final DateTime value;

  /// List of CBOR tags associated with the URL value.
  @override
  final List<int> tags;

  @override
  List<int> _encode() {
    final toString = value.toRFC3339WithTimeZone();
    final toStringCbor = CborStringValue(toString);
    return toStringCbor.encode();
  }
}

/// A class representing a CBOR (Concise Binary Object Representation) epoch float DateTime value.
class CborEpochFloatValue extends _CborDate {
  /// Constructor for creating a CborEpochFloatValue instance with the provided parameters.
  /// It accepts DateTime value, and an optional list of CBOR tags.
  CborEpochFloatValue(this.value, [this.tags = const []]);

  /// The value as a DateTime.
  @override
  final DateTime value;

  /// List of CBOR tags associated with the URL value.
  @override
  final List<int> tags;

  @override
  List<int> _encode() {
    final toSecound = value.millisecondsSinceEpoch / 1000;
    final toFloatCbor = CborFloatValue(toSecound);
    return toFloatCbor.encode();
  }
}

/// A class representing a CBOR (Concise Binary Object Representation) epoch int DateTime value.
class CborEpochIntValue extends _CborDate {
  /// Constructor for creating a CborEpochIntValue instance with the provided parameters.
  /// It accepts DateTime value, and an optional list of CBOR tags.
  CborEpochIntValue(this.value, [this.tags = const []]);

  /// The value as a DateTime.
  @override
  final DateTime value;

  /// List of CBOR tags associated with the URL value.
  @override
  final List<int> tags;
  @override
  List<int> _encode() {
    final toSecound = value.millisecondsSinceEpoch / 1000;
    final toFloatCbor = CborIntValue(toSecound.round());
    return toFloatCbor.encode();
  }
}
