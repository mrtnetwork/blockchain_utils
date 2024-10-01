import 'package:blockchain_utils/exception/exceptions.dart';

class CborException extends BlockchainUtilsException {
  const CborException(String message, {Map<String, dynamic>? details})
      : super(message, details: details);
}
