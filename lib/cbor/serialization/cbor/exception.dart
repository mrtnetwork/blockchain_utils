import 'package:blockchain_utils/exception/exception/exception.dart';

class CborSerializableException extends BlockchainUtilsException {
  const CborSerializableException(super.message, {super.details});
  static CborSerializableException castingFailed<T extends Object?>(
    Object? value,
  ) {
    throw CborSerializableException(
      "Failed to cast CBOR value to type '$T'.",
      details: {
        "expectedType": "$T",
        "actualType": value?.runtimeType.toString() ?? "null",
      },
    );
  }

  static CborSerializableException get missingArguments =>
      CborSerializableException("Missing CBOR arguments.");
  static CborSerializableException get incorrectTagValue =>
      CborSerializableException("Incorrect cbor tag value.");
  static CborSerializableException get invalidCborEncodingBytes =>
      CborSerializableException("Invalid cbor encode bytes.");
  static CborSerializableException get missingListElement =>
      CborSerializableException("Missing cobr element. index out of range.");
}
