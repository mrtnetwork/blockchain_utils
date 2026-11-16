import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Same-signature replacements for the removed core exception factories.
/// Message text and `details` shapes are preserved verbatim.
abstract final class CoreErrors {
  static BuError invalidOperationArguments(
    String operation, {
    required String reason,
    String? name,
    Map<String, String?>? details,
  }) =>
      BuError(
        DefaultErrorType.invalidArgument,
        "Invalid $operation arguments.",
        details: {
          "reason": reason,
          if (name != null) "name": name,
          ...details ?? {},
        }.notNullValue,
      );

  static BuError badState(
    String operation, {
    String? name,
    required String reason,
    int? expecteLen,
    Map<String, dynamic>? details,
  }) =>
      BuError(
        DefaultErrorType.invalidState,
        "$operation not allowed in current state.",
        details: {"expected": operation, "reason": reason},
      );

  static BuError cryptoFailed(
    String operation, {
    String? reason,
    Map<String, String>? details,
  }) =>
      BuError(
        DefaultErrorType.crypto,
        "Crypto operation failed during $operation",
        details: {"reason": reason, ...details ?? {}},
      );

  static const cryptoOperationNotSupported = BuError(
    DefaultErrorType.unsupported,
    "Current operation not supported.",
  );

  static BuError addressValidationFailed({
    String? network,
    String? reason,
    Map<String, String?>? details,
  }) =>
      BuError(
        DefaultErrorType.invalidAddress,
        network == null
            ? "Invalid address format."
            : "Invalid $network address format.",
        details:
            {"network": network, ...details ?? {}, "reason": reason}.notNullValue,
      );

  static BuError addressKeyValidationFailed({
    String? network,
    String? reason,
    Map<String, String?>? details,
  }) =>
      BuError(
        DefaultErrorType.invalidAddress,
        network == null
            ? "Invalid address key format."
            : "Invalid $network address key format.",
        details:
            {
              "network": network,
              ...details ?? {},
              "reason": reason,
            }.notNullValue,
      );

  static BuError addressBytesValidationFailed({
    String? network,
    String? reason,
    Map<String, String?>? details,
  }) =>
      BuError(
        DefaultErrorType.invalidAddress,
        network == null
            ? "Invalid address encoding."
            : "Invalid $network address encoding.",
        details:
            {"network": network, ...details ?? {}, "reason": reason}.notNullValue,
      );

  static BuError missingOrInvalidAddressArguments({
    String? network,
    String? reason,
    Map<String, String?>? details,
  }) =>
      BuError(
        DefaultErrorType.invalidArgument,
        "Missing or invalid conversion address arguments.",
        details:
            {"network": network, ...details ?? {}, "reason": reason}.notNullValue,
      );

  static BuError signInvalidArguments(
    String operation, {
    String? name,
    String? reason,
    Map<String, String?>? details,
  }) =>
      BuError(
        DefaultErrorType.invalidArgument,
        "Invalid $operation arguments.",
        details:
            {
              "name": name,
              ...details ?? {},
              "reason": reason,
            }.notNullValue,
      );

  static BuError unknownKey([String? type]) => BuError(
        DefaultErrorType.invalidArgument,
        "Unknown signing key.",
        details: {"type": type}.notNullValue,
      );

  static BuError unsupportedKeyType(String type) => BuError(
        DefaultErrorType.unsupported,
        "Unsupported key type.",
        details: {"type": type},
      );

  static const signVerificationFailed = BuError(
    DefaultErrorType.cryptoVerifyFailed,
    'The created signature does not pass verification.',
  );

  static BuError pedersenFailed(
    String operation, {
    Map<String, String>? details,
    String? reason,
  }) =>
      BuError(
        DefaultErrorType.crypto,
        "Pedersen operation failed during $operation.",
        details: {...details ?? {}, "reason": reason},
      );

  static BuError incorrectTagValue({List<int>? tag}) => BuError(
        DefaultErrorType.castFailed,
        "Incorrect CBOR tag value.",
        details: {"tag": tag?.toString()},
      );

  static Never castingFailed<T extends Object?>(
    Object? value, {
    String? operation,
  }) {
    throw BuError(
      DefaultErrorType.castFailed,
      "Failed to cast CBOR object to type '$T'.",
      details: {
        "expectedType": "$T",
        "actualType": value?.runtimeType.toString() ?? "null",
        "operation": operation,
      },
    );
  }

  static BuError jsonFailed(String? reason, {Object? value}) => BuError(
        DefaultErrorType.unsupported,
        "Converting object to an encodable object failed.",
        details: {"reason": reason, "value": value?.toString()}.notNullValue,
      );

