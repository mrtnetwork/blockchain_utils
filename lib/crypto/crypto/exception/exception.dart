import 'package:blockchain_utils/exception/exception/exception.dart';

class CryptoException extends BlockchainUtilsException {
  const CryptoException(super.message, {super.details});
  static CryptoException failed(
    String operation, {
    String? reason,
    Map<String, dynamic>? details,
  }) {
    return CryptoException(
      "Crypto operation failed during $operation",
      details: {"reason": reason, ...details ?? {}},
    );
  }

  static CryptoException get operationNotSupported =>
      CryptoException("Current operation not supported.");

  @override
  String toString() {
    return message;
  }
}
