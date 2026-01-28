import 'package:blockchain_utils/crypto/crypto/exception/exception.dart';

class OrchardKeyError extends CryptoException {
  const OrchardKeyError(super.message, {super.details});
  static OrchardKeyError cryptoFailureWith(
    String operation, {
    Map<String, dynamic>? details,
    String? reason,
  }) {
    return OrchardKeyError(
      "Cryptographic failure during $operation",
      details: details,
    );
  }
}
