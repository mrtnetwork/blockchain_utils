import 'package:blockchain_utils/exception/exception/exception.dart';

class ZcashKeyError extends BlockchainUtilsException {
  const ZcashKeyError(super.message);
}

class ZCashKeyEncodingError extends BlockchainUtilsException {
  const ZCashKeyEncodingError(super.message, {super.details});
  static ZCashKeyEncodingError invalidUnifiedArguments(
    String type, {
    String? reason,
  }) {
    return ZCashKeyEncodingError(
      "Invalid unified $type arguments.",
      details: {"reason": reason},
    );
  }

  static ZCashKeyEncodingError invalidUnifiedBytes(
    String type, {
    String? reason,
  }) {
    return ZCashKeyEncodingError(
      "Invalid unified $type bytes.",
      details: {"reason": reason},
    );
  }

  static ZCashKeyEncodingError invalidKeyData(String type, {String? reason}) {
    return ZCashKeyEncodingError(
      "Invalid $type key data.",
      details: {"reason": reason},
    );
  }

  static ZCashKeyEncodingError invalidUnifiedObject(
    String type, {
    String? reason,
    Map<String, dynamic>? details,
  }) {
    return ZCashKeyEncodingError(
      "Invalid unified $type.",
      details: {"reason": reason, ...details ?? {}},
    );
  }

  static ZCashKeyEncodingError invalidUnifiedTypeCode(
    String type, {
    String? reason,
    Map<String, dynamic>? details,
  }) {
    return ZCashKeyEncodingError(
      "Invalid unified $type typecode.",
      details: {"reason": reason, ...details ?? {}},
    );
  }
}
