import 'package:blockchain_utils/bip/zcash/src/types.dart';
import 'package:blockchain_utils/exception/exception/exception.dart';

class ZCashKeyError extends BlockchainUtilsException {
  const ZCashKeyError(super.message, {super.details});
}

class ZCashKeyEncodingError extends ZCashKeyError {
  const ZCashKeyEncodingError(super.message, {super.details});
  static ZCashKeyEncodingError invalidUnifiedArguments(
    UnifiedReceiverMode mode, {
    String? reason,
  }) {
    return ZCashKeyEncodingError(
      "Invalid unified ${mode.viewName()} arguments.",
      details: {"reason": reason},
    );
  }

  static ZCashKeyEncodingError invalidUnifiedBytes(
    UnifiedReceiverMode mode, {
    String? reason,
  }) {
    return ZCashKeyEncodingError(
      "Invalid unified ${mode.viewName()} bytes.",
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
    UnifiedReceiverMode mode, {
    String? reason,
    Map<String, dynamic>? details,
  }) {
    return ZCashKeyEncodingError(
      "Invalid unified ${mode.viewName()}.",
      details: {"reason": reason, ...details ?? {}},
    );
  }

  static ZCashKeyEncodingError invalidUnifiedTypeCode(
    UnifiedReceiverMode mode, {
    String? reason,
    Map<String, dynamic>? details,
  }) {
    return ZCashKeyEncodingError(
      "Invalid unified ${mode.viewName()} typecode.",
      details: {"reason": reason, ...details ?? {}},
    );
  }
}
