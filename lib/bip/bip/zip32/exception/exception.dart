import 'package:blockchain_utils/exception/exception/exception.dart';

class Zip32Error extends BlockchainUtilsException {
  const Zip32Error(super.message, {super.details});
  factory Zip32Error.cryptoFailureWith(
    String operation, {
    String? reason,
    Map<String, dynamic>? details,
  }) {
    return Zip32Error(
      "Cryptographic failure during $operation",
      details: details,
    );
  }
}
