import 'package:blockchain_utils/crypto/crypto/exception/exception.dart';

class OrchardKeyError extends CryptoException {
  const OrchardKeyError(super.message, {super.details});
  static OrchardKeyError failed(
    String operation, {
    Map<String, String?>? details,
    String? reason,
  }) {
    return OrchardKeyError(
      "Orchard key operation failed during $operation",
      details: details,
    );
  }
}
