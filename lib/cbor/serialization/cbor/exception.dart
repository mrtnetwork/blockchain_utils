import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/serialization/identifier.dart';

class CborSerializableException extends BlockchainUtilsException {
  const CborSerializableException(super.message, {super.details});
  static CborSerializableException castingFailed<T extends Object?>(
    Object? value, {
    String? operation,
  }) {
    throw CborSerializableException(
      "Failed to cast CBOR object to type '$T'.",
      details: {
        "expectedType": "$T",
        "actualType": value?.runtimeType.toString() ?? "null",
        "operation": operation,
      },
    );
  }

  factory CborSerializableException.deserialize({
    List<int>? bytes,
    CborObject? object,
  }) {
    final values = CborTagSerializable.decodeTaggedValue(
      identifier: BlockchainUtilsSerializationIdentifier.cborSerializationError,
      cborBytes: bytes,
      cborObject: object,
    );
    return CborSerializableException(
      values.rawValueAt(0),
      details: values.maybeRawMapAt<String, String?>(1),
    );
  }

  @override
  BlockchainUtilsSerializationIdentifier get serializationIdentifier =>
      BlockchainUtilsSerializationIdentifier.cborSerializationError;

  static CborSerializableException get missingArguments =>
      CborSerializableException("Missing CBOR arguments.");

  static CborSerializableException incorrectTagValue({List<int>? tag}) =>
      CborSerializableException(
        "Incorrect cbor tag value.",
        details: {"tag": tag?.toString()},
      );
  static CborSerializableException get invalidCborEncodingBytes =>
      CborSerializableException("Invalid cbor encode bytes.");
  static CborSerializableException get missingListElement =>
      CborSerializableException("Missing cobr element. index out of range.");
}
