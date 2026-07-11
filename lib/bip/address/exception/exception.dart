import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/serialization/identifier.dart';

class AddressConverterException extends BlockchainUtilsException {
  const AddressConverterException(super.message, {super.details});
  factory AddressConverterException.deserialize({
    List<int>? bytes,
    CborObject? object,
  }) {
    final values = CborTagSerializable.decodeTaggedValue(
      identifier: BlockchainUtilsSerializationIdentifier.addressConverterError,
      cborBytes: bytes,
      cborObject: object,
    );
    return AddressConverterException(
      values.rawValueAt(0),
      details: values.maybeRawMapAt<String, String?>(1),
    );
  }

  static AddressConverterException addressValidationFailed({
    String? network,
    String? reason,
    Map<String, String?>? details,
  }) {
    return AddressConverterException(
      network == null
          ? "Invalid address format."
          : "Invalid $network address format.",
      details:
          {"network": network, ...details ?? {}, "reason": reason}.notNullValue,
    );
  }

  static AddressConverterException addressKeyValidationFailed({
    String? network,
    String? reason,
    Map<String, String?>? details,
  }) {
    return AddressConverterException(
      network == null
          ? "Invalid address key format."
          : "Invalid $network address key format.",
      details:
          {
            "network": network.toString(),
            ...details ?? {},
            "reason": reason,
          }.notNullValue,
    );
  }

  static AddressConverterException addressBytesValidationFailed({
    String? network,
    String? reason,
    Map<String, String?>? details,
  }) {
    return AddressConverterException(
      network == null
          ? "Invalid address encoding."
          : "Invalid $network address encoding.",
      details:
          {"network": network, ...details ?? {}, "reason": reason}.notNullValue,
    );
  }

  static AddressConverterException missingOrInvalidAddressArguments({
    String? network,
    String? reason,
    Map<String, String?>? details,
  }) {
    return AddressConverterException(
      "Missing or invalid convertion address arguments.",
      details:
          {"network": network, ...details ?? {}, "reason": reason}.notNullValue,
    );
  }

  @override
  BlockchainUtilsSerializationIdentifier get serializationIdentifier =>
      BlockchainUtilsSerializationIdentifier.addressConverterError;
}