  static BuError jsonCycleError(Object? value) => BuError(
        DefaultErrorType.unsupported,
        "Converting object to an encodable object failed.",
        details: {
          "reason": 'Cyclic reference detected',
          "value": value?.toString(),
        },
      );

  /// Known JSON shape error: a required key is absent from the map.
  static BuError jsonKeyNotFound(
    Object? key, {
    Map<String, String?>? details,
  }) =>
      BuError(
        DefaultErrorType.badJson,
        "Missing key: '$key'.",
        details: {'key': key?.toString(), ...?details},
      );

  /// Known JSON shape error: a value cannot be coerced to the requested
  /// type. [message] preserves the call-site-specific text.
  static BuError jsonWrongType(
    String message, {
    Map<String, String?>? details,
  }) =>
      BuError(
        DefaultErrorType.badJson,
        message,
        details: details,
      );

  static BuError saplingFailed(
    String operation, {
    String? reason,
    Map<String, String?>? details,
  }) =>
      BuError(
        DefaultErrorType.invalidKeyData,
        "Sapling key operation failed during $operation",
        details: {"reason": reason, ...details ?? {}},
      );

  static BuError orchardFailed(
    String operation, {
    Map<String, String?>? details,
    String? reason,
  }) =>
      BuError(
        DefaultErrorType.invalidKeyData,
        "Orchard key operation failed during $operation",
        details: {"reason": reason, ...details ?? {}},
      );

  static BuError zcashInvalidUnifiedArguments(
    String viewName, {
    String? reason,
  }) =>
      BuError(
        DefaultErrorType.invalidArgument,
        "Invalid unified $viewName arguments.",
        details: {"reason": reason},
      );

  static BuError zcashInvalidUnifiedBytes(String viewName, {String? reason}) =>
      BuError(
        DefaultErrorType.invalidArgument,
        "Invalid unified $viewName bytes.",
        details: {"reason": reason},
      );

  static BuError zcashInvalidKeyData(String type, {String? reason}) => BuError(
        DefaultErrorType.invalidKeyData,
        "Invalid $type key data.",
        details: {"reason": reason},
      );

  static BuError zcashInvalidUnifiedObject(
    String viewName, {
    String? reason,
    Map<String, String?>? details,
  }) =>
      BuError(
        DefaultErrorType.invalidArgument,
        "Invalid unified $viewName.",
        details: {"reason": reason, ...details ?? {}},
      );

  static BuError zcashInvalidUnifiedTypeCode(
    String viewName, {
    String? reason,
    Map<String, String>? details,
  }) =>
      BuError(
        DefaultErrorType.invalidArgument,
        "Invalid unified $viewName typecode.",
        details: {"reason": reason, ...details ?? {}},
      );

  static const web3UnsupportedBackupContent = BuError(
    DefaultErrorType.unsupported,
    "Unsupported backup content.",
  );

  static const web3WrongBackupPassword = BuError(
    DefaultErrorType.invalidArgument,
    "Wrong backup password.",
  );

  static const mnemonicInvalidChecksum = BuError(
    DefaultErrorType.invalidChecksum,
    "Invalid mnemonic checksum.",
  );

  static const integerDivisionByZero = BuError(
    DefaultErrorType.invalidArgument,
    "division by zero",
  );

  static const integerOverflow = BuError(
    DefaultErrorType.invalidArgument,
    "integer overflow: value cannot be represented in the target integer type",
  );

  static const integerToIntConversionError = BuError(
    DefaultErrorType.invalidArgument,
    "integer value exceeds the safe range of Dart int; use toBigInt() instead",
  );

  static const ss58InvalidChecksum = BuError(
    DefaultErrorType.invalidChecksum,
    "Invalid SS58 checksum.",
  );

  static const cborInvalidEncodingBytes = BuError(
    DefaultErrorType.badCbor,
    "Invalid CBOR encoded bytes.",
  );

  static const cborMissingListElement = BuError(
    DefaultErrorType.invalidLength,
    "Missing CBOR element. index out of range.",
  );

  static const cborMissingArguments = BuError(
    DefaultErrorType.badCbor,
    "Missing CBOR arguments.",
  );

  static const utf8InvalidUtf16String = BuError(
    DefaultErrorType.badUtf8,
    "Invalid UTF-16 string.",
  );

  static const utf8InvalidUtf8String = BuError(
    DefaultErrorType.badUtf8,
    "Invalid UTF-8 string.",
  );

  /// Attaches the failing map key to a [BuError] JSON parse failure,
  /// unless a key is already recorded.
  static BuError jsonErrorWithKey(BuError error, Object? key) {
    if (error.details?["key"] != null) return error;
    if (key is String || key is num || key is BigInt) {
      return BuError(
        error.type,
        error.message,
        details: {...?error.details, "key": key.toString()},
      );
    }
    return error;
  }
}
