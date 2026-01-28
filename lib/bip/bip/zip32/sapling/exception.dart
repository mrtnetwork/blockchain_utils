import 'package:blockchain_utils/crypto/crypto/exception/exception.dart';

class SaplingKeyError extends CryptoException {
  const SaplingKeyError(super.message, {super.details});
  static SaplingKeyError cryptoFailureWith(
    String operation, {
    String? reason,
    Map<String, dynamic>? details,
  }) {
    return SaplingKeyError(
      "Cryptographic failure during $operation",
      details: details,
    );
  }
}
