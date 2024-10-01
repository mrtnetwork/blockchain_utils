import 'package:blockchain_utils/exception/exceptions.dart';

class LayoutException extends BlockchainUtilsException {
  const LayoutException(String message, {Map<String, dynamic>? details})
      : super(message, details: details);
}
