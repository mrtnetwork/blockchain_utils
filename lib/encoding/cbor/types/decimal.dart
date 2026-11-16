import 'package:blockchain_utils/encoding/cbor/utils/cbor_utils.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

import 'package:blockchain_utils/encoding/cbor/types/int64.dart';
import 'package:blockchain_utils/encoding/cbor/utils/dynamic_bytes.dart';
import 'package:blockchain_utils/encoding/cbor/core/tags.dart';
import 'package:blockchain_utils/encoding/cbor/types/bigint.dart';
import 'package:blockchain_utils/encoding/cbor/core/cbor.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// A class representing a CBOR (Concise Binary Object Representation) Decimal value.
class CborDecimalFracValue extends CborObject<List<BigInt>> {
  /// Constructor for creating a CborDecimalFracValue instance with the provided parameters.
  /// It accepts the BigInt exponent and mantissa value.
  CborDecimalFracValue(this.exponent, this.mantissa)
    : super([exponent, mantissa].immutable);

  factory CborDecimalFracValue.decode(List<int> bytes) {
    return CborUtils.decodeCbor(bytes);
  }

  /// Create a CborDecimalFracValue from two CborNumeric values representing the exponent and mantissa.
  factory CborDecimalFracValue.fromCborNumeric(
    CborNumeric exponent,
    CborNumeric mantissa,
  ) {
    return CborDecimalFracValue(
      CborNumeric.getCborNumericValue(exponent),
      CborNumeric.getCborNumericValue(mantissa),
    );
  }

  /// exponent value
  final BigInt exponent;

  /// mantissa value
  final BigInt mantissa;

  /// Encode the value into CBOR bytes
  @override
  BuBytes encode() {
    final bytes = CborBytesTracker();
    bytes.pushTags(CborTags.decimalFrac);
    bytes.pushInt(MajorTags.array, 2);
    bytes.pushBytes(_encodeValue(exponent));
    bytes.pushBytes(_encodeValue(mantissa));
    return bytes.buffer();
  }

  List<int> _encodeValue(BigInt value) {
    if (value.bitLength > 64) {
      return CborBigIntValue(value).encode();
    }
    return CborSafeIntValue(value).encode();
  }

  @override
  String toString() {
    return "CborDecimalFracValue({exponent:$exponent, mantissa:$mantissa})";
  }
}
