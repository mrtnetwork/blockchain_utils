import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/helper.dart';

class AddressConverterException extends BlockchainUtilsException {
  const AddressConverterException(super.message, {super.details});

  static AddressConverterException addressValidationFailed({
    String? network,
    String? reason,
    Map<String, dynamic>? details,
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
    Map<String, dynamic>? details,
  }) {
    return AddressConverterException(
      network == null
          ? "Invalid address key format."
          : "Invalid $network address key format.",
      details:
          {"network": network, ...details ?? {}, "reason": reason}.notNullValue,
    );
  }

  static AddressConverterException addressBytesValidationFailed({
    String? network,
    String? reason,
    Map<String, dynamic>? details,
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
    Map<String, dynamic>? details,
  }) {
    return AddressConverterException(
      "Missing or invalid convertion address arguments.",
      details:
          {"network": network, ...details ?? {}, "reason": reason}.notNullValue,
    );
  }
}
