import 'package:blockchain_utils/encoding/cbor/utils/cbor_utils.dart';

import 'package:blockchain_utils/encoding/cbor/utils/dynamic_bytes.dart';
import 'package:blockchain_utils/encoding/cbor/utils/extentions.dart';
import 'package:blockchain_utils/encoding/cbor/core/tags.dart';
import 'package:blockchain_utils/encoding/cbor/core/cbor.dart';
import 'package:blockchain_utils/encoding/cbor/types/double.dart';
import 'package:blockchain_utils/encoding/cbor/types/int.dart';
import 'package:blockchain_utils/encoding/cbor/types/string.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// A class representing a CBOR (Concise Binary Object Representation) DateTime value.
abstract class _CborDate extends CborObject<DateTime> {
  const _CborDate(super.value);

  List<int> _getTags() {
    if (this is CborStringDateValue) {
      return CborTags.dateString;
    }
    return CborTags.dateEpoch;
  }

  List<int> _encode();

  /// Encode the value into CBOR bytes
  @override
  BuBytes encode() {
    final bytes = CborBytesTracker();
    bytes.pushTags(_getTags());
    bytes.pushBytes(_encode());
    return bytes.buffer();
  }

  /// Returns the string representation of the value.
  @override
  String toString() {
    return value.toIso8601String();
  }
}

/// A class representing a CBOR (Concise Binary Object Representation) String DateTime value.
class CborStringDateValue extends _CborDate {
  /// Constructor for creating a CborStringDateValue instance with the provided parameters.
  /// It accepts DateTime value.
  CborStringDateValue(super.value);

  factory CborStringDateValue.decode(List<int> bytes) {
    return CborUtils.decodeCbor(bytes);
  }

  @override
  List<int> _encode() {
    final toString = value.toRFC3339WithTimeZone();
    final toStringCbor = CborStringValue(toString);
    return toStringCbor.encode();
  }

  @override
  String toString() {
    return "CborStringDateValue($value)";
  }
}

/// A class representing a CBOR (Concise Binary Object Representation) epoch float DateTime value.
class CborEpochFloatValue extends _CborDate {
  /// Constructor for creating a CborEpochFloatValue instance with the provided parameters.
  /// It accepts DateTime value.
  CborEpochFloatValue(super.value);

  factory CborEpochFloatValue.decode(List<int> bytes) {
    return CborUtils.decodeCbor(bytes);
  }

  @override
  List<int> _encode() {
    final toSecond = value.millisecondsSinceEpoch / 1000;
    final toFloatCbor = CborFloatValue(toSecond);
    return toFloatCbor.encode();
  }

  @override
  String toString() {
    return "CborEpochFloatValue($value)";
  }
}

/// A class representing a CBOR (Concise Binary Object Representation) epoch int DateTime value.
class CborEpochIntValue extends _CborDate {
  /// Constructor for creating a CborEpochIntValue instance with the provided parameters.
  /// It accepts DateTime value.
  CborEpochIntValue(super.value);

  factory CborEpochIntValue.decode(List<int> bytes) {
    return CborUtils.decodeCbor(bytes);
  }

  @override
  List<int> _encode() {
    final toSecond = value.millisecondsSinceEpoch / 1000;
    final toFloatCbor = CborIntValue(toSecond.round());
    return toFloatCbor.encode();
  }

  @override
  String toString() {
    return "CborEpochIntValue($value)";
  }
}
