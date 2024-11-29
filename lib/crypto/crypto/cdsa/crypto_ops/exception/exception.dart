import 'package:blockchain_utils/exception/exception.dart';

class CryptoOpsException extends BlockchainUtilsException {
  const CryptoOpsException(String message, {Map<String, dynamic>? details})
      : super(message, details: details);
}
