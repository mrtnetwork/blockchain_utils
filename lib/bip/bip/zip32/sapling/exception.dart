import 'package:blockchain_utils/crypto/crypto/exception/exception.dart';

class SaplingKeyError extends CryptoException {
  const SaplingKeyError(super.message, {super.details});
  static SaplingKeyError failed(
    String operation, {
    String? reason,
    Map<String, String?>? details,
  }) {
    return SaplingKeyError(
      "Orchard key operation failed during $operation",
      details: details,
    );
  }
}
